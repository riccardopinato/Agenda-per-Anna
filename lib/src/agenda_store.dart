part of '../main.dart';

class AgendaStore extends ChangeNotifier {
  static const _itemsKey = 'items_v1';
  static const _journalsKey = 'journals_v1';
  static const _monthsKey = 'months_v1';
  static const _weeksKey = 'weeks_v1';
  static const _habitsKey = 'habits_v1';
  static const _snapshotsKey = 'backup_snapshots_v1';
  static const _preferencesKey = 'agenda_preferences_v1';
  static const _inboxKey = 'inbox_v1';
  static const _syncQueueKey = 'cloud_sync_queue_v1';
  static const _syncIndexKey = 'cloud_sync_index_v1';
  static const _syncOwnerKey = 'cloud_sync_owner_v1';
  static const _accountProfilesKey = 'account_profiles_v1';
  static const _activeAccountKey = 'active_account_v1';
  static const _legacyClaimedByKey = 'legacy_claimed_by_v1';
  static const _privacyGuardKey = 'privacy_guard_v1';
  static const _backupFormat = 'agenda_per_anna_backup';
  static const _backupSchemaVersion = 1;
  static const _appVersion = '0.20.1';

  final List<AgendaItem> items = [];
  final Map<String, DayJournal> journals = {};
  final Map<String, MonthlyData> months = {};
  final Map<String, WeekData> weeks = {};
  final List<HabitDefinition> habits = [];
  final List<LocalBackupSnapshot> localSnapshots = [];
  final List<InboxEntry> inbox = [];
  final Map<String, CloudSyncOperation> _syncQueue = {};
  final Map<String, String> _syncIndex = {};
  final Map<String, List<AgendaItem>> _dayIndex = {};
  final Map<String, SharedSpace> _sharedAgendaSpaces = {};
  final Map<String, List<SharedEntry>> _sharedAgendaEntriesBySpace = {};
  final Map<String, List<UnifiedAgendaEntry>> _sharedAgendaDayIndex = {};
  final Map<String, int> _sharedUnreadBySpace = {};
  final Set<String> _unifiedRealtimeSpaceIds = {};
  bool _dayIndexDirty = true;
  AgendaContentFilter agendaContentFilter = AgendaContentFilter.all;
  final Set<String> _unreadableStorageKeys = {};
  AgendaPreferences preferences = const AgendaPreferences();

  Timer? _cloudSyncTimer;
  Timer? _syncDebounceTimer;
  Timer? _unifiedRealtimeDebounce;
  bool _cloudSyncRunning = false;
  bool _sharedFlushRunning = false;
  int _sharedConflictCount = 0;
  int _pendingSharedChangeCount = 0;
  DateTime? _lastSharedSyncAt;
  String? _activeAccountId;
  bool _accountScopeResolved = true;

  String? get activeAccountId => _activeAccountId;
  bool get accountScopeResolved => _accountScopeResolved;
  bool get hasStorageWarnings => _unreadableStorageKeys.isNotEmpty;
  int get sharedConflictCount => _sharedConflictCount;
  int get pendingSharedChangeCount => _pendingSharedChangeCount;
  int get totalPendingCloudChanges =>
      pendingCloudChanges + _pendingSharedChangeCount;
  int get totalSharedUnreadCount =>
      _sharedUnreadBySpace.values.fold(0, (sum, count) => sum + count);
  int sharedUnreadCount(String spaceId) => _sharedUnreadBySpace[spaceId] ?? 0;
  DateTime? get lastSharedSyncAt => _lastSharedSyncAt;
  List<SharedSpace> get sharedAgendaSpaces {
    final result = _sharedAgendaSpaces.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return List<SharedSpace>.unmodifiable(result);
  }

  List<UnifiedAgendaEntry> get unifiedAgendaItems {
    final result = <UnifiedAgendaEntry>[];
    if (agendaContentFilter != AgendaContentFilter.sharedOnly) {
      result.addAll(items.map(UnifiedAgendaEntry.private));
    }
    if (agendaContentFilter != AgendaContentFilter.privateOnly) {
      for (final space in _sharedAgendaSpaces.values) {
        for (final entry
            in _sharedAgendaEntriesBySpace[space.id] ?? const <SharedEntry>[]) {
          if (entry.type == SharedEntryType.note) continue;
          result.add(UnifiedAgendaEntry.shared(entry, space));
        }
      }
    }
    result.sort((a, b) {
      final byDate = a.date.compareTo(b.date);
      if (byDate != 0) return byDate;
      return a.sortMinutes.compareTo(b.sortMinutes);
    });
    return List<UnifiedAgendaEntry>.unmodifiable(result);
  }

  int get pendingUnifiedTaskCount => unifiedAgendaItems
      .where((entry) => entry.type == ItemType.task && !entry.done)
      .length;

  List<String> get _workingStorageKeys => const [
        _itemsKey,
        _journalsKey,
        _monthsKey,
        _weeksKey,
        _habitsKey,
        _snapshotsKey,
        _preferencesKey,
        _inboxKey,
        _syncQueueKey,
        _syncIndexKey,
        _syncOwnerKey,
      ];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _activeAccountId = prefs.getString(_activeAccountKey);
    _accountScopeResolved = _activeAccountId == null;
    _unreadableStorageKeys.clear();

    items.clear();
    journals.clear();
    months.clear();
    weeks.clear();
    habits.clear();
    localSnapshots.clear();
    inbox.clear();
    _syncQueue.clear();
    _syncIndex.clear();
    _sharedAgendaSpaces.clear();
    _sharedAgendaEntriesBySpace.clear();
    _sharedAgendaDayIndex.clear();
    _sharedUnreadBySpace.clear();
    _unifiedRealtimeSpaceIds.clear();
    _pendingSharedChangeCount = 0;
    preferences = const AgendaPreferences();

    T? decodeSection<T>(
      String key,
      T Function(dynamic value) parser,
    ) {
      final raw = prefs.getString(key);
      if (raw == null) return null;
      try {
        return parser(jsonDecode(raw));
      } catch (_) {
        _unreadableStorageKeys.add(key);
        return null;
      }
    }

    final parsedItems = decodeSection<List<AgendaItem>>(
      _itemsKey,
      (value) => (value as List)
          .map(
            (e) => AgendaItem.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
    );
    if (parsedItems != null) items.addAll(parsedItems);

    final parsedJournals = decodeSection<Map<String, DayJournal>>(
      _journalsKey,
      (value) => Map<String, dynamic>.from(value as Map).map(
        (key, raw) => MapEntry(
          key,
          DayJournal.fromJson(Map<String, dynamic>.from(raw as Map)),
        ),
      ),
    );
    if (parsedJournals != null) journals.addAll(parsedJournals);

    final parsedMonths = decodeSection<Map<String, MonthlyData>>(
      _monthsKey,
      (value) => Map<String, dynamic>.from(value as Map).map(
        (key, raw) => MapEntry(
          key,
          MonthlyData.fromJson(Map<String, dynamic>.from(raw as Map)),
        ),
      ),
    );
    if (parsedMonths != null) months.addAll(parsedMonths);

    final parsedWeeks = decodeSection<Map<String, WeekData>>(
      _weeksKey,
      (value) => Map<String, dynamic>.from(value as Map).map(
        (key, raw) => MapEntry(
          key,
          WeekData.fromJson(Map<String, dynamic>.from(raw as Map)),
        ),
      ),
    );
    if (parsedWeeks != null) weeks.addAll(parsedWeeks);

    final hadHabitsKey = prefs.containsKey(_habitsKey);
    final parsedHabits = decodeSection<List<HabitDefinition>>(
      _habitsKey,
      (value) => (value as List)
          .map(
            (e) => HabitDefinition.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
    );
    if (parsedHabits != null) habits.addAll(parsedHabits);

    final parsedSnapshots = decodeSection<List<LocalBackupSnapshot>>(
      _snapshotsKey,
      (value) => (value as List)
          .map(
            (e) => LocalBackupSnapshot.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
    );
    if (parsedSnapshots != null) localSnapshots.addAll(parsedSnapshots);

    final parsedPreferences = decodeSection<AgendaPreferences>(
      _preferencesKey,
      (value) => AgendaPreferences.fromJson(
        Map<String, dynamic>.from(value as Map),
      ),
    );
    if (parsedPreferences != null) {
      preferences = parsedPreferences;
    } else if (!prefs.containsKey(_preferencesKey)) {
      preferences = const AgendaPreferences(onboardingDone: false);
    }

    final privacyGuard = decodeSection<Map<String, dynamic>>(
      _privacyGuardKey,
      (value) => Map<String, dynamic>.from(value as Map),
    );
    if (privacyGuard != null) {
      preferences = preferences.copyWith(
        privacyLockEnabled:
            privacyGuard['privacyLockEnabled'] as bool? ??
                preferences.privacyLockEnabled,
        biometricUnlock:
            privacyGuard['biometricUnlock'] as bool? ??
                preferences.biometricUnlock,
        autoLockMinutes:
            privacyGuard['autoLockMinutes'] as int? ??
                preferences.autoLockMinutes,
        hideHomeDetails:
            privacyGuard['hideHomeDetails'] as bool? ??
                preferences.hideHomeDetails,
        pinSalt: privacyGuard['pinSalt'] as String?,
        pinHash: privacyGuard['pinHash'] as String?,
        clearPin: privacyGuard['pinSalt'] == null ||
            privacyGuard['pinHash'] == null,
      );
    } else if (parsedPreferences != null) {
      await prefs.setString(
        _privacyGuardKey,
        jsonEncode(_privacyGuardPayload()),
      );
    }

    final parsedInbox = decodeSection<List<InboxEntry>>(
      _inboxKey,
      (value) => (value as List)
          .map(
            (e) => InboxEntry.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
    );
    if (parsedInbox != null) inbox.addAll(parsedInbox);

    final parsedQueue = decodeSection<Map<String, CloudSyncOperation>>(
      _syncQueueKey,
      (value) => Map<String, dynamic>.from(value as Map).map(
        (key, raw) => MapEntry(
          key,
          CloudSyncOperation.fromJson(
            Map<String, dynamic>.from(raw as Map),
          ),
        ),
      ),
    );
    if (parsedQueue != null) _syncQueue.addAll(parsedQueue);

    final parsedIndex = decodeSection<Map<String, String>>(
      _syncIndexKey,
      (value) => Map<String, String>.from(
        Map<String, dynamic>.from(value as Map),
      ),
    );
    if (parsedIndex != null) _syncIndex.addAll(parsedIndex);

    if (!hadHabitsKey && !_unreadableStorageKeys.contains(_habitsKey)) {
      habits.addAll(const [
        HabitDefinition(id: 'water', name: 'Bere abbastanza'),
        HabitDefinition(id: 'move', name: 'Muovermi un po’'),
        HabitDefinition(id: 'me', name: 'Tempo per me'),
      ]);
    }
    _invalidateDayIndex();
    await _loadSharedUnreadCounts(prefs);
    await refreshSharedAgendaCache(notify: false);
    await refreshPendingSharedCount(notify: false);
  }

  Map<String, dynamic> _readAccountProfiles(SharedPreferences prefs) {
    final raw = prefs.getString(_accountProfilesKey);
    if (raw == null) return <String, dynamic>{};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  Map<String, dynamic> _captureWorkingProfile(
    SharedPreferences prefs,
  ) {
    final result = <String, dynamic>{};
    for (final key in _workingStorageKeys) {
      final raw = prefs.getString(key);
      if (raw != null) result[key] = raw;
    }
    return result;
  }

  Future<void> _writeWorkingProfile(
    SharedPreferences prefs,
    Map<String, dynamic> profile,
  ) async {
    for (final key in _workingStorageKeys) {
      final raw = profile[key];
      if (raw is String) {
        await prefs.setString(key, raw);
      } else {
        await prefs.remove(key);
      }
    }
  }

  Future<void> _archiveCurrentProfile(
    SharedPreferences prefs,
  ) async {
    final profiles = _readAccountProfiles(prefs);
    final scope = _activeAccountId == null
        ? 'guest'
        : 'user:$_activeAccountId';
    profiles[scope] = _captureWorkingProfile(prefs);
    await prefs.setString(_accountProfilesKey, jsonEncode(profiles));
  }

  bool _workingProfileHasUserData(SharedPreferences prefs) {
    for (final key in const [
      _itemsKey,
      _journalsKey,
      _monthsKey,
      _weeksKey,
      _habitsKey,
      _inboxKey,
    ]) {
      final raw = prefs.getString(key);
      if (raw != null && raw != '[]' && raw != '{}') return true;
    }
    return false;
  }

  Future<void> activateCloudAccount(String? accountId) async {
    final prefs = await SharedPreferences.getInstance();
    if (_activeAccountId == accountId) {
      if (accountId != null) {
        _bindPendingOperationsTo(accountId);
        await _persistSyncMetadata(prefs);
      }
      if (!_accountScopeResolved) {
        _accountScopeResolved = true;
        notifyListeners();
      }
      return;
    }

    await _archiveCurrentProfile(prefs);
    final profiles = _readAccountProfiles(prefs);
    final targetScope =
        accountId == null ? 'guest' : 'user:$accountId';

    if (accountId != null &&
        profiles[targetScope] == null &&
        prefs.getString(_legacyClaimedByKey) == null &&
        _activeAccountId == null &&
        _workingProfileHasUserData(prefs)) {
      profiles[targetScope] = _captureWorkingProfile(prefs);
      profiles['guest'] = <String, dynamic>{};
      await prefs.setString(_legacyClaimedByKey, accountId);
      await prefs.setString(_accountProfilesKey, jsonEncode(profiles));
    }

    final rawTarget = profiles[targetScope];
    final target = rawTarget is Map
        ? Map<String, dynamic>.from(rawTarget)
        : <String, dynamic>{};

    await _writeWorkingProfile(prefs, target);
    _activeAccountId = accountId;
    if (accountId == null) {
      await prefs.remove(_activeAccountKey);
    } else {
      await prefs.setString(_activeAccountKey, accountId);
    }

    await load();

    if (accountId != null) {
      _activeAccountId = accountId;
      _bindPendingOperationsTo(accountId);
      await prefs.setString(_activeAccountKey, accountId);
      await _persistSyncMetadata(prefs);
    }

    _accountScopeResolved = true;
    notifyListeners();
  }

  void _bindPendingOperationsTo(String ownerId) {
    for (final entry in _syncQueue.entries.toList()) {
      final operation = entry.value;
      if (operation.ownerId == ownerId) continue;
      if (operation.ownerId != null && operation.ownerId != ownerId) {
        continue;
      }
      _syncQueue[entry.key] = CloudSyncOperation(
        entityType: operation.entityType,
        entityId: operation.entityId,
        payload: operation.payload,
        updatedAt: operation.updatedAt,
        deleted: operation.deleted,
        ownerId: ownerId,
      );
    }
  }

  Future<void> _save({
    bool createAutoSnapshot = true,
    bool enqueueSync = true,
    Set<String>? onlyKeys,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    bool shouldWrite(String key) {
      return (onlyKeys == null || onlyKeys.contains(key)) &&
          !_unreadableStorageKeys.contains(key);
    }
    if (shouldWrite(_itemsKey)) {
      await prefs.setString(
        _itemsKey,
        jsonEncode(items.map((e) => e.toJson()).toList()),
      );
    }
    if (shouldWrite(_journalsKey)) {
      await prefs.setString(
        _journalsKey,
        jsonEncode(journals.map((k, v) => MapEntry(k, v.toJson()))),
      );
    }
    if (shouldWrite(_monthsKey)) {
      await prefs.setString(
        _monthsKey,
        jsonEncode(months.map((k, v) => MapEntry(k, v.toJson()))),
      );
    }
    if (shouldWrite(_weeksKey)) {
      await prefs.setString(
        _weeksKey,
        jsonEncode(weeks.map((k, v) => MapEntry(k, v.toJson()))),
      );
    }
    if (shouldWrite(_habitsKey)) {
      await prefs.setString(
        _habitsKey,
        jsonEncode(habits.map((e) => e.toJson()).toList()),
      );
    }
    if (shouldWrite(_preferencesKey)) {
      await prefs.setString(
        _preferencesKey,
        jsonEncode(preferences.toJson()),
      );
    }
    if (shouldWrite(_inboxKey)) {
      await prefs.setString(
        _inboxKey,
        jsonEncode(inbox.map((e) => e.toJson()).toList()),
      );
    }

    if (createAutoSnapshot) {
      await _maybeCreateAutomaticSnapshot(prefs);
    }

    if (enqueueSync) {
      await _captureSyncChanges(
        prefs,
        onlyKeys: onlyKeys,
      );
      _scheduleCloudSync();
    }
  }

  void _scheduleCloudSync() {
    final cloud = CloudSyncService.instance;
    if (!cloud.signedIn || _activeAccountId != cloud.userId) return;
    _syncDebounceTimer?.cancel();
    _syncDebounceTimer = Timer(
      const Duration(milliseconds: 900),
      () => unawaited(syncCloud()),
    );
  }

  Map<String, dynamic> _privacyGuardPayload() => {
        'privacyLockEnabled': preferences.privacyLockEnabled,
        'biometricUnlock': preferences.biometricUnlock,
        'autoLockMinutes': preferences.autoLockMinutes,
        'hideHomeDetails': preferences.hideHomeDetails,
        'pinSalt': preferences.pinSalt,
        'pinHash': preferences.pinHash,
      };

  Map<String, dynamic> _cloudPreferencesPayload() {
    return Map<String, dynamic>.from(preferences.toJson())
      ..remove('privacyLockEnabled')
      ..remove('biometricUnlock')
      ..remove('autoLockMinutes')
      ..remove('hideHomeDetails')
      ..remove('pinSalt')
      ..remove('pinHash')
      ..remove('onboardingDone');
  }

  Future<void> _queuePreferencesSync() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = _cloudPreferencesPayload();
    final key = 'preferences:main';
    _syncIndex[key] = _syncPayloadHash(payload);
    _syncQueue[key] = CloudSyncOperation(
      entityType: 'preferences',
      entityId: 'main',
      payload: payload,
      updatedAt: DateTime.now(),
      ownerId: _activeAccountId,
    );
    await _persistSyncMetadata(prefs);
    _scheduleCloudSync();
  }

  Map<String, _LocalSyncEntity> _currentSyncEntities({
    Set<String>? onlyKeys,
  }) {
    final result = <String, _LocalSyncEntity>{};

    bool includes(String key) =>
        onlyKeys == null || onlyKeys.contains(key);

    void add(
      String type,
      String id,
      Map<String, dynamic> payload,
    ) {
      final entity = _LocalSyncEntity(
        entityType: type,
        entityId: id,
        payload: payload,
      );
      result[entity.localKey] = entity;
    }

    if (includes(_itemsKey)) {
      for (final item in items) {
        add('item', item.id, item.toJson());
      }
    }
    if (includes(_journalsKey)) {
      for (final entry in journals.entries) {
        add('journal', entry.key, entry.value.toJson());
      }
    }
    if (includes(_monthsKey)) {
      for (final entry in months.entries) {
        add('month', entry.key, entry.value.toJson());
      }
    }
    if (includes(_weeksKey)) {
      for (final entry in weeks.entries) {
        add('week', entry.key, entry.value.toJson());
      }
    }
    if (includes(_habitsKey)) {
      for (final habit in habits) {
        add('habit', habit.id, habit.toJson());
      }
    }
    if (includes(_inboxKey)) {
      for (final entry in inbox) {
        add('inbox', entry.id, entry.toJson());
      }
    }
    if (includes(_preferencesKey)) {
      add('preferences', 'main', _cloudPreferencesPayload());
    }

    return result;
  }

  String _syncPayloadHash(Map<String, dynamic> payload) =>
      sha256.convert(utf8.encode(jsonEncode(payload))).toString();

  String? _storageKeyForEntityType(String type) => switch (type) {
        'item' => _itemsKey,
        'journal' => _journalsKey,
        'month' => _monthsKey,
        'week' => _weeksKey,
        'habit' => _habitsKey,
        'inbox' => _inboxKey,
        'preferences' => _preferencesKey,
        _ => null,
      };

  Future<void> _captureSyncChanges(
    SharedPreferences prefs, {
    bool forceAll = false,
    Set<String>? onlyKeys,
  }) async {
    final entities = _currentSyncEntities(onlyKeys: onlyKeys);
    final now = DateTime.now();

    for (final entry in entities.entries) {
      final hash = _syncPayloadHash(entry.value.payload);
      if (forceAll || _syncIndex[entry.key] != hash) {
        _syncQueue[entry.key] = CloudSyncOperation(
          entityType: entry.value.entityType,
          entityId: entry.value.entityId,
          payload: entry.value.payload,
          updatedAt: now,
          ownerId: _activeAccountId,
        );
      }
    }

    for (final oldKey in _syncIndex.keys.toList()) {
      if (entities.containsKey(oldKey)) continue;
      final splitAt = oldKey.indexOf(':');
      if (splitAt <= 0) continue;
      final entityType = oldKey.substring(0, splitAt);
      final storageKey = _storageKeyForEntityType(entityType);
      if (onlyKeys != null &&
          (storageKey == null || !onlyKeys.contains(storageKey))) {
        continue;
      }
      _syncQueue[oldKey] = CloudSyncOperation(
        entityType: entityType,
        entityId: oldKey.substring(splitAt + 1),
        payload: null,
        updatedAt: now,
        deleted: true,
        ownerId: _activeAccountId,
      );
    }

    _replaceSyncIndex(
      entities,
      onlyKeys: onlyKeys,
    );
    await _persistSyncMetadata(prefs);
  }

  void _replaceSyncIndex(
    Map<String, _LocalSyncEntity> entities, {
    Set<String>? onlyKeys,
  }) {
    if (onlyKeys == null) {
      _syncIndex.clear();
    } else {
      _syncIndex.removeWhere((key, _) {
        final splitAt = key.indexOf(':');
        if (splitAt <= 0) return false;
        final storageKey =
            _storageKeyForEntityType(key.substring(0, splitAt));
        return storageKey != null && onlyKeys.contains(storageKey);
      });
    }

    _syncIndex.addEntries(
      entities.entries.map(
        (entry) => MapEntry(
          entry.key,
          _syncPayloadHash(entry.value.payload),
        ),
      ),
    );
  }

  Future<void> _persistSyncMetadata(SharedPreferences prefs) async {
    await prefs.setString(
      _syncQueueKey,
      jsonEncode(
        _syncQueue.map((key, value) => MapEntry(key, value.toJson())),
      ),
    );
    await prefs.setString(_syncIndexKey, jsonEncode(_syncIndex));
  }

  Map<String, dynamic> _backupDataPayload() => {
        'items': items.map((e) => e.toJson()).toList(),
        'journals': journals.map((k, v) => MapEntry(k, v.toJson())),
        'months': months.map((k, v) => MapEntry(k, v.toJson())),
        'weeks': weeks.map((k, v) => MapEntry(k, v.toJson())),
        'habits': habits.map((e) => e.toJson()).toList(),
        'inbox': inbox.map((e) => e.toJson()).toList(),
        'preferences': preferences.toJson(),
      };

  String createBackupJson() {
    final document = {
      'format': _backupFormat,
      'schemaVersion': _backupSchemaVersion,
      'appVersion': _appVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'data': _backupDataPayload(),
    };
    return const JsonEncoder.withIndent('  ').convert(document);
  }

  BackupSummary inspectBackup(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Il file non contiene un backup valido.');
    }

    final root = Map<String, dynamic>.from(decoded);
    if (root['format'] != _backupFormat) {
      throw const FormatException('Questo file non appartiene ad Agenda per Anna.');
    }

    final schema = root['schemaVersion'];
    if (schema is! int || schema > _backupSchemaVersion || schema < 1) {
      throw const FormatException('Versione del backup non supportata.');
    }

    final data = root['data'];
    if (data is! Map) {
      throw const FormatException('Il backup non contiene dati leggibili.');
    }

    final payload = Map<String, dynamic>.from(data);
    final exportedAt =
        DateTime.tryParse(root['exportedAt'] as String? ?? '') ??
            DateTime.now();

    return BackupSummary(
      exportedAt: exportedAt,
      itemCount: (payload['items'] as List? ?? const []).length,
      journalCount: (payload['journals'] as Map? ?? const {}).length,
      monthCount: (payload['months'] as Map? ?? const {}).length,
      weekCount: (payload['weeks'] as Map? ?? const {}).length,
      habitCount: (payload['habits'] as List? ?? const []).length,
    );
  }

  Future<void> restoreBackup(
    String raw, {
    required bool merge,
  }) async {
    final decoded = jsonDecode(raw);
    final root = Map<String, dynamic>.from(decoded as Map);
    inspectBackup(raw);

    final payload =
        Map<String, dynamic>.from(root['data'] as Map<String, dynamic>);

    final incomingItems = (payload['items'] as List? ?? const [])
        .map(
          (e) => AgendaItem.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
    final incomingJournals =
        Map<String, dynamic>.from(payload['journals'] as Map? ?? const {})
            .map(
      (k, v) => MapEntry(
        k,
        DayJournal.fromJson(Map<String, dynamic>.from(v as Map)),
      ),
    );
    final incomingMonths =
        Map<String, dynamic>.from(payload['months'] as Map? ?? const {}).map(
      (k, v) => MapEntry(
        k,
        MonthlyData.fromJson(Map<String, dynamic>.from(v as Map)),
      ),
    );
    final incomingWeeks =
        Map<String, dynamic>.from(payload['weeks'] as Map? ?? const {}).map(
      (k, v) => MapEntry(
        k,
        WeekData.fromJson(Map<String, dynamic>.from(v as Map)),
      ),
    );
    final incomingHabits = (payload['habits'] as List? ?? const [])
        .map(
          (e) => HabitDefinition.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
    final incomingInbox = (payload['inbox'] as List? ?? const [])
        .map(
          (e) => InboxEntry.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
    final incomingPreferences = payload['preferences'] is Map
        ? AgendaPreferences.fromJson(
            Map<String, dynamic>.from(payload['preferences'] as Map),
          )
        : null;
    final backupContainsHabits = payload.containsKey('habits');

    // Everything above is parsed before any user data is mutated.
    await createLocalSnapshot(label: 'Prima del ripristino');

    final oldItems = [...items];

    if (merge) {
      final byId = {for (final item in items) item.id: item};
      for (final item in incomingItems) {
        byId[item.id] = item;
      }
      items
        ..clear()
        ..addAll(byId.values);

      journals.addAll(incomingJournals);
      months.addAll(incomingMonths);
      weeks.addAll(incomingWeeks);

      final habitsById = {for (final habit in habits) habit.id: habit};
      for (final habit in incomingHabits) {
        habitsById[habit.id] = habit;
      }
      habits
        ..clear()
        ..addAll(habitsById.values);

      final inboxById = {for (final entry in inbox) entry.id: entry};
      for (final entry in incomingInbox) {
        inboxById[entry.id] = entry;
      }
      inbox
        ..clear()
        ..addAll(inboxById.values);
    } else {
      items
        ..clear()
        ..addAll(incomingItems);
      journals
        ..clear()
        ..addAll(incomingJournals);
      months
        ..clear()
        ..addAll(incomingMonths);
      weeks
        ..clear()
        ..addAll(incomingWeeks);
      habits
        ..clear()
        ..addAll(incomingHabits);
      inbox
        ..clear()
        ..addAll(incomingInbox);
      if (incomingPreferences != null) {
        preferences = incomingPreferences;
      }
    }

    _invalidateDayIndex();

    if (habits.isEmpty && !backupContainsHabits) {
      habits.addAll(const [
        HabitDefinition(id: 'water', name: 'Bere abbastanza'),
        HabitDefinition(id: 'move', name: 'Muovermi un po’'),
        HabitDefinition(id: 'me', name: 'Tempo per me'),
      ]);
    }

    for (final item in oldItems) {
      await NotificationService.instance.cancel(item.id);
      await NotificationService.instance.cancel('${item.id}:primary');
      await NotificationService.instance.cancel('${item.id}:secondary');
    }

    await _save(createAutoSnapshot: false);

    if (!merge && incomingPreferences != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _privacyGuardKey,
        jsonEncode(_privacyGuardPayload()),
      );
    }

    for (final item in items) {
      await _syncReminders(item);
    }

    notifyListeners();
  }

  Future<void> createLocalSnapshot({
    String label = 'Backup manuale',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    localSnapshots.insert(
      0,
      LocalBackupSnapshot(
        id: const Uuid().v4(),
        createdAt: DateTime.now(),
        label: label,
        data: jsonDecode(jsonEncode(_backupDataPayload()))
            as Map<String, dynamic>,
      ),
    );
    if (localSnapshots.length > 5) {
      localSnapshots.removeRange(5, localSnapshots.length);
    }
    await _saveSnapshots(prefs);
    notifyListeners();
  }

  Future<void> _maybeCreateAutomaticSnapshot(
    SharedPreferences prefs,
  ) async {
    final now = DateTime.now();
    final shouldCreate = localSnapshots.isEmpty ||
        now.difference(localSnapshots.first.createdAt).inHours >= 6;
    if (!shouldCreate) return;

    localSnapshots.insert(
      0,
      LocalBackupSnapshot(
        id: const Uuid().v4(),
        createdAt: now,
        label: 'Backup automatico',
        data: jsonDecode(jsonEncode(_backupDataPayload()))
            as Map<String, dynamic>,
      ),
    );
    if (localSnapshots.length > 5) {
      localSnapshots.removeRange(5, localSnapshots.length);
    }
    await _saveSnapshots(prefs);
  }

  Future<void> _saveSnapshots(SharedPreferences prefs) async {
    await prefs.setString(
      _snapshotsKey,
      jsonEncode(localSnapshots.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> restoreLocalSnapshot(String id) async {
    final snapshot = localSnapshots.firstWhere((e) => e.id == id);
    final document = {
      'format': _backupFormat,
      'schemaVersion': _backupSchemaVersion,
      'appVersion': _appVersion,
      'exportedAt': snapshot.createdAt.toIso8601String(),
      'data': snapshot.data,
    };
    await restoreBackup(jsonEncode(document), merge: false);
  }

  Future<void> deleteLocalSnapshot(String id) async {
    localSnapshots.removeWhere((e) => e.id == id);
    final prefs = await SharedPreferences.getInstance();
    await _saveSnapshots(prefs);
    notifyListeners();
  }

  String createReadableExport() {
    final buffer = StringBuffer();
    final now = DateTime.now();

    buffer.writeln('AGENDA PER ANNA');
    buffer.writeln('Esportazione del ${DateFormat('d MMMM yyyy, HH:mm', 'it_IT').format(now)}');
    buffer.writeln();
    buffer.writeln('============================================================');
    buffer.writeln('IMPEGNI E ATTIVITÀ');
    buffer.writeln('============================================================');

    final sortedItems = [...items]..sort((a, b) {
      final dateCompare = a.date.compareTo(b.date);
      if (dateCompare != 0) return dateCompare;
      final am = a.start == null ? 9999 : a.start!.hour * 60 + a.start!.minute;
      final bm = b.start == null ? 9999 : b.start!.hour * 60 + b.start!.minute;
      return am.compareTo(bm);
    });

    if (sortedItems.isEmpty) {
      buffer.writeln('Nessun impegno salvato.');
    } else {
      for (final item in sortedItems) {
        final date = DateFormat('d MMMM yyyy', 'it_IT').format(item.date);
        final time = item.start == null ? '' : ' · ${formatTime(item.start!)}';
        buffer.writeln('- $date$time · ${item.title}');
        buffer.writeln('  Categoria: ${item.category.label}');
        if (item.note.trim().isNotEmpty) {
          buffer.writeln('  Note: ${item.note.trim()}');
        }
      }
    }

    buffer.writeln();
    buffer.writeln('============================================================');
    buffer.writeln('DIARIO');
    buffer.writeln('============================================================');

    final journalEntries = journals.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    if (journalEntries.isEmpty) {
      buffer.writeln('Nessuna pagina di diario salvata.');
    } else {
      for (final entry in journalEntries) {
        final date = DateTime.tryParse(entry.key);
        final journal = entry.value;
        buffer.writeln();
        buffer.writeln(
          date == null
              ? entry.key
              : DateFormat('d MMMM yyyy', 'it_IT').format(date),
        );
        if (journal.mood != null) {
          buffer.writeln('Mood: ${journal.mood!.emoji} ${journal.mood!.label}');
        }
        if (journal.gratitude.isNotEmpty) {
          buffer.writeln('Cose belle:');
          for (final value in journal.gratitude) {
            buffer.writeln('  • $value');
          }
        }
        if (journal.beautiful.trim().isNotEmpty) {
          buffer.writeln('Da ricordare: ${journal.beautiful.trim()}');
        }
        if (journal.note.trim().isNotEmpty) {
          buffer.writeln('Pensieri: ${journal.note.trim()}');
        }
      }
    }

    buffer.writeln();
    buffer.writeln('============================================================');
    buffer.writeln('PAGINE MENSILI');
    buffer.writeln('============================================================');

    final monthEntries = months.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    for (final entry in monthEntries) {
      final parts = entry.key.split('-');
      if (parts.length != 2) continue;
      final y = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (y == null || m == null) continue;
      final data = entry.value;
      buffer.writeln();
      buffer.writeln(
        _cap(DateFormat('MMMM yyyy', 'it_IT').format(DateTime(y, m))),
      );
      if (data.monthWord.isNotEmpty) {
        buffer.writeln('Parola del mese: ${data.monthWord}');
      }
      if (data.intention.isNotEmpty) {
        buffer.writeln('Intenzione: ${data.intention}');
      }
      if (data.goals.isNotEmpty) {
        buffer.writeln('Obiettivi: ${data.goals.join(' · ')}');
      }
      if (data.books.isNotEmpty) {
        buffer.writeln('Libri: ${data.books.join(' · ')}');
      }
      if (data.films.isNotEmpty) {
        buffer.writeln('Film e serie: ${data.films.join(' · ')}');
      }
      if (data.wishes.isNotEmpty) {
        buffer.writeln('Desideri: ${data.wishes.join(' · ')}');
      }
      if (data.bestMoment.isNotEmpty) {
        buffer.writeln('Momento più bello: ${data.bestMoment}');
      }
      if (data.reflection.isNotEmpty) {
        buffer.writeln('Riflessione: ${data.reflection}');
      }
    }

    return buffer.toString();
  }

  void _invalidateDayIndex() {
    _dayIndexDirty = true;
  }

  void _ensureDayIndex() {
    if (!_dayIndexDirty) return;
    _dayIndex.clear();
    for (final item in items) {
      (_dayIndex[dateKey(item.date)] ??= <AgendaItem>[]).add(item);
    }
    for (final dayItems in _dayIndex.values) {
      dayItems.sort((a, b) {
        final am =
            a.start == null ? 9999 : a.start!.hour * 60 + a.start!.minute;
        final bm =
            b.start == null ? 9999 : b.start!.hour * 60 + b.start!.minute;
        return am.compareTo(bm);
      });
    }
    _dayIndexDirty = false;
  }

  List<AgendaItem> forDay(DateTime date) {
    _ensureDayIndex();
    return List<AgendaItem>.unmodifiable(
      _dayIndex[dateKey(date)] ?? const <AgendaItem>[],
    );
  }

  Future<void> upsert(AgendaItem item) async {
    final index = items.indexWhere((e) => e.id == item.id);
    if (index < 0) {
      items.add(item);
    } else {
      items[index] = item;
    }
    _invalidateDayIndex();
    await _save(onlyKeys: {_itemsKey});
    await _syncReminders(item);
    notifyListeners();
  }

  Future<void> duplicateItem(AgendaItem item, {DateTime? date}) async {
    final copy = AgendaItem(
      id: const Uuid().v4(),
      title: item.title,
      note: item.note,
      date: date == null
          ? item.date
          : DateTime(date.year, date.month, date.day),
      type: item.type,
      category: item.category,
      reminderMinutesBefore: item.reminderMinutesBefore,
      secondaryReminderMinutesBefore: item.secondaryReminderMinutesBefore,
      start: item.start,
      end: item.end,
      done: false,
    );
    await upsert(copy);
  }

  Future<void> deleteItem(String id) async {
    items.removeWhere((e) => e.id == id);
    _invalidateDayIndex();
    await NotificationService.instance.cancel(id);
    await NotificationService.instance.cancel('$id:primary');
    await NotificationService.instance.cancel('$id:secondary');
    await _save(onlyKeys: {_itemsKey});
    notifyListeners();
  }

  Future<void> _syncReminders(AgendaItem item) async {
    final start = item.start;

    // Pulisce anche il vecchio ID usato dalla versione a promemoria singolo.
    await NotificationService.instance.cancel(item.id);

    if (start == null || item.done) {
      await NotificationService.instance.cancel('${item.id}:primary');
      await NotificationService.instance.cancel('${item.id}:secondary');
      return;
    }

    final eventTime = DateTime(
      item.date.year,
      item.date.month,
      item.date.day,
      start.hour,
      start.minute,
    );

    Future<void> syncOne(String suffix, int? minutes) async {
      final stableId = '${item.id}:$suffix';
      if (minutes == null) {
        await NotificationService.instance.cancel(stableId);
        return;
      }

      final when = eventTime.subtract(Duration(minutes: minutes));
      await NotificationService.instance.schedule(
        stableId: stableId,
        title: item.title,
        body: minutes == 0
            ? 'È il momento di iniziare.'
            : _reminderBody(minutes, item.title),
        when: when,
      );
    }

    await syncOne('primary', item.reminderMinutesBefore);
    await syncOne('secondary', item.secondaryReminderMinutesBefore);
  }

  Future<void> reconcileReminders() async {
    for (final item in items) {
      await _syncReminders(item);
    }
  }

  String _reminderBody(int minutes, String title) {
    if (minutes == 1440) return 'Domani: $title';
    if (minutes == 120) return 'Tra 2 ore: $title';
    if (minutes == 60) return 'Tra 1 ora: $title';
    return 'Tra $minutes minuti: $title';
  }

  Future<void> toggle(String id) async {
    final i = items.indexWhere((e) => e.id == id);
    if (i < 0) return;
    items[i] = items[i].copyWith(done: !items[i].done);
    _invalidateDayIndex();
    await _save(onlyKeys: {_itemsKey});
    await _syncReminders(items[i]);
    notifyListeners();
  }

  DayJournal journal(DateTime date) => journals[dateKey(date)] ?? const DayJournal();

  Future<void> saveJournal(DateTime date, DayJournal journal) async {
    journals[dateKey(date)] = journal;
    await _save(onlyKeys: {_journalsKey});
    notifyListeners();
  }

  Future<void> initializeCloudSync() async {
    _cloudSyncTimer?.cancel();

    final cloud = CloudSyncService.instance;
    if (cloud.initialized) {
      await activateCloudAccount(cloud.signedIn ? cloud.userId : null);
    } else {
      _accountScopeResolved = true;
      notifyListeners();
    }

    if (cloud.signedIn) {
      await syncAllCloud(preferRemoteOnFirstSync: true);
    }

    // Reconcile private + shared state periodically in case Realtime or a
    // network transition was missed while the app stayed open.
    _cloudSyncTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) {
        if (CloudSyncService.instance.signedIn) {
          unawaited(syncAllCloud());
        }
      },
    );
  }

  Future<void> handleAppResumed() async {
    final cloud = CloudSyncService.instance;
    if (!cloud.initialized) {
      await cloud.initialize();
    }

    if (cloud.initialized) {
      await activateCloudAccount(cloud.signedIn ? cloud.userId : null);
    } else if (!_accountScopeResolved) {
      _accountScopeResolved = true;
      notifyListeners();
    }

    if (cloud.signedIn) {
      await syncAllCloud();
    }
  }

  Future<void> syncAllCloud({
    bool preferRemoteOnFirstSync = false,
  }) async {
    final cloud = CloudSyncService.instance;
    if (!cloud.configured || !cloud.initialized || !cloud.signedIn) {
      return;
    }

    await flushSharedPendingOperations();
    await syncCloud(
      preferRemoteOnFirstSync: preferRemoteOnFirstSync,
    );

    if (!cloud.signedIn ||
        cloud.userId == null ||
        _activeAccountId != cloud.userId) {
      return;
    }

    await refreshSharedAgendaCache(pullRemote: true);
    await refreshPendingSharedCount();
  }

  Future<void> syncCloud({
    bool preferRemoteOnFirstSync = false,
  }) async {
    final cloud = CloudSyncService.instance;
    if (!cloud.configured || !cloud.initialized || !cloud.signedIn) return;
    if (_cloudSyncRunning) return;

    final ownerId = cloud.userId!;
    if (_activeAccountId != ownerId) {
      await activateCloudAccount(ownerId);
    }
    if (_activeAccountId != ownerId) return;

    final sessionEpoch = cloud.sessionEpoch;
    _cloudSyncRunning = true;
    cloud.markSyncStarted();

    try {
      final prefs = await SharedPreferences.getInstance();
      final previousOwner = prefs.getString(_syncOwnerKey);
      final firstSyncForOwner = previousOwner != ownerId;

      final firstSnapshotKey = 'cloud_first_sync_snapshot_$ownerId';
      if (firstSyncForOwner &&
          prefs.getBool(firstSnapshotKey) != true &&
          (items.isNotEmpty ||
              journals.isNotEmpty ||
              months.isNotEmpty ||
              weeks.isNotEmpty ||
              inbox.isNotEmpty)) {
        await createLocalSnapshot(
          label: 'Prima sincronizzazione cloud',
        );
        await prefs.setBool(firstSnapshotKey, true);
      }

      if (firstSyncForOwner && _syncIndex.isEmpty) {
        await _captureSyncChanges(
          prefs,
          forceAll: true,
        );
        _bindPendingOperationsTo(ownerId);
      }

      final remote = await cloud.pullPrivateRecords();

      if (cloud.sessionEpoch != sessionEpoch ||
          cloud.userId != ownerId ||
          _activeAccountId != ownerId) {
        return;
      }

      var remoteChanged = false;
      for (final record in remote) {
        final localOp = _syncQueue[record.localKey];
        final remoteWins = preferRemoteOnFirstSync && firstSyncForOwner
            ? true
            : localOp == null ||
                !localOp.updatedAt.isAfter(record.clientUpdatedAt);

        if (!remoteWins) continue;

        final changed = await _applyRemoteRecord(record);
        remoteChanged = remoteChanged || changed;
        _syncQueue.remove(record.localKey);
      }

      if (remoteChanged) {
        final entitiesAfterPull = _currentSyncEntities();
        _replaceSyncIndex(entitiesAfterPull);
        await _save(
          createAutoSnapshot: false,
          enqueueSync: false,
        );
      }

      if (cloud.sessionEpoch != sessionEpoch ||
          cloud.userId != ownerId ||
          _activeAccountId != ownerId) {
        return;
      }

      final pendingSnapshot =
          Map<String, CloudSyncOperation>.from(_syncQueue)
            ..removeWhere(
              (_, operation) =>
                  operation.ownerId != null &&
                  operation.ownerId != ownerId,
            );

      await cloud.pushPrivateOperations(pendingSnapshot.values);

      if (cloud.sessionEpoch != sessionEpoch ||
          cloud.userId != ownerId ||
          _activeAccountId != ownerId) {
        return;
      }

      for (final entry in pendingSnapshot.entries) {
        final current = _syncQueue[entry.key];
        if (current != null &&
            current.updatedAt == entry.value.updatedAt &&
            current.ownerId == entry.value.ownerId) {
          _syncQueue.remove(entry.key);
        }
      }

      await prefs.setString(_syncOwnerKey, ownerId);
      await _persistSyncMetadata(prefs);

      cloud.markSyncSuccess();
      if (remoteChanged || pendingSnapshot.isNotEmpty) {
        notifyListeners();
      }
    } catch (error) {
      cloud.markSyncError(error);
    } finally {
      _cloudSyncRunning = false;
    }
  }

  Future<bool> _applyRemoteRecord(CloudRemoteRecord record) async {
    if (record.deletedAt != null) {
      switch (record.entityType) {
        case 'item':
          final existed = items.any((e) => e.id == record.entityId);
          if (!existed) return false;
          items.removeWhere((e) => e.id == record.entityId);
          _invalidateDayIndex();
          await NotificationService.instance.cancel(record.entityId);
          await NotificationService.instance
              .cancel('${record.entityId}:primary');
          await NotificationService.instance
              .cancel('${record.entityId}:secondary');
          return true;
        case 'journal':
          return journals.remove(record.entityId) != null;
        case 'month':
          return months.remove(record.entityId) != null;
        case 'week':
          return weeks.remove(record.entityId) != null;
        case 'habit':
          final before = habits.length;
          habits.removeWhere((e) => e.id == record.entityId);
          return habits.length != before;
        case 'inbox':
          final before = inbox.length;
          inbox.removeWhere((e) => e.id == record.entityId);
          return inbox.length != before;
        case 'preferences':
          return false;
      }
    }

    final payload = record.payload;
    if (payload == null) return false;

    switch (record.entityType) {
      case 'item':
        final item = AgendaItem.fromJson(payload);
        final index = items.indexWhere((e) => e.id == item.id);
        if (index >= 0 &&
            _syncPayloadHash(items[index].toJson()) ==
                _syncPayloadHash(item.toJson())) {
          return false;
        }
        if (index < 0) {
          items.add(item);
        } else {
          items[index] = item;
        }
        _invalidateDayIndex();
        await _syncReminders(item);
        return true;
      case 'journal':
        final incoming = DayJournal.fromJson(payload);
        final current = journals[record.entityId];
        if (current != null &&
            _syncPayloadHash(current.toJson()) ==
                _syncPayloadHash(incoming.toJson())) {
          return false;
        }
        journals[record.entityId] = incoming;
        return true;
      case 'month':
        final incoming = MonthlyData.fromJson(payload);
        final current = months[record.entityId];
        if (current != null &&
            _syncPayloadHash(current.toJson()) ==
                _syncPayloadHash(incoming.toJson())) {
          return false;
        }
        months[record.entityId] = incoming;
        return true;
      case 'week':
        final incoming = WeekData.fromJson(payload);
        final current = weeks[record.entityId];
        if (current != null &&
            _syncPayloadHash(current.toJson()) ==
                _syncPayloadHash(incoming.toJson())) {
          return false;
        }
        weeks[record.entityId] = incoming;
        return true;
      case 'habit':
        final incoming = HabitDefinition.fromJson(payload);
        final index = habits.indexWhere((e) => e.id == incoming.id);
        if (index >= 0 &&
            _syncPayloadHash(habits[index].toJson()) ==
                _syncPayloadHash(incoming.toJson())) {
          return false;
        }
        if (index < 0) {
          habits.add(incoming);
        } else {
          habits[index] = incoming;
        }
        return true;
      case 'inbox':
        final incoming = InboxEntry.fromJson(payload);
        final index = inbox.indexWhere((e) => e.id == incoming.id);
        if (index >= 0 &&
            _syncPayloadHash(inbox[index].toJson()) ==
                _syncPayloadHash(incoming.toJson())) {
          return false;
        }
        if (index < 0) {
          inbox.add(incoming);
        } else {
          inbox[index] = incoming;
        }
        return true;
      case 'preferences':
        if (_syncPayloadHash(_cloudPreferencesPayload()) ==
            _syncPayloadHash(payload)) {
          return false;
        }
        preferences = preferences.copyWith(
          displayName: payload['displayName'] as String?,
          themeMode: AgendaThemeMode.values.firstWhere(
            (e) => e.name == payload['themeMode'],
            orElse: () => preferences.themeMode,
          ),
          palette: AgendaPalette.values.firstWhere(
            (e) => e.name == payload['palette'],
            orElse: () => preferences.palette,
          ),
          showDailyQuote:
              payload['showDailyQuote'] as bool? ??
                  preferences.showDailyQuote,
          startTab: StartTab.values.firstWhere(
            (e) => e.name == payload['startTab'],
            orElse: () => preferences.startTab,
          ),
          defaultCategory: AgendaCategory.values.firstWhere(
            (e) => e.name == payload['defaultCategory'],
            orElse: () => preferences.defaultCategory,
          ),
          defaultEventMinutes:
              (payload['defaultEventMinutes'] as int?) ??
                  preferences.defaultEventMinutes,
          defaultPrimaryReminder:
              payload['defaultPrimaryReminder'] as int?,
          defaultSecondaryReminder:
              payload['defaultSecondaryReminder'] as int?,
          clearPrimaryReminder:
              payload['defaultPrimaryReminder'] == null,
          clearSecondaryReminder:
              payload['defaultSecondaryReminder'] == null,
        );
        return true;
    }
    return false;
  }

  void setAgendaContentFilter(AgendaContentFilter value) {
    if (agendaContentFilter == value) return;
    agendaContentFilter = value;
    notifyListeners();
  }

  List<UnifiedAgendaEntry> unifiedForDay(DateTime date) {
    final result = <UnifiedAgendaEntry>[];
    final key = dateKey(date);

    if (agendaContentFilter != AgendaContentFilter.sharedOnly) {
      _ensureDayIndex();
      result.addAll(
        (_dayIndex[key] ?? const <AgendaItem>[])
            .map(UnifiedAgendaEntry.private),
      );
    }

    if (agendaContentFilter != AgendaContentFilter.privateOnly) {
      result.addAll(
        _sharedAgendaDayIndex[key] ?? const <UnifiedAgendaEntry>[],
      );
    }

    result.sort((a, b) => a.sortMinutes.compareTo(b.sortMinutes));
    return List<UnifiedAgendaEntry>.unmodifiable(result);
  }

  void _rebuildSharedAgendaDayIndex() {
    _sharedAgendaDayIndex.clear();
    for (final space in _sharedAgendaSpaces.values) {
      for (final entry
          in _sharedAgendaEntriesBySpace[space.id] ?? const <SharedEntry>[]) {
        if (entry.type == SharedEntryType.note) continue;
        final unified = UnifiedAgendaEntry.shared(entry, space);
        (_sharedAgendaDayIndex[dateKey(entry.date)] ??=
                <UnifiedAgendaEntry>[])
            .add(unified);
      }
    }
    for (final dayEntries in _sharedAgendaDayIndex.values) {
      dayEntries.sort((a, b) => a.sortMinutes.compareTo(b.sortMinutes));
    }
  }

  List<UnifiedAgendaEntry> unifiedUpcoming(DateTime now) {
    final result = unifiedAgendaItems.where((entry) {
      if (entry.done || entry.start == null) return false;
      final at = DateTime(
        entry.date.year,
        entry.date.month,
        entry.date.day,
        entry.start!.hour,
        entry.start!.minute,
      );
      return at.isAfter(now);
    }).toList()
      ..sort((a, b) {
        final at = DateTime(
          a.date.year,
          a.date.month,
          a.date.day,
          a.start!.hour,
          a.start!.minute,
        );
        final bt = DateTime(
          b.date.year,
          b.date.month,
          b.date.day,
          b.start!.hour,
          b.start!.minute,
        );
        return at.compareTo(bt);
      });
    return List<UnifiedAgendaEntry>.unmodifiable(result);
  }

  int unifiedMonthCount(int year, int month) => unifiedAgendaItems
      .where((entry) => entry.date.year == year && entry.date.month == month)
      .length;

  Future<void> refreshSharedAgendaCache({
    bool pullRemote = false,
    bool notify = true,
  }) async {
    final ownerId = _activeAccountId;
    if (ownerId == null) {
      _sharedAgendaSpaces.clear();
      _sharedAgendaEntriesBySpace.clear();
      if (notify) notifyListeners();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final cloud = CloudSyncService.instance;
    List<SharedSpace> spaces = const [];
    var remoteSpacesLoaded = false;

    if (pullRemote && cloud.signedIn && cloud.userId == ownerId) {
      try {
        spaces = await cloud.listSharedSpaces();
        remoteSpacesLoaded = true;
        await prefs.setString(
          sharedSpacesCacheStorageKey,
          jsonEncode(
            spaces
                .map(
                  (space) => {
                    'id': space.id,
                    'owner_id': space.ownerId,
                    'name': space.name,
                    'role': space.role,
                    'created_at': space.createdAt.toIso8601String(),
                  },
                )
                .toList(),
          ),
        );
      } catch (_) {
        spaces = const [];
      }
    }

    if (!remoteSpacesLoaded && spaces.isEmpty) {
      final rawSpaces = prefs.getString(sharedSpacesCacheStorageKey);
      if (rawSpaces != null) {
        try {
          spaces = (jsonDecode(rawSpaces) as List)
              .map((raw) => Map<String, dynamic>.from(raw as Map))
              .map(
                (raw) => SharedSpace.fromJson(
                  raw,
                  role: raw['role'] as String? ?? 'member',
                ),
              )
              .toList();
        } catch (_) {
          spaces = const [];
        }
      }
    }

    final nextEntries = <String, List<SharedEntry>>{};
    for (final space in spaces) {
      var entries = <SharedEntry>[];
      var remoteEntriesLoaded = false;

      if (pullRemote && cloud.signedIn && cloud.userId == ownerId) {
        try {
          final records = await cloud.pullSharedRecords(space.id);
          remoteEntriesLoaded = true;
          entries = records
              .where(
                (record) =>
                    record.entityType == 'shared_entry' &&
                    record.deletedAt == null &&
                    record.payload != null,
              )
              .map(
                (record) => SharedEntry.fromJson(
                  record.payload!,
                  updatedBy: record.updatedBy,
                  updatedAt: record.clientUpdatedAt,
                ),
              )
              .toList();
        } catch (_) {
          entries = <SharedEntry>[];
        }
      }

      if (!remoteEntriesLoaded && entries.isEmpty) {
        final raw = prefs.getString(sharedCacheStorageKey(space.id));
        if (raw != null) {
          try {
            entries = (jsonDecode(raw) as List)
                .map(
                  (rawEntry) => SharedEntry.fromCacheJson(
                    Map<String, dynamic>.from(rawEntry as Map),
                  ),
                )
                .toList();
          } catch (_) {
            entries = <SharedEntry>[];
          }
        }
      }

      final pending = await loadSharedPendingOperations(space.id);
      for (final operation in pending) {
        entries.removeWhere((entry) => entry.id == operation.entityId);
        if (operation.action == SharedPendingAction.upsert &&
            operation.payload != null) {
          entries.add(
            SharedEntry.fromJson(
              operation.payload!,
              updatedBy: ownerId,
              updatedAt: operation.updatedAt,
            ),
          );
        }
      }

      entries.sort((a, b) {
        final dateCompare = a.date.compareTo(b.date);
        if (dateCompare != 0) return dateCompare;
        final am =
            a.start == null ? 24 * 60 + 1 : a.start!.hour * 60 + a.start!.minute;
        final bm =
            b.start == null ? 24 * 60 + 1 : b.start!.hour * 60 + b.start!.minute;
        return am.compareTo(bm);
      });
      nextEntries[space.id] = entries;
      await prefs.setString(
        sharedCacheStorageKey(space.id),
        jsonEncode(entries.map((entry) => entry.toCacheJson()).toList()),
      );
    }

    _sharedAgendaSpaces
      ..clear()
      ..addEntries(spaces.map((space) => MapEntry(space.id, space)));
    _sharedAgendaEntriesBySpace
      ..clear()
      ..addAll(nextEntries);
    _rebuildSharedAgendaDayIndex();

    final activeSpaceIds = spaces.map((space) => space.id).toSet();
    final staleUnreadIds = _sharedUnreadBySpace.keys
        .where((spaceId) => !activeSpaceIds.contains(spaceId))
        .toList();
    if (staleUnreadIds.isNotEmpty) {
      for (final spaceId in staleUnreadIds) {
        _sharedUnreadBySpace.remove(spaceId);
      }
      await _saveSharedUnreadCounts();
    }

    await _bindUnifiedRealtime(spaces);
    if (notify) notifyListeners();
  }

  Future<void> _bindUnifiedRealtime(List<SharedSpace> spaces) async {
    final nextIds = spaces.map((space) => space.id).toSet();
    final cloud = CloudSyncService.instance;

    for (final oldId in _unifiedRealtimeSpaceIds.difference(nextIds).toList()) {
      await cloud.unsubscribeSharedSpace(
        spaceId: oldId,
        listenerKey: 'unified-agenda',
      );
      _unifiedRealtimeSpaceIds.remove(oldId);
    }

    if (!cloud.signedIn) return;
    for (final space in spaces) {
      cloud.subscribeSharedSpace(
        spaceId: space.id,
        listenerKey: 'unified-agenda',
        onUpdatedBy: (updatedBy) {
          if (updatedBy != null && updatedBy != cloud.userId) {
            unawaited(markSharedSpaceUnread(space.id));
          }
        },
        onChanged: () {
          _unifiedRealtimeDebounce?.cancel();
          _unifiedRealtimeDebounce = Timer(
            const Duration(milliseconds: 450),
            () => unawaited(
              refreshSharedAgendaCache(pullRemote: true),
            ),
          );
        },
      );
      _unifiedRealtimeSpaceIds.add(space.id);
    }
  }

  Future<void> _cacheSharedAgendaEntries(
    String spaceId,
    List<SharedEntry> entries,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      sharedCacheStorageKey(spaceId),
      jsonEncode(entries.map((entry) => entry.toCacheJson()).toList()),
    );
  }

  String sharedCacheStorageKey(String spaceId) {
    final owner = _activeAccountId ?? 'guest';
    return 'shared_cache_${owner}_$spaceId';
  }

  String sharedPendingStorageKey(String spaceId) {
    final owner = _activeAccountId ?? 'guest';
    return 'shared_pending_${owner}_$spaceId';
  }

  String get sharedSpacesCacheStorageKey {
    final owner = _activeAccountId ?? 'guest';
    return 'shared_spaces_$owner';
  }

  String get sharedUnreadStorageKey {
    final owner = _activeAccountId ?? 'guest';
    return 'shared_unread_$owner';
  }

  Future<void> _loadSharedUnreadCounts(SharedPreferences prefs) async {
    final raw = prefs.getString(sharedUnreadStorageKey);
    if (raw == null) return;
    try {
      final decoded = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      _sharedUnreadBySpace
        ..clear()
        ..addEntries(
          decoded.entries.map(
            (entry) => MapEntry(
              entry.key,
              max(0, (entry.value as num?)?.toInt() ?? 0),
            ),
          ),
        );
    } catch (_) {
      _sharedUnreadBySpace.clear();
    }
  }

  Future<void> _saveSharedUnreadCounts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      sharedUnreadStorageKey,
      jsonEncode(_sharedUnreadBySpace),
    );
  }

  Future<void> markSharedSpaceUnread(
    String spaceId, {
    int amount = 1,
  }) async {
    if (_activeAccountId == null || amount <= 0) return;
    final next = min(999, sharedUnreadCount(spaceId) + amount);
    if (next == sharedUnreadCount(spaceId)) return;
    _sharedUnreadBySpace[spaceId] = next;
    await _saveSharedUnreadCounts();
    notifyListeners();
  }

  Future<void> markSharedSpaceRead(String spaceId) async {
    if (!_sharedUnreadBySpace.containsKey(spaceId)) return;
    _sharedUnreadBySpace.remove(spaceId);
    await _saveSharedUnreadCounts();
    notifyListeners();
  }

  Future<List<SharedPendingOperation>> loadSharedPendingOperations(
    String spaceId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(sharedPendingStorageKey(spaceId));
    if (raw == null) return <SharedPendingOperation>[];
    try {
      return (jsonDecode(raw) as List)
          .map(
            (rawOperation) => SharedPendingOperation.fromJson(
              Map<String, dynamic>.from(rawOperation as Map),
            ),
          )
          .where((operation) => operation.entityId.isNotEmpty)
          .toList();
    } catch (_) {
      return <SharedPendingOperation>[];
    }
  }

  Future<void> _saveSharedPendingOperations(
    String spaceId,
    List<SharedPendingOperation> operations,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = sharedPendingStorageKey(spaceId);
    if (operations.isEmpty) {
      await prefs.remove(key);
    } else {
      await prefs.setString(
        key,
        jsonEncode(
          operations.map((operation) => operation.toJson()).toList(),
        ),
      );
    }
  }

  Future<void> enqueueSharedUpsert({
    required String spaceId,
    required SharedEntry entry,
    DateTime? updatedAt,
  }) async {
    final revision = (updatedAt ?? DateTime.now()).toUtc();
    final operations = await loadSharedPendingOperations(spaceId);
    operations.removeWhere((operation) => operation.entityId == entry.id);
    operations.add(
      SharedPendingOperation(
        action: SharedPendingAction.upsert,
        entityId: entry.id,
        payload: entry.toJson(),
        updatedAt: revision,
      ),
    );
    await _saveSharedPendingOperations(spaceId, operations);
    await refreshPendingSharedCount(notify: false);
    final cached = List<SharedEntry>.from(
      _sharedAgendaEntriesBySpace[spaceId] ?? const <SharedEntry>[],
    )
      ..removeWhere((cachedEntry) => cachedEntry.id == entry.id)
      ..add(
        entry.copyWith(
          updatedBy: CloudSyncService.instance.userId,
          updatedAt: revision,
        ),
      );
    _sharedAgendaEntriesBySpace[spaceId] = cached;
    _rebuildSharedAgendaDayIndex();
    await _cacheSharedAgendaEntries(spaceId, cached);
    notifyListeners();
  }

  Future<void> enqueueSharedDelete({
    required String spaceId,
    required String entityId,
    DateTime? updatedAt,
  }) async {
    final revision = (updatedAt ?? DateTime.now()).toUtc();
    final operations = await loadSharedPendingOperations(spaceId);
    operations.removeWhere((operation) => operation.entityId == entityId);
    operations.add(
      SharedPendingOperation(
        action: SharedPendingAction.delete,
        entityId: entityId,
        updatedAt: revision,
      ),
    );
    await _saveSharedPendingOperations(spaceId, operations);
    await refreshPendingSharedCount(notify: false);
    final cached = List<SharedEntry>.from(
      _sharedAgendaEntriesBySpace[spaceId] ?? const <SharedEntry>[],
    )..removeWhere((entry) => entry.id == entityId);
    _sharedAgendaEntriesBySpace[spaceId] = cached;
    _rebuildSharedAgendaDayIndex();
    await _cacheSharedAgendaEntries(spaceId, cached);
    notifyListeners();
  }

  Future<int> pendingSharedChanges(String spaceId) async =>
      (await loadSharedPendingOperations(spaceId)).length;

  Future<Set<String>> pendingSharedEntityIds(String spaceId) async =>
      (await loadSharedPendingOperations(spaceId))
          .map((operation) => operation.entityId)
          .toSet();

  Future<void> refreshPendingSharedCount({
    bool notify = true,
  }) async {
    final ownerId = _activeAccountId;
    var next = 0;

    if (ownerId != null) {
      final prefs = await SharedPreferences.getInstance();
      final prefix = 'shared_pending_${ownerId}_';
      for (final key in prefs.getKeys().where((key) => key.startsWith(prefix))) {
        final raw = prefs.getString(key);
        if (raw == null) continue;
        try {
          next += (jsonDecode(raw) as List).length;
        } catch (_) {
          // Preserve unreadable queues; only exclude them from the badge.
        }
      }
    }

    if (next == _pendingSharedChangeCount) return;
    _pendingSharedChangeCount = next;
    if (notify) notifyListeners();
  }

  void resetSharedConflictCount() {
    if (_sharedConflictCount == 0) return;
    _sharedConflictCount = 0;
    notifyListeners();
  }

  Future<void> flushSharedPendingOperations({
    String? spaceId,
  }) async {
    final cloud = CloudSyncService.instance;
    final ownerId = _activeAccountId;
    if (!cloud.signedIn ||
        ownerId == null ||
        cloud.userId != ownerId ||
        _sharedFlushRunning) {
      return;
    }

    _sharedFlushRunning = true;
    var stateChanged = false;
    final pendingBefore = _pendingSharedChangeCount;
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefix = 'shared_pending_${ownerId}_';
      final keys = prefs
          .getKeys()
          .where(
            (key) =>
                key.startsWith(prefix) &&
                (spaceId == null || key == sharedPendingStorageKey(spaceId)),
          )
          .toList();

      for (final key in keys) {
        final currentSpaceId = key.substring(prefix.length);
        final raw = prefs.getString(key);
        if (raw == null) continue;

        List<SharedPendingOperation> snapshot;
        try {
          snapshot = (jsonDecode(raw) as List)
              .map(
                (rawOperation) => SharedPendingOperation.fromJson(
                  Map<String, dynamic>.from(rawOperation as Map),
                ),
              )
              .where((operation) => operation.entityId.isNotEmpty)
              .toList();
        } catch (_) {
          continue;
        }

        Future<void> removeExactOperation(
          SharedPendingOperation operation,
        ) async {
          final latestRaw = prefs.getString(key);
          if (latestRaw == null) return;
          try {
            final latest = (jsonDecode(latestRaw) as List)
                .map(
                  (rawOperation) => SharedPendingOperation.fromJson(
                    Map<String, dynamic>.from(rawOperation as Map),
                  ),
                )
                .toList();
            latest.removeWhere(
              (candidate) =>
                  candidate.entityId == operation.entityId &&
                  candidate.action == operation.action &&
                  candidate.updatedAt.toUtc() ==
                      operation.updatedAt.toUtc(),
            );
            if (latest.isEmpty) {
              await prefs.remove(key);
            } else {
              await prefs.setString(
                key,
                jsonEncode(
                  latest.map((candidate) => candidate.toJson()).toList(),
                ),
              );
            }
          } catch (_) {
            // Preserve a queue we cannot safely parse.
          }
        }

        for (final operation in snapshot) {
          try {
            if (operation.action == SharedPendingAction.delete) {
              await cloud.deleteSharedRecord(
                spaceId: currentSpaceId,
                entityType: 'shared_entry',
                entityId: operation.entityId,
                updatedAt: operation.updatedAt,
              );
            } else if (operation.payload != null) {
              await cloud.upsertSharedRecord(
                spaceId: currentSpaceId,
                entityType: 'shared_entry',
                entityId: operation.entityId,
                payload: operation.payload!,
                updatedAt: operation.updatedAt,
              );
            } else {
              continue;
            }

            if (cloud.userId != ownerId || _activeAccountId != ownerId) {
              return;
            }

            await removeExactOperation(operation);
            _lastSharedSyncAt = DateTime.now();
            stateChanged = true;
          } catch (error) {
            if (error is StateError &&
                error.message == 'remote_record_is_newer') {
              await removeExactOperation(operation);
              _sharedConflictCount++;
              _lastSharedSyncAt = DateTime.now();
              stateChanged = true;
            }
            // Network and permission errors stay queued for a later retry.
          }
        }
      }
    } finally {
      _sharedFlushRunning = false;
      await refreshPendingSharedCount(notify: false);
      if (stateChanged || pendingBefore != _pendingSharedChangeCount) {
        notifyListeners();
      }
    }
  }
  int get pendingCloudChanges => _syncQueue.length;

  Future<void> addInboxEntry(String text) async {
    final value = text.trim();
    if (value.isEmpty) return;
    inbox.insert(
      0,
      InboxEntry(
        id: const Uuid().v4(),
        text: value,
        createdAt: DateTime.now(),
      ),
    );
    await _save(onlyKeys: {_inboxKey});
    notifyListeners();
  }

  Future<void> deleteInboxEntry(String id) async {
    inbox.removeWhere((e) => e.id == id);
    await _save(onlyKeys: {_inboxKey});
    notifyListeners();
  }

  Future<void> toggleInboxPinned(String id) async {
    final index = inbox.indexWhere((e) => e.id == id);
    if (index < 0) return;
    inbox[index] = inbox[index].copyWith(pinned: !inbox[index].pinned);
    await _save(onlyKeys: {_inboxKey});
    notifyListeners();
  }

  Future<void> toggleItemPinned(String id) async {
    final index = items.indexWhere((e) => e.id == id);
    if (index < 0) return;
    items[index] = items[index].copyWith(pinned: !items[index].pinned);
    _invalidateDayIndex();
    await _save(onlyKeys: {_itemsKey});
    notifyListeners();
  }

  Future<void> setPin(String pin) async {
    final normalized = pin.trim();
    final validPin = RegExp(r'^\d{4,8}$').hasMatch(normalized);
    if (!validPin) {
      throw const FormatException(
        'Il PIN deve contenere da 4 a 8 cifre.',
      );
    }
    final saltBytes = List<int>.generate(
      16,
      (_) => Random.secure().nextInt(256),
    );
    final salt = base64UrlEncode(saltBytes);
    final hash = _derivePinHash(normalized, salt);
    await savePreferences(
      preferences.copyWith(
        pinSalt: salt,
        pinHash: hash,
        privacyLockEnabled: true,
      ),
    );
  }

  bool verifyPin(String pin) {
    final salt = preferences.pinSalt;
    final expected = preferences.pinHash;
    if (salt == null || expected == null) return false;
    return _derivePinHash(pin.trim(), salt) == expected;
  }

  Future<void> savePreferences(AgendaPreferences value) async {
    preferences = value;
    final prefs = await SharedPreferences.getInstance();
    if (!_unreadableStorageKeys.contains(_preferencesKey)) {
      await prefs.setString(
        _preferencesKey,
        jsonEncode(preferences.toJson()),
      );
    }
    await prefs.setString(
      _privacyGuardKey,
      jsonEncode(_privacyGuardPayload()),
    );
    await _queuePreferencesSync();
    notifyListeners();
  }

  Future<void> resetPreferences() async {
    await savePreferences(const AgendaPreferences());
  }

  Future<void> addHabit(String name) async {
    final value = name.trim();
    if (value.isEmpty) return;
    habits.add(HabitDefinition(id: const Uuid().v4(), name: value));
    await _save(onlyKeys: {_habitsKey});
    notifyListeners();
  }

  Future<void> removeHabit(String id) async {
    habits.removeWhere((e) => e.id == id);
    for (final entry in journals.entries.toList()) {
      final journal = entry.value;
      if (journal.completedHabitIds.contains(id)) {
        journals[entry.key] = journal.copyWith(
          completedHabitIds: journal.completedHabitIds
              .where((habitId) => habitId != id)
              .toList(),
        );
      }
    }
    await _save(onlyKeys: {_habitsKey, _journalsKey});
    notifyListeners();
  }

  Future<void> toggleHabit(DateTime date, String habitId) async {
    final current = journal(date);
    final completed = [...current.completedHabitIds];
    if (completed.contains(habitId)) {
      completed.remove(habitId);
    } else {
      completed.add(habitId);
    }
    journals[dateKey(date)] = current.copyWith(completedHabitIds: completed);
    await _save(onlyKeys: {_journalsKey});
    notifyListeners();
  }

  MonthlyData month(int year, int month) => months[monthKey(year, month)] ?? const MonthlyData();

  Future<void> saveMonth(int year, int month, MonthlyData value) async {
    months[monthKey(year, month)] = value;
    await _save(onlyKeys: {_monthsKey});
    notifyListeners();
  }

  WeekData week(DateTime anyDay) {
    final monday = mondayOf(anyDay);
    return weeks[dateKey(monday)] ?? const WeekData();
  }

  Future<void> saveWeek(DateTime anyDay, WeekData value) async {
    final monday = mondayOf(anyDay);
    weeks[dateKey(monday)] = value;
    await _save(onlyKeys: {_weeksKey});
    notifyListeners();
  }

  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String monthKey(int y, int m) => '$y-${m.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _cloudSyncTimer?.cancel();
    _syncDebounceTimer?.cancel();
    _unifiedRealtimeDebounce?.cancel();
    for (final spaceId in _unifiedRealtimeSpaceIds.toList()) {
      unawaited(
        CloudSyncService.instance.unsubscribeSharedSpace(
          spaceId: spaceId,
          listenerKey: 'unified-agenda',
        ),
      );
    }
    _unifiedRealtimeSpaceIds.clear();
    super.dispose();
  }
}
