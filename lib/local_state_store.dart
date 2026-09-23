import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:sembast/sembast.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'local_state_backend.dart';

class LocalStateStore {
  LocalStateStore._();

  static final LocalStateStore instance = LocalStateStore._();

  static const int schemaVersion = 1;
  static const String _testSessionMarker =
      'annas_diary_structured_store_test_session_v1';

  final StoreRef<String, Map<String, Object?>> _state =
      stringMapStoreFactory.store('state');
  final StoreRef<String, Map<String, Object?>> _meta =
      stringMapStoreFactory.store('meta');

  final Map<String, String> _cache = <String, String>{};
  final Set<String> _corruptKeys = <String>{};
  final Set<String> _recoveredKeys = <String>{};

  Database? _database;
  Future<LocalStateStore>? _opening;

  Set<String> get corruptKeys => Set<String>.unmodifiable(_corruptKeys);
  Set<String> get recoveredKeys => Set<String>.unmodifiable(_recoveredKeys);

  Future<LocalStateStore> open({
    SharedPreferences? legacyPreferences,
  }) async {
    if (localStateBackendIsTest && legacyPreferences != null) {
      final marker = legacyPreferences.getBool(_testSessionMarker) ?? false;
      if (!marker) {
        await resetForTesting();
        await legacyPreferences.setBool(_testSessionMarker, true);
      }
    }

    if (_database != null) return this;
    final existing = _opening;
    if (existing != null) return existing;

    final future = _openInternal(legacyPreferences);
    _opening = future;
    try {
      return await future;
    } finally {
      _opening = null;
    }
  }

  Future<LocalStateStore> _openInternal(
    SharedPreferences? legacyPreferences,
  ) async {
    final db = await openLocalStateDatabase();
    _database = db;
    await _loadValidatedRecords(db);

    if (legacyPreferences != null) {
      await _migrateLegacyPreferences(db, legacyPreferences);
    }

    await _meta.record('schema').put(
      db,
      <String, Object?>{
        'version': schemaVersion,
        'openedAt': DateTime.now().toUtc().toIso8601String(),
      },
    );
    return this;
  }

  Future<void> _loadValidatedRecords(Database db) async {
    _cache.clear();
    _corruptKeys.clear();
    _recoveredKeys.clear();

    final records = await _state.find(db);
    for (final record in records) {
      final value = record.value['value'];
      final checksum = record.value['checksum'];
      if (value is String &&
          checksum is String &&
          checksum == _checksum(value)) {
        _cache[record.key] = value;
        continue;
      }

      final previous = record.value['previousValue'];
      final previousChecksum = record.value['previousChecksum'];
      if (previous is String &&
          previousChecksum is String &&
          previousChecksum == _checksum(previous)) {
        _cache[record.key] = previous;
        _recoveredKeys.add(record.key);
        await _writeRecord(
          db,
          record.key,
          previous,
          preservePrevious: false,
        );
        continue;
      }

      _corruptKeys.add(record.key);
    }
  }

  Future<void> _migrateLegacyPreferences(
    Database db,
    SharedPreferences legacy,
  ) async {
    final migration = await _meta.record('shared_preferences_migration').get(db);
    final completed = migration?['version'] == schemaVersion;
    if (completed) return;

    var migrated = 0;
    for (final key in legacy.getKeys()) {
      if (!_isAgendaStateKey(key) || _cache.containsKey(key)) continue;
      final value = legacy.getString(key);
      if (value == null) continue;
      await _writeRecord(db, key, value, preservePrevious: false);
      _cache[key] = value;
      migrated++;
    }

    await _meta.record('shared_preferences_migration').put(
      db,
      <String, Object?>{
        'version': schemaVersion,
        'completedAt': DateTime.now().toUtc().toIso8601String(),
        'migratedRecords': migrated,
      },
    );
  }

  String? getString(String key) => _cache[key];

  bool containsKey(String key) => _cache.containsKey(key);

  Set<String> getKeys() => Set<String>.unmodifiable(_cache.keys.toSet());

  Future<bool> setString(String key, String value) async {
    final db = _requireDatabase();
    await _writeRecord(db, key, value);
    _cache[key] = value;
    _corruptKeys.remove(key);
    return true;
  }

  Future<bool> remove(String key) async {
    final db = _requireDatabase();
    await _state.record(key).delete(db);
    _cache.remove(key);
    _corruptKeys.remove(key);
    _recoveredKeys.remove(key);
    return true;
  }

  Future<void> writeBatch(Map<String, String?> changes) async {
    final db = _requireDatabase();
    await db.transaction((txn) async {
      for (final entry in changes.entries) {
        final value = entry.value;
        if (value == null) {
          await _state.record(entry.key).delete(txn);
          continue;
        }
        await _writeRecord(
          txn,
          entry.key,
          value,
        );
      }
    });

    for (final entry in changes.entries) {
      if (entry.value == null) {
        _cache.remove(entry.key);
        _corruptKeys.remove(entry.key);
        _recoveredKeys.remove(entry.key);
      } else {
        _cache[entry.key] = entry.value!;
        _corruptKeys.remove(entry.key);
      }
    }
  }

  Future<void> _writeRecord(
    DatabaseClient db,
    String key,
    String value, {
    bool preservePrevious = true,
  }) async {
    final previous = preservePrevious ? _cache[key] : null;
    await _state.record(key).put(
      db,
      <String, Object?>{
        'value': value,
        'checksum': _checksum(value),
        'previousValue': previous,
        'previousChecksum': previous == null ? null : _checksum(previous),
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
        'version': schemaVersion,
      },
    );
  }

  Database _requireDatabase() {
    final db = _database;
    if (db == null) {
      throw StateError('LocalStateStore.open() must be called first.');
    }
    return db;
  }

  Future<void> resetForTesting() async {
    final db = _database;
    _database = null;
    _opening = null;
    _cache.clear();
    _corruptKeys.clear();
    _recoveredKeys.clear();
    if (db != null) {
      try {
        await db.close();
      } catch (_) {}
    }
  }

  static String _checksum(String value) =>
      sha256.convert(utf8.encode(value)).toString();

  static bool _isAgendaStateKey(String key) {
    const exact = <String>{
      'items_v1',
      'journals_v1',
      'months_v1',
      'weeks_v1',
      'habits_v1',
      'backup_snapshots_v1',
      'agenda_preferences_v1',
      'inbox_v1',
      'cloud_sync_queue_v1',
      'cloud_sync_index_v1',
      'cloud_sync_owner_v1',
      'account_profiles_v1',
      'active_account_v1',
      'legacy_claimed_by_v1',
      'privacy_guard_v1',
    };
    if (exact.contains(key)) return true;

    const prefixes = <String>[
      'shared_cache_',
      'shared_pending_',
      'shared_interactions_pending_',
      'shared_media_pending_',
      'shared_spaces_',
      'shared_unread_',
      'shared_interactions_cache_',
    ];
    return prefixes.any(key.startsWith);
  }
}
