import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pointycastle/export.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cycle_tracker_domain.dart';
import 'local_state_store.dart';
import 'src/security/vault_password_kdf.dart';

enum PrivateVaultEntryKind { note, credential }

class PrivateVaultEntry {
  final String id;
  final PrivateVaultEntryKind kind;
  final String title;
  final String body;
  final String username;
  final String email;
  final String password;
  final String sharedSpaceId;
  final String sharedCredentialId;
  final int sharedRevision;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PrivateVaultEntry({
    required this.id,
    this.kind = PrivateVaultEntryKind.note,
    required this.title,
    required this.body,
    this.username = '',
    this.email = '',
    this.password = '',
    this.sharedSpaceId = '',
    this.sharedCredentialId = '',
    this.sharedRevision = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isCredential => kind == PrivateVaultEntryKind.credential;
  bool get isSharedCredential =>
      isCredential && sharedSpaceId.isNotEmpty && sharedCredentialId.isNotEmpty;
  String get service => title;
  String get notes => body;

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'title': title,
        'body': body,
        if (isCredential) 'username': username,
        if (isCredential) 'email': email,
        if (isCredential) 'password': password,
        if (isSharedCredential) 'sharedSpaceId': sharedSpaceId,
        if (isSharedCredential) 'sharedCredentialId': sharedCredentialId,
        if (isSharedCredential) 'sharedRevision': sharedRevision,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };

  factory PrivateVaultEntry.fromJson(Map<String, dynamic> json) {
    final rawKind = json['kind']?.toString();
    final kind = PrivateVaultEntryKind.values.firstWhere(
      (value) => value.name == rawKind,
      orElse: () => PrivateVaultEntryKind.note,
    );
    return PrivateVaultEntry(
      id: json['id']?.toString() ?? '',
      kind: kind,
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      password: json['password']?.toString() ?? '',
      sharedSpaceId: json['sharedSpaceId']?.toString() ?? '',
      sharedCredentialId: json['sharedCredentialId']?.toString() ?? '',
      sharedRevision: (json['sharedRevision'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '')
              ?.toLocal() ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '')
              ?.toLocal() ??
          DateTime.now(),
    );
  }
}

class PrivateVaultService extends ChangeNotifier {
  PrivateVaultService._();

  static final PrivateVaultService instance = PrivateVaultService._();

  static const _metaKey = 'private_vault_meta_v1';
  static const _payloadKey = 'private_vault_payload_v1';
  static const _version = 1;
  static const _legacyIterations = 180000;
  static const _currentIterations = 600000;
  static const _tagBits = 128;
  static const _nonceLength = 12;
  static const _masterKeyLength = 32;
  static const autoLockTimeout = Duration(minutes: 5);
  static const _keyAad = 'annas-diary-vault-key-v1';
  static const _payloadAad = 'annas-diary-vault-payload-v1';
  static const MethodChannel _native =
      MethodChannel('annas_diary/private_vault');

  final Random _random = Random.secure();
  final List<PrivateVaultEntry> _entries = [];
  final Map<String, Uint8List> _sharedPasswordKeys = {};
  CycleTrackerState _cycleTrackerState = const CycleTrackerState();

  LocalStateStore? _store;
  Uint8List? _masterKey;
  Map<String, dynamic>? _meta;
  bool _initialized = false;
  Timer? _autoLockTimer;

  bool get initialized => _initialized;
  bool get configured => _meta != null;
  bool get unlocked => _masterKey != null;
  bool get biometricAvailable =>
      (_meta?['biometricWrap'] as String?)?.isNotEmpty == true;
  List<PrivateVaultEntry> get entries =>
      List<PrivateVaultEntry>.unmodifiable(_entries);
  List<PrivateVaultEntry> get noteEntries => List<PrivateVaultEntry>.unmodifiable(
        _entries.where((entry) => !entry.isCredential),
      );
  List<PrivateVaultEntry> get credentialEntries =>
      List<PrivateVaultEntry>.unmodifiable(
        _entries.where((entry) => entry.isCredential),
      );
  CycleTrackerState get cycleTrackerState {
    _requireUnlocked();
    return _cycleTrackerState;
  }

  List<PrivateVaultEntry> sharedCredentialEntries(String spaceId) =>
      List<PrivateVaultEntry>.unmodifiable(
        _entries.where(
          (entry) => entry.isSharedCredential && entry.sharedSpaceId == spaceId,
        ),
      );

  bool hasSharedPasswordKey(String spaceId) =>
      _sharedPasswordKeys.containsKey(spaceId);

  Uint8List? sharedPasswordKeyCopy(String spaceId) {
    _requireUnlocked();
    final key = _sharedPasswordKeys[spaceId];
    return key == null ? null : Uint8List.fromList(key);
  }

  Future<void> initialize() async {
    if (_initialized) return;
    final legacy = await SharedPreferences.getInstance();
    _store = await LocalStateStore.instance.open(
      legacyPreferences: legacy,
    );
    final raw = _store!.getString(_metaKey);
    if (raw != null) {
      try {
        final parsed = Map<String, dynamic>.from(jsonDecode(raw) as Map);
        if (parsed['v'] == _version) {
          _meta = parsed;
        }
      } catch (_) {
        _meta = null;
      }
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> setup({
    required String password,
    required bool enableBiometric,
  }) async {
    await initialize();
    if (configured) {
      throw StateError('La cassaforte è già configurata.');
    }
    _validatePassword(password);

    final salt = _randomBytes(16);
    final master = _randomBytes(_masterKeyLength);
    final passwordKey = await deriveVaultPasswordKey(
      password: password,
      salt: salt,
      iterations: _currentIterations,
      length: _masterKeyLength,
    );
    try {
      final wrapped = _encrypt(
        key: passwordKey,
        plaintext: master,
        aad: _keyAad,
      );

      String? biometricWrap;
      if (enableBiometric && !kIsWeb) {
        try {
          biometricWrap = await _native.invokeMethod<String>(
            'protectMasterKey',
            {'key': base64UrlEncode(master)},
          );
        } catch (_) {
          biometricWrap = null;
        }
      }

      final nextMeta = <String, dynamic>{
        'v': _version,
        'salt': base64UrlEncode(salt),
        'iterations': _currentIterations,
        'passwordWrap': wrapped,
        'biometricWrap': biometricWrap,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
      };
      final initialPlaintext =
          Uint8List.fromList(utf8.encode('{"entries":[]}'));
      Map<String, dynamic> initialEnvelope;
      try {
        initialEnvelope = _encrypt(
          key: master,
          plaintext: initialPlaintext,
          aad: _payloadAad,
        );
      } finally {
        _zero(initialPlaintext);
      }

      await _store!.writeBatch({
        _metaKey: jsonEncode(nextMeta),
        _payloadKey: jsonEncode(initialEnvelope),
      });

      _meta = nextMeta;
      _masterKey = Uint8List.fromList(master);
      _entries.clear();
      _sharedPasswordKeys.clear();
      _cycleTrackerState = const CycleTrackerState();
      _armAutoLock();
      notifyListeners();
    } finally {
      _zero(passwordKey);
      _zero(master);
    }
  }

  Future<bool> unlockWithPassword(String password) async {
    await initialize();
    final meta = _meta;
    if (meta == null) return false;

    Uint8List? passwordKey;
    Uint8List? master;
    try {
      final salt = base64Url.decode(meta['salt'] as String);
      final iterations =
          (meta['iterations'] as num?)?.toInt() ?? _legacyIterations;
      if (iterations < 100000 || iterations > 2000000) return false;
      passwordKey = await deriveVaultPasswordKey(
        password: password,
        salt: salt,
        iterations: iterations,
        length: _masterKeyLength,
      );
      final wrapped = Map<String, dynamic>.from(meta['passwordWrap'] as Map);
      master = _decrypt(
        key: passwordKey,
        envelope: wrapped,
        aad: _keyAad,
      );
      if (master.length != _masterKeyLength) return false;

      _masterKey = Uint8List.fromList(master);
      await _loadEntries();

      if (iterations < _currentIterations) {
        try {
          await _upgradePasswordWrap(password, master);
        } catch (_) {
          // A failed hardening write must not lock the user out. The existing
          // wrap remains valid and the upgrade is retried on a later unlock.
        }
      }

      _armAutoLock();
      notifyListeners();
      return true;
    } catch (_) {
      final active = _masterKey;
      if (active != null) _zero(active);
      _masterKey = null;
      _entries.clear();
      for (final key in _sharedPasswordKeys.values) {
        _zero(key);
      }
      _sharedPasswordKeys.clear();
      _cycleTrackerState = const CycleTrackerState();
      return false;
    } finally {
      if (passwordKey != null) _zero(passwordKey);
      if (master != null) _zero(master);
    }
  }

  Future<bool> unlockWithBiometricKey() async {
    await initialize();
    final wrap = _meta?['biometricWrap'] as String?;
    if (kIsWeb || wrap == null || wrap.isEmpty) return false;
    try {
      final encoded = await _native.invokeMethod<String>(
        'unprotectMasterKey',
        {'blob': wrap},
      );
      if (encoded == null) return false;
      final master = base64Url.decode(encoded);
      try {
        if (master.length != _masterKeyLength) return false;
        _masterKey = Uint8List.fromList(master);
        await _loadEntries();
        _armAutoLock();
        notifyListeners();
        return true;
      } finally {
        _zero(master);
      }
    } catch (_) {
      return false;
    }
  }

  Future<bool> enableBiometricForCurrentKey() async {
    final master = _masterKey;
    if (kIsWeb || master == null || _meta == null) return false;
    try {
      final wrap = await _native.invokeMethod<String>(
        'protectMasterKey',
        {'key': base64UrlEncode(master)},
      );
      if (wrap == null || wrap.isEmpty) return false;
      _meta = {..._meta!, 'biometricWrap': wrap};
      await _store!.setString(_metaKey, jsonEncode(_meta));
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  void noteUserActivity() {
    if (!unlocked) return;
    _armAutoLock();
  }

  void _armAutoLock() {
    _autoLockTimer?.cancel();
    if (!unlocked) return;
    _autoLockTimer = Timer(autoLockTimeout, lock);
  }

  void lock() {
    _autoLockTimer?.cancel();
    _autoLockTimer = null;
    final key = _masterKey;
    if (key != null) _zero(key);
    _masterKey = null;
    _entries.clear();
    for (final key in _sharedPasswordKeys.values) {
      _zero(key);
    }
    _sharedPasswordKeys.clear();
    _cycleTrackerState = const CycleTrackerState();
    notifyListeners();
  }

  Future<void> upsert({
    String? id,
    required String title,
    required String body,
  }) async {
    _requireUnlocked();
    final cleanTitle = title.trim();
    final cleanBody = body.trim();
    if (cleanTitle.isEmpty && cleanBody.isEmpty) {
      throw const FormatException('Scrivi almeno un titolo o un contenuto.');
    }

    final now = DateTime.now();
    final existingIndex =
        id == null ? -1 : _entries.indexWhere((entry) => entry.id == id);
    if (existingIndex >= 0 && _entries[existingIndex].isSharedCredential) {
      throw StateError(
        'Le credenziali Noi ♡ si modificano tramite la sincronizzazione condivisa.',
      );
    }
    if (existingIndex >= 0) {
      final previous = _entries[existingIndex];
      _entries[existingIndex] = PrivateVaultEntry(
        id: previous.id,
        kind: PrivateVaultEntryKind.note,
        title: cleanTitle,
        body: cleanBody,
        createdAt: previous.createdAt,
        updatedAt: now,
      );
    } else {
      _entries.add(
        PrivateVaultEntry(
          id: id ?? _newId(),
          kind: PrivateVaultEntryKind.note,
          title: cleanTitle,
          body: cleanBody,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
    _sortEntries();
    await _persistEntries();
    notifyListeners();
  }

  Future<void> upsertCredential({
    String? id,
    required String service,
    required String username,
    required String email,
    required String password,
    required String notes,
  }) async {
    _requireUnlocked();
    final cleanService = service.trim();
    final cleanUsername = username.trim();
    final cleanEmail = email.trim();
    final cleanPassword = password;
    final cleanNotes = notes.trim();

    if (cleanService.isEmpty) {
      throw const FormatException('Inserisci il nome del servizio.');
    }
    if (cleanService.length > 160) {
      throw const FormatException('Il nome del servizio è troppo lungo.');
    }
    if (cleanUsername.length > 320 || cleanEmail.length > 320) {
      throw const FormatException('Nome utente o email troppo lunghi.');
    }
    if (cleanPassword.length > 4096) {
      throw const FormatException('La password è troppo lunga.');
    }
    if (cleanNotes.length > 12000) {
      throw const FormatException('Le note sono troppo lunghe.');
    }

    final now = DateTime.now();
    final existingIndex =
        id == null ? -1 : _entries.indexWhere((entry) => entry.id == id);
    if (existingIndex >= 0 && _entries[existingIndex].isSharedCredential) {
      throw StateError(
        'Le credenziali Noi ♡ si modificano tramite la sincronizzazione condivisa.',
      );
    }
    if (existingIndex >= 0) {
      final previous = _entries[existingIndex];
      _entries[existingIndex] = PrivateVaultEntry(
        id: previous.id,
        kind: PrivateVaultEntryKind.credential,
        title: cleanService,
        body: cleanNotes,
        username: cleanUsername,
        email: cleanEmail,
        password: cleanPassword,
        createdAt: previous.createdAt,
        updatedAt: now,
      );
    } else {
      _entries.add(
        PrivateVaultEntry(
          id: id ?? _newId(),
          kind: PrivateVaultEntryKind.credential,
          title: cleanService,
          body: cleanNotes,
          username: cleanUsername,
          email: cleanEmail,
          password: cleanPassword,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
    _sortEntries();
    await _persistEntries();
    notifyListeners();
  }

  Future<void> upsertCycleDayLog(CycleDayLog log) async {
    _requireUnlocked();
    final now = DateTime.now();
    final existing = _cycleTrackerState.logFor(log.date);
    final normalized = CycleDayLog(
      date: cycleDateOnly(log.date),
      flow: log.flow,
      painLevel: log.painLevel.clamp(0, 5),
      energyLevel: log.energyLevel.clamp(0, 5),
      symptoms: List<String>.unmodifiable(log.symptoms),
      moods: List<String>.unmodifiable(log.moods),
      discharge: log.discharge.trim(),
      hadSex: log.hadSex,
      basalTemperature: log.basalTemperature,
      ovulationTest: log.ovulationTest.trim(),
      notes: log.notes.trim(),
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    _cycleTrackerState = _cycleTrackerState.upsertLog(normalized);
    await _persistEntries();
    notifyListeners();
  }

  Future<void> deleteCycleDayLog(DateTime date) async {
    _requireUnlocked();
    if (_cycleTrackerState.logFor(date) == null) return;
    _cycleTrackerState = _cycleTrackerState.removeLog(date);
    await _persistEntries();
    notifyListeners();
  }

  Future<void> updateCycleSettings(CycleSettings settings) async {
    _requireUnlocked();
    _cycleTrackerState = _cycleTrackerState.withSettings(settings);
    await _persistEntries();
    notifyListeners();
  }

  Future<Uint8List> ensureSharedPasswordKey(String spaceId) async {
    _requireUnlocked();
    final normalized = spaceId.trim();
    if (normalized.isEmpty) {
      throw const FormatException('Spazio condiviso non valido.');
    }
    final existing = _sharedPasswordKeys[normalized];
    if (existing != null) return Uint8List.fromList(existing);

    final key = _randomBytes(_masterKeyLength);
    _sharedPasswordKeys[normalized] = Uint8List.fromList(key);
    await _persistEntries();
    notifyListeners();
    return Uint8List.fromList(key);
  }

  Future<void> importSharedPasswordKey(
    String spaceId,
    Uint8List key,
  ) async {
    _requireUnlocked();
    final normalized = spaceId.trim();
    if (normalized.isEmpty || key.length != _masterKeyLength) {
      throw const FormatException('Chiave Noi ♡ non valida.');
    }
    final previous = _sharedPasswordKeys[normalized];
    if (previous != null) _zero(previous);
    _sharedPasswordKeys[normalized] = Uint8List.fromList(key);
    await _persistEntries();
    notifyListeners();
  }

  Future<void> upsertSharedCredentialMirror({
    required String spaceId,
    required String credentialId,
    required String service,
    required String username,
    required String email,
    required String password,
    required String notes,
    required DateTime updatedAt,
    int sharedRevision = 0,
  }) async {
    _requireUnlocked();
    final mirrorId = 'shared:$spaceId:$credentialId';
    final index = _entries.indexWhere((entry) => entry.id == mirrorId);
    final createdAt = index >= 0 ? _entries[index].createdAt : updatedAt;
    final mirror = PrivateVaultEntry(
      id: mirrorId,
      kind: PrivateVaultEntryKind.credential,
      title: service.trim(),
      body: notes.trim(),
      username: username.trim(),
      email: email.trim(),
      password: password,
      sharedSpaceId: spaceId,
      sharedCredentialId: credentialId,
      sharedRevision: sharedRevision,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
    if (index >= 0) {
      _entries[index] = mirror;
    } else {
      _entries.add(mirror);
    }
    _sortEntries();
    await _persistEntries();
    notifyListeners();
  }

  Future<void> deleteSharedCredentialMirror(
    String spaceId,
    String credentialId,
  ) async {
    _requireUnlocked();
    final before = _entries.length;
    _entries.removeWhere(
      (entry) =>
          entry.isSharedCredential &&
          entry.sharedSpaceId == spaceId &&
          entry.sharedCredentialId == credentialId,
    );
    if (_entries.length == before) return;
    await _persistEntries();
    notifyListeners();
  }

  Future<void> removeSharedPasswordSpace(String spaceId) async {
    _requireUnlocked();
    final key = _sharedPasswordKeys.remove(spaceId);
    if (key != null) _zero(key);
    _entries.removeWhere(
      (entry) => entry.isSharedCredential && entry.sharedSpaceId == spaceId,
    );
    await _persistEntries();
    notifyListeners();
  }

  Future<void> reconcileSharedPasswordSpaces(Set<String> activeSpaceIds) async {
    _requireUnlocked();
    final staleSpaces = <String>{
      ..._sharedPasswordKeys.keys.where((id) => !activeSpaceIds.contains(id)),
      ..._entries
          .where(
            (entry) =>
                entry.isSharedCredential &&
                !activeSpaceIds.contains(entry.sharedSpaceId),
          )
          .map((entry) => entry.sharedSpaceId),
    };
    if (staleSpaces.isEmpty) return;
    for (final spaceId in staleSpaces) {
      final key = _sharedPasswordKeys.remove(spaceId);
      if (key != null) _zero(key);
      _entries.removeWhere(
        (entry) => entry.isSharedCredential && entry.sharedSpaceId == spaceId,
      );
    }
    await _persistEntries();
    notifyListeners();
  }

  Future<void> delete(String id) async {
    _requireUnlocked();
    final targetIndex = _entries.indexWhere((entry) => entry.id == id);
    if (targetIndex >= 0 && _entries[targetIndex].isSharedCredential) {
      throw StateError(
        'Le credenziali Noi ♡ si eliminano dalla sorgente condivisa.',
      );
    }
    _entries.removeWhere((entry) => entry.id == id);
    await _persistEntries();
    notifyListeners();
  }

  Future<void> destroy() async {
    await initialize();
    lock();
    await _store!.writeBatch({
      _metaKey: null,
      _payloadKey: null,
    });
    if (!kIsWeb) {
      try {
        await _native.invokeMethod<void>('deleteMasterKey');
      } catch (_) {}
    }
    _meta = null;
    notifyListeners();
  }

  @visibleForTesting
  void resetMemoryForTesting() {
    lock();
    _meta = null;
    _store = null;
    _initialized = false;
  }

  Future<void> setSecureScreen(bool enabled) async {
    if (kIsWeb) return;
    try {
      await _native.invokeMethod<void>(
        'setSecureScreen',
        {'enabled': enabled},
      );
    } catch (_) {}
  }

  Future<void> _loadEntries() async {
    final master = _masterKey;
    if (master == null) return;
    final raw = _store!.getString(_payloadKey);
    if (raw == null) {
      _entries.clear();
      return;
    }
    final envelope = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    final plaintext = _decrypt(
      key: master,
      envelope: envelope,
      aad: _payloadAad,
    );
    final decoded = Map<String, dynamic>.from(
      jsonDecode(utf8.decode(plaintext)) as Map,
    );
    final list = decoded['entries'] as List? ?? const [];
    final rawCycleTracker = decoded['cycleTracker'];
    _cycleTrackerState = rawCycleTracker is Map
        ? CycleTrackerState.fromJson(
            Map<String, dynamic>.from(rawCycleTracker),
          )
        : const CycleTrackerState();
    for (final key in _sharedPasswordKeys.values) {
      _zero(key);
    }
    _sharedPasswordKeys.clear();
    final rawSharedKeys = decoded['sharedPasswordKeys'];
    if (rawSharedKeys is Map) {
      for (final rawEntry in rawSharedKeys.entries) {
        try {
          final key = base64Url.decode(rawEntry.value.toString());
          if (key.length == _masterKeyLength) {
            _sharedPasswordKeys[rawEntry.key.toString()] =
                Uint8List.fromList(key);
          }
        } catch (_) {}
      }
    }
    _entries
      ..clear()
      ..addAll(
        list.map(
          (raw) => PrivateVaultEntry.fromJson(
            Map<String, dynamic>.from(raw as Map),
          ),
        ),
      );
    _sortEntries();
  }

  Future<void> _persistEntries() async {
    final master = _requireUnlocked();
    final plaintext = Uint8List.fromList(
      utf8.encode(
        jsonEncode({
          'entries': _entries.map((entry) => entry.toJson()).toList(),
          'sharedPasswordKeys': {
            for (final entry in _sharedPasswordKeys.entries)
              entry.key: base64UrlEncode(entry.value),
          },
          'cycleTracker': _cycleTrackerState.toJson(),
        }),
      ),
    );
    try {
      final envelope = _encrypt(
        key: master,
        plaintext: plaintext,
        aad: _payloadAad,
      );
      await _store!.setString(_payloadKey, jsonEncode(envelope));
    } finally {
      _zero(plaintext);
    }
  }

  Future<void> _upgradePasswordWrap(
    String password,
    Uint8List master,
  ) async {
    final current = _meta;
    if (current == null) return;

    final salt = _randomBytes(16);
    final passwordKey = await deriveVaultPasswordKey(
      password: password,
      salt: salt,
      iterations: _currentIterations,
      length: _masterKeyLength,
    );
    try {
      final wrapped = _encrypt(
        key: passwordKey,
        plaintext: master,
        aad: _keyAad,
      );
      final upgraded = <String, dynamic>{
        ...current,
        'salt': base64UrlEncode(salt),
        'iterations': _currentIterations,
        'passwordWrap': wrapped,
        'kdfUpgradedAt': DateTime.now().toUtc().toIso8601String(),
      };
      await _store!.setString(_metaKey, jsonEncode(upgraded));
      _meta = upgraded;
    } finally {
      _zero(passwordKey);
    }
  }

  Map<String, dynamic> _encrypt({
    required Uint8List key,
    required Uint8List plaintext,
    required String aad,
  }) {
    final nonce = _randomBytes(_nonceLength);
    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        true,
        AEADParameters(
          KeyParameter(key),
          _tagBits,
          nonce,
          Uint8List.fromList(utf8.encode(aad)),
        ),
      );
    final encrypted = cipher.process(plaintext);
    return {
      'nonce': base64UrlEncode(nonce),
      'data': base64UrlEncode(encrypted),
    };
  }

  Uint8List _decrypt({
    required Uint8List key,
    required Map<String, dynamic> envelope,
    required String aad,
  }) {
    final nonce = base64Url.decode(envelope['nonce'] as String);
    final encrypted = base64Url.decode(envelope['data'] as String);
    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        false,
        AEADParameters(
          KeyParameter(key),
          _tagBits,
          nonce,
          Uint8List.fromList(utf8.encode(aad)),
        ),
      );
    return cipher.process(encrypted);
  }

  Uint8List _randomBytes(int length) => Uint8List.fromList(
        List<int>.generate(length, (_) => _random.nextInt(256)),
      );

  String _newId() {
    final bytes = _randomBytes(16);
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  void _sortEntries() {
    _entries.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Uint8List _requireUnlocked() {
    final key = _masterKey;
    if (key == null) {
      throw StateError('La cassaforte è bloccata.');
    }
    return key;
  }

  void _validatePassword(String value) {
    if (value.length < 12) {
      throw const FormatException(
        'La password della cassaforte deve avere almeno 12 caratteri.',
      );
    }
  }

  void _zero(Uint8List bytes) {
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = 0;
    }
  }
}
