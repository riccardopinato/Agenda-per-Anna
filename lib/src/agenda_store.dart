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
  static const _forceFullSyncKey = 'cloud_force_full_sync_v1';
  static const _accountProfilesKey = 'account_profiles_v1';
  static const _activeAccountKey = 'active_account_v1';
  static const _legacyClaimedByKey = 'legacy_claimed_by_v1';
  static const _privacyGuardKey = 'privacy_guard_v1';
  static const _entityDeltaPrefix = 'entity_delta_v2_';
  static const _privateSyncCursorPrefix = 'cloud_private_cursor_v2_';
  static const _sharedSyncCursorPrefix = 'cloud_shared_cursor_v2_';
  static const _backupFormat = 'agenda_per_anna_backup';
  static const _backupBundleFormat = 'agenda_per_anna_backup_bundle';
  static const _backupSchemaVersion = 1;
  static const _backupBundleVersion = 1;
  static const _appVersion = appReleaseVersion;

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
  final List<UnifiedAgendaEntry> _unifiedAgendaCache = [];
  final Map<String, int> _unifiedMonthCountCache = {};
  final ValueNotifier<int> shellRevision = ValueNotifier<int>(0);
  final Map<String, int> _sharedUnreadBySpace = {};
  final Set<String> _unifiedRealtimeSpaceIds = {};
  bool _dayIndexDirty = true;
  bool _unifiedAgendaCacheDirty = true;
  int _pendingUnifiedTaskCountCache = 0;
  AgendaContentFilter agendaContentFilter = AgendaContentFilter.all;
  final Set<String> _unreadableStorageKeys = {};
  AgendaPreferences preferences = const AgendaPreferences();

  Timer? _cloudSyncTimer;
  Timer? _syncDebounceTimer;
  Timer? _unifiedRealtimeDebounce;
  Timer? _mediaMaintenanceTimer;
  Timer? _deferredCloudSyncTimer;
  bool _cloudSyncRunning = false;
  bool _sharedFlushRunning = false;
  bool _sharedInteractionFlushRunning = false;
  bool _sharedMediaFlushRunning = false;
  int _sharedConflictCount = 0;
  int _pendingSharedChangeCount = 0;
  int _pendingSharedInteractionCount = 0;
  int _pendingSharedMediaCount = 0;
  DateTime? _lastSharedSyncAt;
  String? _activeAccountId;
  bool _accountScopeResolved = true;

  String? get activeAccountId => _activeAccountId;
  bool get accountScopeResolved => _accountScopeResolved;
  bool get hasStorageWarnings => _unreadableStorageKeys.isNotEmpty;
  int get sharedConflictCount => _sharedConflictCount;
  int get pendingSharedChangeCount => _pendingSharedChangeCount;
  int get pendingSharedInteractionCount => _pendingSharedInteractionCount;
  int get pendingSharedMediaCount => _pendingSharedMediaCount;
  int get totalPendingCloudChanges =>
      pendingCloudChanges +
      _pendingSharedChangeCount +
      _pendingSharedInteractionCount +
      _pendingSharedMediaCount;
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
    _ensureUnifiedAgendaCache();
    return List<UnifiedAgendaEntry>.unmodifiable(_unifiedAgendaCache);
  }

  int get pendingUnifiedTaskCount {
    _ensureUnifiedAgendaCache();
    return _pendingUnifiedTaskCountCache;
  }

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
        _forceFullSyncKey,
      ];

  Future<LocalStateStore> _localState() async {
    final legacyPreferences = await SharedPreferences.getInstance();
    return LocalStateStore.instance.open(
      legacyPreferences: legacyPreferences,
    );
  }

  String _entityScopeToken([String? accountId]) {
    final scope = accountId == null ? 'guest' : 'user:$accountId';
    return base64UrlEncode(utf8.encode(scope));
  }

  String _entityDeltaScopePrefix([String? accountId]) =>
      '$_entityDeltaPrefix${_entityScopeToken(accountId)}:';

  String _privateSyncCursorKey(String ownerId) =>
      '$_privateSyncCursorPrefix${_entityScopeToken(ownerId)}';

  String _sharedSyncCursorKey(String spaceId) =>
      '$_sharedSyncCursorPrefix${_entityScopeToken(_activeAccountId)}:'
      '${base64UrlEncode(utf8.encode(spaceId))}';

  DateTime? _readSyncCursor(LocalStateStore prefs, String key) =>
      DateTime.tryParse(prefs.getString(key) ?? '')?.toUtc();

  DateTime _nextSyncCursor(
    DateTime? current,
    Iterable<DateTime> revisions,
  ) {
    var next = current;
    for (final revision in revisions) {
      final value = revision.toUtc();
      if (next == null || value.isAfter(next)) next = value;
    }
    return next ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }

  String _entityDeltaKey(String type, String id) =>
      '${_entityDeltaScopePrefix(_activeAccountId)}$type:'
      '${base64UrlEncode(utf8.encode(id))}';

  Set<String> _activeEntityDeltaKeys(LocalStateStore prefs) {
    final prefix = _entityDeltaScopePrefix(_activeAccountId);
    return prefs.getKeys().where((key) => key.startsWith(prefix)).toSet();
  }

  void _invalidateUnifiedAgendaCache() {
    _unifiedAgendaCacheDirty = true;
  }

  void _ensureUnifiedAgendaCache() {
    if (!_unifiedAgendaCacheDirty) return;

    final result = <UnifiedAgendaEntry>[];
    if (agendaContentFilter != AgendaContentFilter.sharedOnly) {
      result.addAll(items.map(UnifiedAgendaEntry.private));
    }
    if (agendaContentFilter != AgendaContentFilter.privateOnly) {
      for (final space in _sharedAgendaSpaces.values) {
        for (final entry
            in _sharedAgendaEntriesBySpace[space.id] ?? const <SharedEntry>[]) {
          if (entry.type != SharedEntryType.appointment &&
              entry.type != SharedEntryType.task) {
            continue;
          }
          result.add(UnifiedAgendaEntry.shared(entry, space));
        }
      }
    }

    result.sort((a, b) {
      final byDate = b.date.compareTo(a.date);
      if (byDate != 0) return byDate;
      return _compareUnifiedNewestFirst(a, b);
    });

    _unifiedAgendaCache
      ..clear()
      ..addAll(result);
    _pendingUnifiedTaskCountCache = result
        .where((entry) => entry.type == ItemType.task && !entry.done)
        .length;
    _unifiedMonthCountCache.clear();
    for (final entry in result) {
      final key = '${entry.date.year}-${entry.date.month}';
      _unifiedMonthCountCache[key] =
          (_unifiedMonthCountCache[key] ?? 0) + 1;
    }
    _unifiedAgendaCacheDirty = false;
  }

  void _notifyShellChanged() {
    shellRevision.value = shellRevision.value + 1;
  }

  Future<void> _applyEntityDeltas(LocalStateStore prefs) async {
    final prefix = _entityDeltaScopePrefix(_activeAccountId);
    final keys =
        prefs.getKeys().where((key) => key.startsWith(prefix)).toList()
          ..sort();

    for (final key in keys) {
      final raw = prefs.getString(key);
      if (raw == null) continue;

      try {
        final envelope =
            Map<String, dynamic>.from(jsonDecode(raw) as Map);
        final type = envelope['type']?.toString() ?? '';
        final id = envelope['id']?.toString() ?? '';
        final deleted = envelope['deleted'] == true;
        final payload = envelope['payload'];

        if (type.isEmpty || id.isEmpty) continue;

        switch (type) {
          case 'item':
            items.removeWhere((item) => item.id == id);
            if (!deleted && payload is Map) {
              items.add(
                AgendaItem.fromJson(
                  Map<String, dynamic>.from(payload),
                ),
              );
            }
            break;
          case 'journal':
            if (deleted) {
              journals.remove(id);
            } else if (payload is Map) {
              journals[id] = DayJournal.fromJson(
                Map<String, dynamic>.from(payload),
              );
            }
            break;
          case 'month':
            if (deleted) {
              months.remove(id);
            } else if (payload is Map) {
              months[id] = MonthlyData.fromJson(
                Map<String, dynamic>.from(payload),
              );
            }
            break;
          case 'week':
            if (deleted) {
              weeks.remove(id);
            } else if (payload is Map) {
              weeks[id] = WeekData.fromJson(
                Map<String, dynamic>.from(payload),
              );
            }
            break;
          case 'habit':
            habits.removeWhere((habit) => habit.id == id);
            if (!deleted && payload is Map) {
              habits.add(
                HabitDefinition.fromJson(
                  Map<String, dynamic>.from(payload),
                ),
              );
            }
            break;
          case 'inbox':
            inbox.removeWhere((entry) => entry.id == id);
            if (!deleted && payload is Map) {
              inbox.add(
                InboxEntry.fromJson(
                  Map<String, dynamic>.from(payload),
                ),
              );
            }
            break;
        }
      } catch (_) {
        // A single bad delta must not hide the aggregate baseline.
      }
    }
  }

  Future<void> _compactActiveEntityDeltas(
    LocalStateStore prefs,
  ) async {
    final deltaKeys = _activeEntityDeltaKeys(prefs);
    if (deltaKeys.isEmpty) return;

    final changes = <String, String?>{
      ..._currentWorkingStateChanges(),
      for (final key in deltaKeys) key: null,
    };
    await prefs.writeBatch(changes);
  }

  Future<void> _persistEntityMutations(
    List<
        ({
          String type,
          String id,
          Map<String, dynamic>? payload,
          bool deleted,
        })> mutations, {
    bool createAutoSnapshot = true,
  }) async {
    if (mutations.isEmpty) return;

    final prefs = await _localState();
    final changes = <String, String?>{};
    final now = DateTime.now();

    for (final mutation in mutations) {
      final storageKey = _storageKeyForEntityType(mutation.type);
      if (storageKey == null ||
          _unreadableStorageKeys.contains(storageKey)) {
        continue;
      }

      changes[_entityDeltaKey(mutation.type, mutation.id)] = jsonEncode({
        'type': mutation.type,
        'id': mutation.id,
        'deleted': mutation.deleted,
        'payload': mutation.deleted ? null : mutation.payload,
      });

      final localKey = '${mutation.type}:${mutation.id}';
      if (mutation.deleted) {
        _syncIndex.remove(localKey);
        _syncQueue[localKey] = CloudSyncOperation(
          entityType: mutation.type,
          entityId: mutation.id,
          payload: null,
          updatedAt: now,
          deleted: true,
          ownerId: _activeAccountId,
        );
        continue;
      }

      final localPayload = mutation.payload;
      if (localPayload == null) continue;

      // The sync index hashes the compact local representation.
      // Media is materialized to Base64 only at the outbound upload boundary,
      // avoiding repeated large allocations during normal local saves.
      _syncIndex[localKey] = _syncPayloadHash(localPayload);
      _syncQueue[localKey] = CloudSyncOperation(
        entityType: mutation.type,
        entityId: mutation.id,
        payload: localPayload,
        updatedAt: now,
        ownerId: _activeAccountId,
      );
    }

    if (changes.isEmpty) return;

    changes[_syncQueueKey] = jsonEncode(
      _syncQueue.map((key, value) => MapEntry(key, value.toJson())),
    );
    changes[_syncIndexKey] = jsonEncode(_syncIndex);
    await prefs.writeBatch(changes);

    if (createAutoSnapshot) {
      await _maybeCreateAutomaticSnapshot(prefs);
    }
    _scheduleCloudSync();
  }

  Future<void> _persistEntityMutation({
    required String type,
    required String id,
    Map<String, dynamic>? payload,
    bool deleted = false,
    bool createAutoSnapshot = true,
  }) =>
      _persistEntityMutations(
        [
          (
            type: type,
            id: id,
            payload: payload,
            deleted: deleted,
          ),
        ],
        createAutoSnapshot: createAutoSnapshot,
      );

  Map<String, dynamic>? _localEntityPayload(
    String type,
    String id,
  ) {
    switch (type) {
      case 'item':
        for (final item in items) {
          if (item.id == id) return item.toJson();
        }
        return null;
      case 'journal':
        return journals[id]?.toLocalJson();
      case 'month':
        return months[id]?.toJson();
      case 'week':
        return weeks[id]?.toJson();
      case 'habit':
        for (final habit in habits) {
          if (habit.id == id) return habit.toJson();
        }
        return null;
      case 'inbox':
        for (final entry in inbox) {
          if (entry.id == id) return entry.toJson();
        }
        return null;
      case 'preferences':
        return _cloudPreferencesPayload();
    }
    return null;
  }

  Future<void> _persistAppliedRemoteRecords(
    LocalStateStore prefs,
    Iterable<CloudRemoteRecord> records,
  ) async {
    final changes = <String, String?>{};
    var preferencesChanged = false;

    for (final record in records) {
      final localKey = record.localKey;
      _syncQueue.remove(localKey);

      if (record.entityType == 'preferences') {
        if (record.deletedAt == null) {
          preferencesChanged = true;
          _syncIndex[localKey] =
              _syncPayloadHash(_cloudPreferencesPayload());
        } else {
          _syncIndex.remove(localKey);
        }
        continue;
      }

      final storageKey = _storageKeyForEntityType(record.entityType);
      if (storageKey == null ||
          _unreadableStorageKeys.contains(storageKey)) {
        continue;
      }

      final payload = record.deletedAt == null
          ? _localEntityPayload(record.entityType, record.entityId)
          : null;
      changes[_entityDeltaKey(record.entityType, record.entityId)] =
          jsonEncode({
        'type': record.entityType,
        'id': record.entityId,
        'deleted': record.deletedAt != null,
        'payload': payload,
      });

      if (payload == null) {
        _syncIndex.remove(localKey);
      } else {
        _syncIndex[localKey] = _syncPayloadHash(payload);
      }
    }

    if (preferencesChanged) {
      changes[_preferencesKey] = jsonEncode(preferences.toJson());
    }
    changes[_syncQueueKey] = jsonEncode(
      _syncQueue.map((key, value) => MapEntry(key, value.toJson())),
    );
    changes[_syncIndexKey] = jsonEncode(_syncIndex);

    await prefs.writeBatch(changes);
  }

  Future<Uint8List> _createMediaThumbnail(
    Uint8List bytes, {
    int maxSide = 420,
    int quality = 46,
  }) async {
    try {
      final compressed = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: maxSide,
        minHeight: maxSide,
        quality: quality,
        format: CompressFormat.jpeg,
      );
      if (compressed.isNotEmpty) return compressed;
    } catch (_) {}
    return Uint8List.fromList(bytes);
  }

  Future<({List<DiarySketchPage> pages, bool changed})>
      _localizeSketchPages(
    List<DiarySketchPage> pages,
  ) async {
    var changed = false;
    final localizedPages = <DiarySketchPage>[];

    for (final page in pages) {
      final images = <DiarySketchImageElement>[];
      var pageChanged = false;

      for (final image in page.imageElements) {
        var next = image;
        if (image.imageBase64.isNotEmpty) {
          try {
            final bytes = base64Decode(image.imageBase64);
            final assetId = await MediaAssetStore.instance.put(bytes);
            next = image.copyWith(
              imageBase64: '',
              mediaAssetId: assetId,
            );
            pageChanged = true;
          } catch (_) {
            // Preserve legacy inline media when it cannot be decoded.
          }
        }
        images.add(next);
      }

      localizedPages.add(
        pageChanged ? page.copyWith(imageElements: images) : page,
      );
      changed = changed || pageChanged;
    }

    return (pages: localizedPages, changed: changed);
  }

  Future<List<Map<String, dynamic>>> _portableSketchPages(
    List<DiarySketchPage> pages,
  ) async {
    final result = <Map<String, dynamic>>[];

    for (final page in pages) {
      final pageJson = Map<String, dynamic>.from(page.toJson());
      final images = <Map<String, dynamic>>[];

      for (final image in page.imageElements) {
        final imageJson = Map<String, dynamic>.from(image.toJson());
        if ((imageJson['imageBase64']?.toString().isEmpty ?? true) &&
            image.mediaAssetId.isNotEmpty) {
          final bytes =
              await MediaAssetStore.instance.read(image.mediaAssetId);
          if (bytes != null) {
            imageJson['imageBase64'] = base64Encode(bytes);
          }
        }
        imageJson.remove('mediaAssetId');
        images.add(imageJson);
      }

      pageJson['imageElements'] = images;
      result.add(pageJson);
    }

    return result;
  }

  Future<bool> _migrateInlinePrivateMedia(
    LocalStateStore prefs, {
    bool persist = true,
  }) async {
    if (_unreadableStorageKeys.contains(_journalsKey)) return false;

    var changed = false;
    for (final entry in journals.entries.toList()) {
      final journal = entry.value;
      final blocks = <DiaryBlock>[];
      var journalChanged = false;

      for (final block in journal.blocks) {
        var next = block;
        var blockChanged = false;

        if (block.type == DiaryBlockType.photo) {
          var fullId = block.mediaAssetId;
          var thumbnailId = block.mediaThumbnailAssetId;

          if (block.imageBase64.isNotEmpty) {
            try {
              final bytes = base64Decode(block.imageBase64);
              fullId = await MediaAssetStore.instance.put(bytes);

              final existingThumbnail = thumbnailId.isEmpty
                  ? null
                  : await MediaAssetStore.instance.read(thumbnailId);
              if (existingThumbnail == null) {
                thumbnailId = await MediaAssetStore.instance.put(
                  await _createMediaThumbnail(bytes),
                );
              }

              next = next.copyWith(
                imageBase64: '',
                mediaAssetId: fullId,
                mediaThumbnailAssetId: thumbnailId,
              );
              blockChanged = true;
            } catch (_) {
              // Preserve unreadable legacy Base64 instead of destroying it.
            }
          } else if (fullId.isNotEmpty) {
            final bytes = await MediaAssetStore.instance.read(fullId);
            if (bytes != null) {
              final existingThumbnail = thumbnailId.isEmpty
                  ? null
                  : await MediaAssetStore.instance.read(thumbnailId);
              if (existingThumbnail == null) {
                thumbnailId = await MediaAssetStore.instance.put(
                  await _createMediaThumbnail(bytes),
                );
                next = next.copyWith(
                  mediaThumbnailAssetId: thumbnailId,
                );
                blockChanged = true;
              }
            }
          }
        }

        if (next.pages.isNotEmpty) {
          final localized = await _localizeSketchPages(next.pages);
          if (localized.changed) {
            next = next.copyWith(pages: localized.pages);
            blockChanged = true;
          }
        }

        blocks.add(next);
        journalChanged = journalChanged || blockChanged;
      }

      if (journalChanged) {
        journals[entry.key] = journal.copyWith(blocks: blocks);
        changed = true;
      }
    }

    if (changed && persist) {
      await prefs.setString(
        _journalsKey,
        jsonEncode(
          journals.map(
            (key, value) => MapEntry(key, value.toLocalJson()),
          ),
        ),
      );
    }
    return changed;
  }

  Future<Map<String, dynamic>> _portableJournalJson(
    DayJournal journal,
  ) async {
    final payload = Map<String, dynamic>.from(journal.toJson());
    final blocks = <Map<String, dynamic>>[];

    for (final block in journal.blocks) {
      final blockJson = Map<String, dynamic>.from(block.toJson());

      if (block.type == DiaryBlockType.photo) {
        if ((blockJson['imageBase64']?.toString().isEmpty ?? true) &&
            block.mediaAssetId.isNotEmpty) {
          final bytes =
              await MediaAssetStore.instance.read(block.mediaAssetId);
          if (bytes != null) {
            blockJson['imageBase64'] = base64Encode(bytes);
          }
        }
        blockJson.remove('mediaAssetId');
        blockJson.remove('mediaThumbnailAssetId');
      }

      if (block.pages.isNotEmpty) {
        blockJson['pages'] = await _portableSketchPages(block.pages);
      }
      blocks.add(blockJson);
    }

    payload['blocks'] = blocks;
    return payload;
  }

  Future<SharedEntry> _localizeSharedThumbnail(
    SharedEntry entry,
  ) async {
    var next = entry;

    if (next.type == SharedEntryType.photo &&
        next.mediaThumbnailAssetId.isEmpty &&
        next.mediaThumbnailBase64.isNotEmpty) {
      final assetId = await MediaAssetStore.instance
          .importBase64(next.mediaThumbnailBase64);
      if (assetId != null) {
        next = next.copyWith(mediaThumbnailAssetId: assetId);
      }
    }

    if (next.sketchPages.isNotEmpty) {
      final localized = await _localizeSketchPages(next.sketchPages);
      if (localized.changed) {
        next = next.copyWith(sketchPages: localized.pages);
      }
    }

    return next;
  }

  Map<String, dynamic> _sharedLocalQueuePayload(
    SharedEntry entry,
  ) {
    final payload = Map<String, dynamic>.from(entry.toJson());
    if (entry.type == SharedEntryType.photo &&
        entry.mediaThumbnailAssetId.isNotEmpty) {
      payload['mediaThumbnailBase64'] = '';
      payload['_mediaThumbnailAssetId'] = entry.mediaThumbnailAssetId;
    }
    if (entry.sketchPages.isNotEmpty) {
      payload['sketchPages'] =
          entry.sketchPages.map((page) => page.toLocalJson()).toList();
    }
    return payload;
  }

  Future<Map<String, dynamic>> _materializeSharedQueuePayload(
    Map<String, dynamic> source,
  ) async {
    final payload = Map<String, dynamic>.from(source);
    final localAssetId =
        payload.remove('_mediaThumbnailAssetId')?.toString() ?? '';
    if ((payload['mediaThumbnailBase64']?.toString().isEmpty ?? true) &&
        localAssetId.isNotEmpty) {
      final bytes = await MediaAssetStore.instance.read(localAssetId);
      if (bytes != null) {
        payload['mediaThumbnailBase64'] = base64Encode(bytes);
      }
    }

    final rawPages = payload['sketchPages'];
    if (rawPages is List) {
      final pages = rawPages
          .whereType<Map>()
          .map(
            (value) => DiarySketchPage.fromJson(
              Map<String, dynamic>.from(value),
            ),
          )
          .toList();
      payload['sketchPages'] = await _portableSketchPages(pages);
    }

    return payload;
  }

  void _collectAssetIdsFromJson(dynamic value, Set<String> result) {
    if (value is Map) {
      for (final entry in value.entries) {
        final key = entry.key.toString().toLowerCase();
        final child = entry.value;
        if (key.contains('assetid') &&
            child is String &&
            child.trim().isNotEmpty) {
          result.add(child);
        }
        _collectAssetIdsFromJson(child, result);
      }
      return;
    }
    if (value is List) {
      for (final child in value) {
        _collectAssetIdsFromJson(child, result);
      }
    }
  }

  Future<void> _pruneUnreferencedMedia(LocalStateStore prefs) async {
    final referenced = <String>{};

    for (final journal in journals.values) {
      for (final block in journal.blocks) {
        if (block.mediaAssetId.isNotEmpty) referenced.add(block.mediaAssetId);
        if (block.mediaThumbnailAssetId.isNotEmpty) {
          referenced.add(block.mediaThumbnailAssetId);
        }
        for (final page in block.pages) {
          for (final image in page.imageElements) {
            if (image.mediaAssetId.isNotEmpty) {
              referenced.add(image.mediaAssetId);
            }
          }
        }
      }
    }

    for (final key in prefs.getKeys()) {
      final raw = prefs.getString(key);
      if (raw == null || !raw.contains('AssetId')) continue;
      try {
        _collectAssetIdsFromJson(jsonDecode(raw), referenced);
      } catch (_) {}
    }

    await MediaAssetStore.instance.prune(referenced);
  }

  void _scheduleMediaMaintenance({
    Duration delay = const Duration(seconds: 3),
  }) {
    _mediaMaintenanceTimer?.cancel();
    _mediaMaintenanceTimer = Timer(
      delay,
      () => unawaited(_runMediaMaintenance()),
    );
  }

  Future<void> _runMediaMaintenance() async {
    try {
      final prefs = await _localState();
      await _pruneUnreferencedMedia(prefs);
    } catch (_) {
      // Media maintenance is best-effort and must never block app startup.
    }
  }

  Future<void> load() async {
    final prefs = await _localState();
    _activeAccountId = prefs.getString(_activeAccountKey);
    _accountScopeResolved = _activeAccountId == null;
    _unreadableStorageKeys
      ..clear()
      ..addAll(prefs.corruptKeys);

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
    _pendingSharedInteractionCount = 0;
    _pendingSharedMediaCount = 0;
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

    await _applyEntityDeltas(prefs);
    await _migrateInlinePrivateMedia(prefs);
    _invalidateDayIndex();
    await _loadSharedUnreadCounts(prefs);
    await refreshSharedAgendaCache(notify: false);
    await refreshPendingSharedCount(notify: false);
    await refreshPendingSharedInteractionCount(notify: false);
    await _migrateSharedMediaQueues(prefs);
    await refreshPendingSharedMediaCount(notify: false);
    _scheduleMediaMaintenance();
  }

  Future<void> _migrateSharedMediaQueues(
    LocalStateStore prefs,
  ) async {
    final ownerId = _activeAccountId;
    if (ownerId == null) return;
    final prefix = 'shared_media_pending_${ownerId}_';
    final keys =
        prefs.getKeys().where((key) => key.startsWith(prefix)).toList();
    for (final key in keys) {
      final spaceId = key.substring(prefix.length);
      if (spaceId.isEmpty) continue;
      await loadSharedMediaPendingUploads(spaceId);
    }
  }

  Map<String, dynamic> _readAccountProfiles(LocalStateStore prefs) {
    final raw = prefs.getString(_accountProfilesKey);
    if (raw == null) return <String, dynamic>{};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  Map<String, dynamic> _captureWorkingProfile(
    LocalStateStore prefs,
  ) {
    final result = <String, dynamic>{};
    for (final key in _workingStorageKeys) {
      final raw = prefs.getString(key);
      if (raw != null) result[key] = raw;
    }
    return result;
  }

  Map<String, String?> _workingProfileChanges(
    Map<String, dynamic> profile,
  ) {
    return {
      for (final key in _workingStorageKeys)
        key: profile[key] is String ? profile[key] as String : null,
    };
  }

  Map<String, String?> _currentWorkingStateChanges() => {
        _itemsKey: jsonEncode(items.map((e) => e.toJson()).toList()),
        _journalsKey: jsonEncode(
          journals.map((k, v) => MapEntry(k, v.toLocalJson())),
        ),
        _monthsKey:
            jsonEncode(months.map((k, v) => MapEntry(k, v.toJson()))),
        _weeksKey:
            jsonEncode(weeks.map((k, v) => MapEntry(k, v.toJson()))),
        _habitsKey: jsonEncode(habits.map((e) => e.toJson()).toList()),
        _preferencesKey: jsonEncode(preferences.toJson()),
        _inboxKey: jsonEncode(inbox.map((e) => e.toJson()).toList()),
        _privacyGuardKey: jsonEncode(_privacyGuardPayload()),
      };

  bool _workingProfileHasUserData(LocalStateStore prefs) {
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
    final prefs = await _localState();
    if (_activeAccountId == accountId) {
      if (accountId != null) {
        _bindPendingOperationsTo(accountId);
        await _persistSyncMetadata(prefs);
      }
      if (!_accountScopeResolved) {
        _accountScopeResolved = true;
        _notifyShellChanged();
        notifyListeners();
      }
      return;
    }

    await _compactActiveEntityDeltas(prefs);

    final profiles = _readAccountProfiles(prefs);
    final currentScope =
        _activeAccountId == null ? 'guest' : 'user:$_activeAccountId';
    final currentProfile = _captureWorkingProfile(prefs);
    profiles[currentScope] = currentProfile;

    final targetScope =
        accountId == null ? 'guest' : 'user:$accountId';
    var claimedLegacyGuest = false;

    if (accountId != null &&
        profiles[targetScope] == null &&
        prefs.getString(_legacyClaimedByKey) == null &&
        _activeAccountId == null &&
        _workingProfileHasUserData(prefs)) {
      profiles[targetScope] = currentProfile;
      profiles['guest'] = <String, dynamic>{};
      claimedLegacyGuest = true;
    }

    final rawTarget = profiles[targetScope];
    final target = rawTarget is Map
        ? Map<String, dynamic>.from(rawTarget)
        : <String, dynamic>{};

    final changes = <String, String?>{
      _accountProfilesKey: jsonEncode(profiles),
      ..._workingProfileChanges(target),
      _activeAccountKey: accountId,
      if (claimedLegacyGuest) _legacyClaimedByKey: accountId,
    };

    // Archive the previous profile, activate the target profile and move the
    // active-account pointer in one Sembast transaction. A crash cannot leave
    // a partially switched working set.
    await prefs.writeBatch(changes);

    await load();

    if (accountId != null) {
      _activeAccountId = accountId;
      _bindPendingOperationsTo(accountId);
      await _persistSyncMetadata(prefs);
    }

    _accountScopeResolved = true;
    _notifyShellChanged();
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
    final prefs = await _localState();
    final changes = <String, String?>{};

    bool shouldWrite(String key) {
      return (onlyKeys == null || onlyKeys.contains(key)) &&
          !_unreadableStorageKeys.contains(key);
    }

    if (shouldWrite(_itemsKey)) {
      changes[_itemsKey] =
          jsonEncode(items.map((e) => e.toJson()).toList());
    }
    if (shouldWrite(_journalsKey)) {
      await _migrateInlinePrivateMedia(
        prefs,
        persist: false,
      );
      changes[_journalsKey] = jsonEncode(
        journals.map((k, v) => MapEntry(k, v.toLocalJson())),
      );
    }
    if (shouldWrite(_monthsKey)) {
      changes[_monthsKey] =
          jsonEncode(months.map((k, v) => MapEntry(k, v.toJson())));
    }
    if (shouldWrite(_weeksKey)) {
      changes[_weeksKey] =
          jsonEncode(weeks.map((k, v) => MapEntry(k, v.toJson())));
    }
    if (shouldWrite(_habitsKey)) {
      changes[_habitsKey] =
          jsonEncode(habits.map((e) => e.toJson()).toList());
    }
    if (shouldWrite(_preferencesKey)) {
      changes[_preferencesKey] = jsonEncode(preferences.toJson());
    }
    if (shouldWrite(_inboxKey)) {
      changes[_inboxKey] =
          jsonEncode(inbox.map((e) => e.toJson()).toList());
    }

    // Full-section writes compact any accumulated entity deltas for the same
    // sections in the very same Sembast transaction.
    for (final key in _activeEntityDeltaKeys(prefs)) {
      final raw = prefs.getString(key);
      if (raw == null) continue;
      try {
        final envelope =
            Map<String, dynamic>.from(jsonDecode(raw) as Map);
        final type = envelope['type']?.toString() ?? '';
        final storageKey = _storageKeyForEntityType(type);
        if (storageKey != null && shouldWrite(storageKey)) {
          changes[key] = null;
        }
      } catch (_) {
        // Preserve unreadable deltas for diagnostics/recovery.
      }
    }

    if (changes.isNotEmpty) {
      await prefs.writeBatch(changes);
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
    final prefs = await _localState();
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

  Future<Map<String, _LocalSyncEntity>> _currentSyncEntities({
    Set<String>? onlyKeys,
  }) async {
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
        add(
          'journal',
          entry.key,
          entry.value.toLocalJson(),
        );
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
    LocalStateStore prefs, {
    bool forceAll = false,
    Set<String>? onlyKeys,
  }) async {
    final entities = await _currentSyncEntities(onlyKeys: onlyKeys);
    final now = DateTime.now();

    for (final entry in entities.entries) {
      final hash = _syncPayloadHash(entry.value.payload);
      if (forceAll || _syncIndex[entry.key] != hash) {
        final queuedPayload = entry.value.entityType == 'journal'
            ? (journals[entry.value.entityId]?.toLocalJson() ??
                entry.value.payload)
            : entry.value.payload;
        _syncQueue[entry.key] = CloudSyncOperation(
          entityType: entry.value.entityType,
          entityId: entry.value.entityId,
          payload: queuedPayload,
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

  Future<void> _persistSyncMetadata(
    LocalStateStore prefs, {
    Map<String, String?> extraChanges = const {},
  }) async {
    await prefs.writeBatch({
      _syncQueueKey: jsonEncode(
        _syncQueue.map((key, value) => MapEntry(key, value.toJson())),
      ),
      _syncIndexKey: jsonEncode(_syncIndex),
      ...extraChanges,
    });
  }

  Map<String, dynamic> _localDataPayload() => {
        'items': items.map((e) => e.toJson()).toList(),
        'journals':
            journals.map((k, v) => MapEntry(k, v.toLocalJson())),
        'months': months.map((k, v) => MapEntry(k, v.toJson())),
        'weeks': weeks.map((k, v) => MapEntry(k, v.toJson())),
        'habits': habits.map((e) => e.toJson()).toList(),
        'inbox': inbox.map((e) => e.toJson()).toList(),
        'preferences': preferences.toJson(),
      };

  Future<Map<String, dynamic>> _portableBackupDataPayload() async {
    final portableJournals = <String, dynamic>{};
    for (final entry in journals.entries) {
      portableJournals[entry.key] = await _portableJournalJson(entry.value);
    }
    return {
      'items': items.map((e) => e.toJson()).toList(),
      'journals': portableJournals,
      'months': months.map((k, v) => MapEntry(k, v.toJson())),
      'weeks': weeks.map((k, v) => MapEntry(k, v.toJson())),
      'habits': habits.map((e) => e.toJson()).toList(),
      'inbox': inbox.map((e) => e.toJson()).toList(),
      'preferences': preferences.toJson(),
    };
  }

  Future<String> createBackupJson() async {
    final document = {
      'format': _backupFormat,
      'schemaVersion': _backupSchemaVersion,
      'appVersion': _appVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'data': await _portableBackupDataPayload(),
    };
    return const JsonEncoder.withIndent('  ').convert(document);
  }

  Future<Uint8List> createBackupZip() async {
    final exportedAt = DateTime.now();
    final localData = _localDataPayload();
    final referencedAssetIds = <String>{};
    _collectAssetIdsFromJson(localData, referencedAssetIds);

    final media = <String, Uint8List>{};
    final manifestMedia = <Map<String, dynamic>>[];

    final sortedIds = referencedAssetIds.toList()..sort();
    for (final assetId in sortedIds) {
      final bytes = await MediaAssetStore.instance.read(assetId);
      if (bytes == null || bytes.isEmpty) {
        throw FormatException(
          'Media locale mancante nel backup: $assetId',
        );
      }
      media[assetId] = bytes;
      manifestMedia.add({
        'assetId': assetId,
        'path': 'media/$assetId.bin',
        'size': bytes.lengthInBytes,
        'sha256': sha256.convert(bytes).toString(),
      });
    }

    final dataDocument = {
      'format': _backupFormat,
      'schemaVersion': _backupSchemaVersion,
      'appVersion': _appVersion,
      'exportedAt': exportedAt.toIso8601String(),
      'data': localData,
    };
    final dataJson =
        const JsonEncoder.withIndent('  ').convert(dataDocument);

    final manifest = {
      'format': _backupBundleFormat,
      'bundleVersion': _backupBundleVersion,
      'appVersion': _appVersion,
      'exportedAt': exportedAt.toIso8601String(),
      'dataFile': 'data.json',
      'mediaCount': manifestMedia.length,
      'media': manifestMedia,
      'dataSha256': sha256.convert(utf8.encode(dataJson)).toString(),
    };

    return BackupFileService.instance.buildZipBackup(
      manifestJson: const JsonEncoder.withIndent('  ').convert(manifest),
      dataJson: dataJson,
      media: media,
    );
  }

  DecodedZipBackup _decodeAndValidateBackupZip(Uint8List bytes) {
    final decoded = BackupFileService.instance.decodeZipBackup(bytes);

    final manifestValue = jsonDecode(decoded.manifestJson);
    if (manifestValue is! Map) {
      throw const FormatException('Manifest backup non valido.');
    }
    final manifest = Map<String, dynamic>.from(manifestValue);
    if (manifest['format'] != _backupBundleFormat ||
        manifest['bundleVersion'] != _backupBundleVersion) {
      throw const FormatException('Formato ZIP del backup non supportato.');
    }

    final expectedDataHash = manifest['dataSha256']?.toString() ?? '';
    final actualDataHash =
        sha256.convert(utf8.encode(decoded.dataJson)).toString();
    if (expectedDataHash.isEmpty || expectedDataHash != actualDataHash) {
      throw const FormatException('Il file dati del backup non è integro.');
    }

    final rawMedia = manifest['media'];
    if (rawMedia is! List) {
      throw const FormatException('Indice media del backup non valido.');
    }

    final declaredIds = <String>{};
    for (final raw in rawMedia) {
      if (raw is! Map) {
        throw const FormatException('Indice media del backup non valido.');
      }
      final entry = Map<String, dynamic>.from(raw);
      final assetId = entry['assetId']?.toString() ?? '';
      final expectedSize = entry['size'];
      final expectedHash = entry['sha256']?.toString() ?? '';
      if (assetId.isEmpty ||
          expectedSize is! int ||
          expectedHash.isEmpty ||
          !declaredIds.add(assetId)) {
        throw const FormatException('Indice media del backup non valido.');
      }

      final mediaBytes = decoded.media[assetId];
      if (mediaBytes == null ||
          mediaBytes.lengthInBytes != expectedSize ||
          sha256.convert(mediaBytes).toString() != expectedHash) {
        throw FormatException(
          'Media del backup danneggiato o mancante: $assetId',
        );
      }
    }

    if (decoded.media.keys.any((assetId) => !declaredIds.contains(assetId))) {
      throw const FormatException('Il backup contiene media non dichiarati.');
    }

    inspectBackup(decoded.dataJson);
    return decoded;
  }

  BackupSummary inspectBackupZip(Uint8List bytes) =>
      inspectBackup(_decodeAndValidateBackupZip(bytes).dataJson);

  Future<void> restoreBackupZip(
    Uint8List bytes, {
    required bool merge,
  }) async {
    final decoded = _decodeAndValidateBackupZip(bytes);

    for (final entry in decoded.media.entries) {
      await MediaAssetStore.instance.putNamed(
        entry.key,
        entry.value,
      );
    }

    await restoreBackup(
      decoded.dataJson,
      merge: merge,
    );
  }

  BackupSummary inspectBackup(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Il file non contiene un backup valido.');
    }

    final root = Map<String, dynamic>.from(decoded);
    if (root['format'] != _backupFormat) {
      throw const FormatException('Questo file non appartiene ad Anna\'s Diary.');
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

    // Parse first and keep a safety snapshot before touching the working set.
    await createLocalSnapshot(label: 'Prima del ripristino');
    final prefs = await _localState();

    final previousItems = List<AgendaItem>.from(items);
    final previousJournals = Map<String, DayJournal>.from(journals);
    final previousMonths = Map<String, MonthlyData>.from(months);
    final previousWeeks = Map<String, WeekData>.from(weeks);
    final previousHabits = List<HabitDefinition>.from(habits);
    final previousInbox = List<InboxEntry>.from(inbox);
    final previousPreferences = preferences;

    try {
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

      if (habits.isEmpty && !backupContainsHabits) {
        habits.addAll(const [
          HabitDefinition(id: 'water', name: 'Bere abbastanza'),
          HabitDefinition(id: 'move', name: 'Muovermi un po’'),
          HabitDefinition(id: 'me', name: 'Tempo per me'),
        ]);
      }

      _invalidateDayIndex();

      // Convert portable inline media in memory first. The actual structured
      // state is committed only once all sections are ready.
      await _migrateInlinePrivateMedia(
        prefs,
        persist: false,
      );

      final changes = <String, String?>{
        ..._currentWorkingStateChanges(),
        _forceFullSyncKey: 'true',
        for (final key in _activeEntityDeltaKeys(prefs)) key: null,
      };
      await prefs.writeBatch(changes);
      _unreadableStorageKeys.removeAll(changes.keys);
    } catch (_) {
      items
        ..clear()
        ..addAll(previousItems);
      journals
        ..clear()
        ..addAll(previousJournals);
      months
        ..clear()
        ..addAll(previousMonths);
      weeks
        ..clear()
        ..addAll(previousWeeks);
      habits
        ..clear()
        ..addAll(previousHabits);
      inbox
        ..clear()
        ..addAll(previousInbox);
      preferences = previousPreferences;
      _invalidateDayIndex();
      rethrow;
    }

    // Reminder changes happen only after the data transaction has committed.
    for (final item in previousItems) {
      await NotificationService.instance.cancel(item.id);
      await NotificationService.instance.cancel('${item.id}:primary');
      await NotificationService.instance.cancel('${item.id}:secondary');
    }
    for (final item in items) {
      await _syncReminders(item);
    }

    // Force a complete queue rebuild after restore. The marker stays on disk
    // until this succeeds, so a crash will retry on the next cloud sync.
    try {
      await _captureSyncChanges(
        prefs,
        forceAll: true,
      );
      await prefs.remove(_forceFullSyncKey);
      _scheduleCloudSync();
    } catch (_) {
      // Local restore is already safely committed. Cloud recovery will retry
      // from the durable marker on the next sync/resume.
    }

    _notifyShellChanged();
    notifyListeners();
  }

  Future<void> createLocalSnapshot({
    String label = 'Backup manuale',
  }) async {
    final prefs = await _localState();
    localSnapshots.insert(
      0,
      LocalBackupSnapshot(
        id: const Uuid().v4(),
        createdAt: DateTime.now(),
        label: label,
        data: jsonDecode(jsonEncode(_localDataPayload()))
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
    LocalStateStore prefs,
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
        data: jsonDecode(jsonEncode(_localDataPayload()))
            as Map<String, dynamic>,
      ),
    );
    if (localSnapshots.length > 5) {
      localSnapshots.removeRange(5, localSnapshots.length);
    }
    await _saveSnapshots(prefs);
  }

  Future<void> _saveSnapshots(LocalStateStore prefs) async {
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
    final prefs = await _localState();
    await _saveSnapshots(prefs);
    notifyListeners();
  }

  String createReadableExport() {
    final buffer = StringBuffer();
    final now = DateTime.now();

    buffer.writeln('ANNA\'S DIARY');
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
    _invalidateUnifiedAgendaCache();
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
    await _persistEntityMutation(
      type: 'item',
      id: item.id,
      payload: item.toJson(),
    );
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
    await _persistEntityMutation(
      type: 'item',
      id: id,
      deleted: true,
    );
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
    await _persistEntityMutation(
      type: 'item',
      id: items[i].id,
      payload: items[i].toJson(),
    );
    await _syncReminders(items[i]);
    notifyListeners();
  }

  DayJournal journal(DateTime date) => journals[dateKey(date)] ?? const DayJournal();

  Future<void> saveJournal(DateTime date, DayJournal journal) async {
    final key = dateKey(date);
    journals[key] = journal;
    await _persistEntityMutation(
      type: 'journal',
      id: key,
      payload: journal.toLocalJson(),
    );
    _scheduleMediaMaintenance(
      delay: const Duration(seconds: 5),
    );
    notifyListeners();
  }

  Future<void> initializeCloudSync() async {
    _cloudSyncTimer?.cancel();

    final cloud = CloudSyncService.instance;
    if (cloud.initialized) {
      await activateCloudAccount(cloud.signedIn ? cloud.userId : null);
    } else {
      _accountScopeResolved = true;
      _notifyShellChanged();
      notifyListeners();
    }

    if (cloud.signedIn) {
      await syncCloud(preferRemoteOnFirstSync: true);
      _scheduleDeferredSharedCloudSync();
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
    await NotificationService.instance.initialize();
    await reconcileReminders();

    final cloud = CloudSyncService.instance;
    if (!cloud.initialized) {
      await cloud.initialize();
    }

    if (cloud.initialized) {
      await activateCloudAccount(cloud.signedIn ? cloud.userId : null);
    } else if (!_accountScopeResolved) {
      _accountScopeResolved = true;
      _notifyShellChanged();
      notifyListeners();
    }

    if (cloud.signedIn) {
      await syncAllCloud();
      await PushNotificationService.instance.registerCurrentToken();
    }
  }

  void _scheduleDeferredSharedCloudSync() {
    _deferredCloudSyncTimer?.cancel();
    _deferredCloudSyncTimer = Timer(
      const Duration(milliseconds: 900),
      () => unawaited(_syncSharedCloudWork()),
    );
  }

  Future<void> _syncSharedCloudWork() async {
    final cloud = CloudSyncService.instance;
    if (!cloud.configured || !cloud.initialized || !cloud.signedIn) {
      return;
    }
    if (_activeAccountId != cloud.userId) return;

    await flushSharedMediaUploads();
    await flushSharedInteractionOperations();
    await flushSharedPendingOperations();

    if (!cloud.signedIn ||
        cloud.userId == null ||
        _activeAccountId != cloud.userId) {
      return;
    }

    await refreshSharedAgendaCache(pullRemote: true);
    await refreshPendingSharedCount();
    await refreshPendingSharedInteractionCount();
    await refreshPendingSharedMediaCount();
  }

  Future<void> syncAllCloud({
    bool preferRemoteOnFirstSync = false,
  }) async {
    final cloud = CloudSyncService.instance;
    if (!cloud.configured || !cloud.initialized || !cloud.signedIn) {
      return;
    }

    await syncCloud(
      preferRemoteOnFirstSync: preferRemoteOnFirstSync,
    );
    await _syncSharedCloudWork();
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
      final prefs = await _localState();
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

      final forceFullSync =
          prefs.getBool(_forceFullSyncKey) == true;
      if (forceFullSync || (firstSyncForOwner && _syncIndex.isEmpty)) {
        await _captureSyncChanges(
          prefs,
          forceAll: true,
        );
        _bindPendingOperationsTo(ownerId);
      }

      final cursorKey = _privateSyncCursorKey(ownerId);
      final storedCursor = _readSyncCursor(prefs, cursorKey);
      final requiresFullPull =
          forceFullSync || firstSyncForOwner || storedCursor == null;

      final remote = await cloud.pullPrivateRecords(
        updatedSince: requiresFullPull ? null : storedCursor,
      );

      if (cloud.sessionEpoch != sessionEpoch ||
          cloud.userId != ownerId ||
          _activeAccountId != ownerId) {
        return;
      }

      var remoteChanged = false;
      final appliedRemote = <CloudRemoteRecord>[];
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
        appliedRemote.add(record);
      }

      if (remoteChanged) {
        await _migrateInlinePrivateMedia(
          prefs,
          persist: false,
        );
      }
      if (appliedRemote.isNotEmpty) {
        await _persistAppliedRemoteRecords(prefs, appliedRemote);
      }

      final nextPrivateCursor = _nextSyncCursor(
        requiresFullPull ? null : storedCursor,
        remote.map((record) => record.clientUpdatedAt),
      );

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

      final portablePending = <CloudSyncOperation>[];
      for (final operation in pendingSnapshot.values) {
        if (operation.entityType == 'journal' &&
            !operation.deleted &&
            operation.payload != null) {
          final journal = journals[operation.entityId] ??
              DayJournal.fromJson(operation.payload!);
          portablePending.add(
            CloudSyncOperation(
              entityType: operation.entityType,
              entityId: operation.entityId,
              payload: await _portableJournalJson(journal),
              updatedAt: operation.updatedAt,
              deleted: operation.deleted,
              ownerId: operation.ownerId,
            ),
          );
        } else {
          portablePending.add(operation);
        }
      }

      await cloud.pushPrivateOperations(portablePending);

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

      await _persistSyncMetadata(
        prefs,
        extraChanges: {
          _syncOwnerKey: ownerId,
          cursorKey: nextPrivateCursor.toIso8601String(),
          if (forceFullSync) _forceFullSyncKey: null,
        },
      );

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
        _notifyShellChanged();
        return true;
    }
    return false;
  }

  void setAgendaContentFilter(AgendaContentFilter value) {
    if (agendaContentFilter == value) return;
    agendaContentFilter = value;
    _invalidateUnifiedAgendaCache();
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

    result.sort(_compareUnifiedNewestFirst);
    return List<UnifiedAgendaEntry>.unmodifiable(result);
  }

  int _compareUnifiedNewestFirst(
    UnifiedAgendaEntry a,
    UnifiedAgendaEntry b,
  ) {
    final aHasTime = a.start != null;
    final bHasTime = b.start != null;
    if (aHasTime && bHasTime) {
      final time = b.sortMinutes.compareTo(a.sortMinutes);
      if (time != 0) return time;
    } else if (aHasTime != bHasTime) {
      return aHasTime ? -1 : 1;
    }

    final date = b.date.compareTo(a.date);
    if (date != 0) return date;
    return b.id.compareTo(a.id);
  }

  void _rebuildSharedAgendaDayIndex() {
    _sharedAgendaDayIndex.clear();
    _invalidateUnifiedAgendaCache();
    for (final space in _sharedAgendaSpaces.values) {
      for (final entry
          in _sharedAgendaEntriesBySpace[space.id] ?? const <SharedEntry>[]) {
        if (entry.type != SharedEntryType.appointment &&
            entry.type != SharedEntryType.task) {
          continue;
        }
        final unified = UnifiedAgendaEntry.shared(entry, space);
        (_sharedAgendaDayIndex[dateKey(entry.date)] ??=
                <UnifiedAgendaEntry>[])
            .add(unified);
      }
    }
    for (final dayEntries in _sharedAgendaDayIndex.values) {
      dayEntries.sort(_compareUnifiedNewestFirst);
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

  int unifiedMonthCount(int year, int month) {
    _ensureUnifiedAgendaCache();
    return _unifiedMonthCountCache['$year-$month'] ?? 0;
  }

  Future<void> refreshSharedAgendaCache({
    bool pullRemote = false,
    bool notify = true,
    String? targetSpaceId,
  }) async {
    final ownerId = _activeAccountId;
    if (ownerId == null) {
      _sharedAgendaSpaces.clear();
      _sharedAgendaEntriesBySpace.clear();
      _sharedAgendaDayIndex.clear();
      _invalidateUnifiedAgendaCache();
      if (notify) notifyListeners();
      return;
    }

    final prefs = await _localState();
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
      var entries = List<SharedEntry>.from(
        _sharedAgendaEntriesBySpace[space.id] ?? const <SharedEntry>[],
      );
      var hasBaseline = _sharedAgendaEntriesBySpace.containsKey(space.id);

      if (!hasBaseline) {
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
            hasBaseline = true;
          } catch (_) {
            entries = <SharedEntry>[];
          }
        }
      }

      final shouldPullSpace = pullRemote &&
          cloud.signedIn &&
          cloud.userId == ownerId &&
          (targetSpaceId == null || targetSpaceId == space.id);
      String? cursorKeyToPersist;
      DateTime? nextCursorToPersist;

      if (shouldPullSpace) {
        try {
          final cursorKey = _sharedSyncCursorKey(space.id);
          final storedCursor =
              hasBaseline ? _readSyncCursor(prefs, cursorKey) : null;
          final records = await cloud.pullSharedRecords(
            space.id,
            updatedSince: storedCursor,
          );

          if (storedCursor == null) {
            entries.clear();
          }

          for (final record in records) {
            if (record.entityType != 'shared_entry') continue;
            entries.removeWhere(
              (entry) => entry.id == record.entityId,
            );
            if (record.deletedAt == null && record.payload != null) {
              entries.add(
                SharedEntry.fromJson(
                  record.payload!,
                  updatedBy: record.updatedBy,
                  updatedAt: record.clientUpdatedAt,
                ),
              );
            }
          }

          cursorKeyToPersist = cursorKey;
          nextCursorToPersist = _nextSyncCursor(
            storedCursor,
            records.map((record) => record.clientUpdatedAt),
          );
        } catch (_) {
          // Keep the current in-memory/disk baseline and pending overlay.
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
              mediaThumbnailAssetId:
                  operation.payload!['_mediaThumbnailAssetId']
                          ?.toString() ??
                      '',
            ),
          );
        }
      }

      final localizedEntries = <SharedEntry>[];
      for (final entry in entries) {
        localizedEntries.add(await _localizeSharedThumbnail(entry));
      }
      entries = localizedEntries;

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
      await prefs.writeBatch({
        sharedCacheStorageKey(space.id):
            jsonEncode(entries.map((entry) => entry.toCacheJson()).toList()),
        if (cursorKeyToPersist != null && nextCursorToPersist != null)
          cursorKeyToPersist!: nextCursorToPersist!.toIso8601String(),
      });
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
          if (updatedBy != null &&
              updatedBy != cloud.userId &&
              !PushNotificationService.instance.remotePushActive) {
            // FCM is the primary unread source when a registered remote token
            // is active. Realtime remains the fallback when push is unavailable,
            // avoiding duplicate unread increments and duplicate notifications.
            unawaited(markSharedSpaceUnread(space.id));
            unawaited(
              NotificationService.instance.showSharedUpdate(
                spaceId: space.id,
                spaceName: space.name,
              ),
            );
          }
        },
        onChanged: () {},
        onRecordChanged: (change) {
          unawaited(
            _applySharedRealtimeRecordChange(
              space,
              change,
            ),
          );
        },
      );
      _unifiedRealtimeSpaceIds.add(space.id);
    }
  }

  Future<void> _applySharedRealtimeRecordChange(
    SharedSpace space,
    SharedRealtimeRecordChange change,
  ) async {
    if (_activeAccountId == null ||
        change.spaceId != space.id ||
        change.entityType != 'shared_entry' ||
        change.entityId.isEmpty) {
      return;
    }

    final pending = await loadSharedPendingOperations(space.id);
    final localPending = pending.where(
      (operation) => operation.entityId == change.entityId,
    );
    if (localPending.any(
      (operation) => operation.updatedAt.isAfter(change.clientUpdatedAt),
    )) {
      return;
    }

    final entries = List<SharedEntry>.from(
      _sharedAgendaEntriesBySpace[space.id] ?? const <SharedEntry>[],
    )..removeWhere((entry) => entry.id == change.entityId);

    if (change.deletedAt == null && change.payload != null) {
      entries.add(
        await _localizeSharedThumbnail(
          SharedEntry.fromJson(
            change.payload!,
            updatedBy: change.updatedBy,
            updatedAt: change.clientUpdatedAt,
          ),
        ),
      );
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

    _sharedAgendaEntriesBySpace[space.id] = entries;
    _rebuildSharedAgendaDayIndex();

    final prefs = await _localState();
    final cursorKey = _sharedSyncCursorKey(space.id);
    final current = _readSyncCursor(prefs, cursorKey);
    final next = _nextSyncCursor(
      current,
      [change.clientUpdatedAt],
    );
    await prefs.writeBatch({
      sharedCacheStorageKey(space.id):
          jsonEncode(entries.map((entry) => entry.toCacheJson()).toList()),
      cursorKey: next.toIso8601String(),
    });

    notifyListeners();
  }

  Future<void> _cacheSharedAgendaEntries(
    String spaceId,
    List<SharedEntry> entries,
  ) async {
    final prefs = await _localState();
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
  String sharedInteractionPendingStorageKey(String spaceId) {
    final owner = _activeAccountId ?? 'guest';
    return 'shared_interactions_pending_${owner}_$spaceId';
  }

  String sharedMediaPendingStorageKey(String spaceId) {
    final owner = _activeAccountId ?? 'guest';
    return 'shared_media_pending_${owner}_$spaceId';
  }


  String get sharedSpacesCacheStorageKey {
    final owner = _activeAccountId ?? 'guest';
    return 'shared_spaces_$owner';
  }

  String get sharedUnreadStorageKey {
    final owner = _activeAccountId ?? 'guest';
    return 'shared_unread_$owner';
  }

  Future<void> _loadSharedUnreadCounts(LocalStateStore prefs) async {
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
    final prefs = await _localState();
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
    final prefs = await _localState();
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
    final prefs = await _localState();
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
    final queuedPayload = _sharedLocalQueuePayload(entry);
    operations.add(
      SharedPendingOperation(
        action: SharedPendingAction.upsert,
        entityId: entry.id,
        payload: queuedPayload,
        updatedAt: revision,
      ),
    );
    await _saveSharedPendingOperations(spaceId, operations);
    await refreshPendingSharedCount(notify: false);
    final localizedEntry = await _localizeSharedThumbnail(
      entry.copyWith(
        updatedBy: CloudSyncService.instance.userId,
        updatedAt: revision,
      ),
    );
    final cached = List<SharedEntry>.from(
      _sharedAgendaEntriesBySpace[spaceId] ?? const <SharedEntry>[],
    )
      ..removeWhere((cachedEntry) => cachedEntry.id == entry.id)
      ..add(localizedEntry);
    _sharedAgendaEntriesBySpace[spaceId] = cached;
    _rebuildSharedAgendaDayIndex();
    await _cacheSharedAgendaEntries(spaceId, cached);
    notifyListeners();
  }

  Future<void> enqueueSharedDelete({
    required String spaceId,
    required String entityId,
    DateTime? updatedAt,
    String mediaPath = '',
  }) async {
    await cancelSharedMediaUpload(
      spaceId: spaceId,
      entryId: entityId,
    );
    final revision = (updatedAt ?? DateTime.now()).toUtc();
    final operations = await loadSharedPendingOperations(spaceId);
    operations.removeWhere((operation) => operation.entityId == entityId);
    operations.add(
      SharedPendingOperation(
        action: SharedPendingAction.delete,
        entityId: entityId,
        updatedAt: revision,
        payload: mediaPath.trim().isEmpty
            ? null
            : {'mediaPath': mediaPath.trim()},
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
      final prefs = await _localState();
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

  Future<List<SharedInteractionPendingOperation>>
      loadSharedInteractionPendingOperations(String spaceId) async {
    final prefs = await _localState();
    final raw = prefs.getString(sharedInteractionPendingStorageKey(spaceId));
    if (raw == null) return <SharedInteractionPendingOperation>[];
    try {
      return (jsonDecode(raw) as List)
          .map(
            (value) => SharedInteractionPendingOperation.fromJson(
              Map<String, dynamic>.from(value as Map),
            ),
          )
          .where(
            (operation) =>
                operation.id.isNotEmpty &&
                operation.spaceId == spaceId &&
                operation.entryId.isNotEmpty,
          )
          .toList();
    } catch (_) {
      return <SharedInteractionPendingOperation>[];
    }
  }

  Future<void> _saveSharedInteractionPendingOperations(
    String spaceId,
    List<SharedInteractionPendingOperation> operations,
  ) async {
    final prefs = await _localState();
    final key = sharedInteractionPendingStorageKey(spaceId);
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

  Future<SharedEntryComment> enqueueSharedComment({
    required String spaceId,
    required String entryId,
    required String authorName,
    required String body,
  }) async {
    final ownerId = _activeAccountId;
    if (ownerId == null) {
      throw StateError('shared_account_required');
    }
    final text = body.trim();
    if (text.isEmpty) {
      throw const FormatException('empty_comment');
    }

    final commentId = const Uuid().v4();
    final now = DateTime.now().toUtc();
    final operations = await loadSharedInteractionPendingOperations(spaceId);
    operations.add(
      SharedInteractionPendingOperation(
        id: const Uuid().v4(),
        type: SharedInteractionPendingType.addComment,
        spaceId: spaceId,
        entryId: entryId,
        payload: {
          'commentId': commentId,
          'authorName': authorName.trim(),
          'body': text,
        },
        createdAt: now,
      ),
    );
    await _saveSharedInteractionPendingOperations(spaceId, operations);
    await refreshPendingSharedInteractionCount(notify: false);
    notifyListeners();

    return SharedEntryComment(
      id: commentId,
      spaceId: spaceId,
      entryId: entryId,
      userId: ownerId,
      authorName: authorName.trim(),
      body: text,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> enqueueSharedCommentDelete({
    required String spaceId,
    required String entryId,
    required String commentId,
  }) async {
    final operations = await loadSharedInteractionPendingOperations(spaceId);
    final before = operations.length;
    operations.removeWhere(
      (operation) =>
          operation.type == SharedInteractionPendingType.addComment &&
          operation.payload['commentId']?.toString() == commentId,
    );

    if (operations.length == before) {
      operations.add(
        SharedInteractionPendingOperation(
          id: const Uuid().v4(),
          type: SharedInteractionPendingType.deleteComment,
          spaceId: spaceId,
          entryId: entryId,
          payload: {'commentId': commentId},
          createdAt: DateTime.now().toUtc(),
        ),
      );
    }

    await _saveSharedInteractionPendingOperations(spaceId, operations);
    await refreshPendingSharedInteractionCount(notify: false);
    notifyListeners();
  }

  Future<void> enqueueSharedHeart({
    required String spaceId,
    required String entryId,
    required bool active,
  }) async {
    final operations = await loadSharedInteractionPendingOperations(spaceId);
    operations.removeWhere(
      (operation) =>
          operation.type == SharedInteractionPendingType.setHeart &&
          operation.entryId == entryId,
    );
    operations.add(
      SharedInteractionPendingOperation(
        id: const Uuid().v4(),
        type: SharedInteractionPendingType.setHeart,
        spaceId: spaceId,
        entryId: entryId,
        payload: {'active': active},
        createdAt: DateTime.now().toUtc(),
      ),
    );
    await _saveSharedInteractionPendingOperations(spaceId, operations);
    await refreshPendingSharedInteractionCount(notify: false);
    notifyListeners();
  }

  Future<void> refreshPendingSharedInteractionCount({
    bool notify = true,
  }) async {
    final ownerId = _activeAccountId;
    var next = 0;
    if (ownerId != null) {
      final prefs = await _localState();
      final prefix = 'shared_interactions_pending_${ownerId}_';
      for (final key in prefs.getKeys().where((key) => key.startsWith(prefix))) {
        final raw = prefs.getString(key);
        if (raw == null) continue;
        try {
          next += (jsonDecode(raw) as List).length;
        } catch (_) {}
      }
    }
    if (next == _pendingSharedInteractionCount) return;
    _pendingSharedInteractionCount = next;
    if (notify) notifyListeners();
  }

  Future<void> flushSharedInteractionOperations({
    String? spaceId,
  }) async {
    final cloud = CloudSyncService.instance;
    final ownerId = _activeAccountId;
    if (!cloud.signedIn ||
        ownerId == null ||
        cloud.userId != ownerId ||
        _sharedInteractionFlushRunning) {
      return;
    }

    _sharedInteractionFlushRunning = true;
    final before = _pendingSharedInteractionCount;
    var changed = false;
    try {
      final prefs = await _localState();
      final prefix = 'shared_interactions_pending_${ownerId}_';
      final keys = prefs
          .getKeys()
          .where(
            (key) =>
                key.startsWith(prefix) &&
                (spaceId == null ||
                    key == sharedInteractionPendingStorageKey(spaceId)),
          )
          .toList();

      for (final key in keys) {
        final currentSpaceId = key.substring(prefix.length);
        final operations =
            await loadSharedInteractionPendingOperations(currentSpaceId);

        for (final operation in List<SharedInteractionPendingOperation>.from(
          operations,
        )) {
          try {
            switch (operation.type) {
              case SharedInteractionPendingType.addComment:
                final commentId =
                    operation.payload['commentId']?.toString() ?? operation.id;
                await cloud.addSharedEntryComment(
                  spaceId: currentSpaceId,
                  entryId: operation.entryId,
                  authorName:
                      operation.payload['authorName']?.toString() ?? '',
                  body: operation.payload['body']?.toString() ?? '',
                  commentId: commentId,
                );
                try {
                  await cloud.sendSharedPush(
                    spaceId: currentSpaceId,
                    eventId: 'comment:$commentId',
                    action: 'comment',
                    entityId: operation.entryId,
                  );
                } catch (_) {}
                break;
              case SharedInteractionPendingType.deleteComment:
                final commentId =
                    operation.payload['commentId']?.toString() ?? '';
                if (commentId.isNotEmpty) {
                  await cloud.deleteSharedEntryComment(commentId);
                }
                break;
              case SharedInteractionPendingType.setHeart:
                final active = operation.payload['active'] == true;
                await cloud.setSharedHeart(
                  spaceId: currentSpaceId,
                  entryId: operation.entryId,
                  active: active,
                );
                if (active) {
                  try {
                    await cloud.sendSharedPush(
                      spaceId: currentSpaceId,
                      eventId: 'reaction:${operation.id}',
                      action: 'reaction',
                      entityId: operation.entryId,
                    );
                  } catch (_) {}
                }
                break;
            }

            final latest =
                await loadSharedInteractionPendingOperations(currentSpaceId);
            latest.removeWhere((candidate) => candidate.id == operation.id);
            await _saveSharedInteractionPendingOperations(
              currentSpaceId,
              latest,
            );
            changed = true;
          } catch (_) {
            // Keep the operation queued for the next resume/periodic sync.
          }
        }
      }
    } finally {
      _sharedInteractionFlushRunning = false;
      await refreshPendingSharedInteractionCount(notify: false);
      if (changed || before != _pendingSharedInteractionCount) {
        notifyListeners();
      }
    }
  }

  Future<SharedMediaPendingUpload> _localizeSharedMediaUpload(
    SharedMediaPendingUpload upload,
  ) async {
    var mediaAssetId = upload.mediaAssetId;
    var thumbnailAssetId = upload.thumbnailAssetId;

    if (mediaAssetId.isEmpty && upload.imageBase64.isNotEmpty) {
      mediaAssetId =
          await MediaAssetStore.instance.importBase64(upload.imageBase64) ?? '';
    }
    if (thumbnailAssetId.isEmpty && upload.thumbnailBase64.isNotEmpty) {
      thumbnailAssetId = await MediaAssetStore.instance
              .importBase64(upload.thumbnailBase64) ??
          '';
    }

    if (mediaAssetId == upload.mediaAssetId &&
        thumbnailAssetId == upload.thumbnailAssetId) {
      return upload;
    }

    return SharedMediaPendingUpload(
      id: upload.id,
      spaceId: upload.spaceId,
      entryId: upload.entryId,
      title: upload.title,
      note: upload.note,
      date: upload.date,
      mediaAssetId: mediaAssetId,
      thumbnailAssetId: thumbnailAssetId,
      imageBase64: upload.imageBase64,
      thumbnailBase64: upload.thumbnailBase64,
      oldMediaPath: upload.oldMediaPath,
      createdAt: upload.createdAt,
    );
  }

  Future<Uint8List?> _sharedMediaUploadBytes(
    SharedMediaPendingUpload upload, {
    required bool thumbnail,
  }) async {
    final assetId =
        thumbnail ? upload.thumbnailAssetId : upload.mediaAssetId;
    if (assetId.isNotEmpty) {
      final stored = await MediaAssetStore.instance.read(assetId);
      if (stored != null) return stored;
    }

    final legacy =
        thumbnail ? upload.thumbnailBase64 : upload.imageBase64;
    if (legacy.isEmpty) return null;
    try {
      return base64Decode(legacy);
    } catch (_) {
      return null;
    }
  }

  Future<List<SharedMediaPendingUpload>> loadSharedMediaPendingUploads(
    String spaceId,
  ) async {
    final prefs = await _localState();
    final raw = prefs.getString(sharedMediaPendingStorageKey(spaceId));
    if (raw == null) return <SharedMediaPendingUpload>[];

    try {
      final decoded = (jsonDecode(raw) as List)
          .map(
            (value) => SharedMediaPendingUpload.fromJson(
              Map<String, dynamic>.from(value as Map),
            ),
          )
          .where(
            (upload) =>
                upload.id.isNotEmpty &&
                upload.spaceId == spaceId &&
                upload.entryId.isNotEmpty &&
                upload.hasFullMedia,
          )
          .toList();

      final localized = <SharedMediaPendingUpload>[];
      var changed = false;
      for (final upload in decoded) {
        final next = await _localizeSharedMediaUpload(upload);
        localized.add(next);
        changed = changed ||
            next.mediaAssetId != upload.mediaAssetId ||
            next.thumbnailAssetId != upload.thumbnailAssetId;
      }
      if (changed) {
        await _saveSharedMediaPendingUploads(spaceId, localized);
      }
      return localized;
    } catch (_) {
      return <SharedMediaPendingUpload>[];
    }
  }

  Future<void> _saveSharedMediaPendingUploads(
    String spaceId,
    List<SharedMediaPendingUpload> uploads,
  ) async {
    final prefs = await _localState();
    final key = sharedMediaPendingStorageKey(spaceId);
    if (uploads.isEmpty) {
      await prefs.remove(key);
    } else {
      await prefs.setString(
        key,
        jsonEncode(uploads.map((upload) => upload.toJson()).toList()),
      );
    }
  }

  Future<void> cancelSharedMediaUpload({
    required String spaceId,
    required String entryId,
  }) async {
    final uploads = await loadSharedMediaPendingUploads(spaceId);
    final before = uploads.length;
    uploads.removeWhere((upload) => upload.entryId == entryId);
    if (uploads.length == before) return;
    await _saveSharedMediaPendingUploads(spaceId, uploads);
    await refreshPendingSharedMediaCount(notify: false);
    notifyListeners();
  }

  Future<void> enqueueSharedMediaUpload(
    SharedMediaPendingUpload upload,
  ) async {
    final localizedUpload = await _localizeSharedMediaUpload(upload);
    final uploads =
        await loadSharedMediaPendingUploads(localizedUpload.spaceId);
    uploads.removeWhere(
      (candidate) => candidate.entryId == localizedUpload.entryId,
    );
    uploads.add(localizedUpload);
    await _saveSharedMediaPendingUploads(localizedUpload.spaceId, uploads);
    await refreshPendingSharedMediaCount(notify: false);
    notifyListeners();
  }

  Future<void> refreshPendingSharedMediaCount({
    bool notify = true,
  }) async {
    final ownerId = _activeAccountId;
    var next = 0;
    if (ownerId != null) {
      final prefs = await _localState();
      final prefix = 'shared_media_pending_${ownerId}_';
      for (final key in prefs.getKeys().where((key) => key.startsWith(prefix))) {
        final raw = prefs.getString(key);
        if (raw == null) continue;
        try {
          next += (jsonDecode(raw) as List).length;
        } catch (_) {}
      }
    }
    if (next == _pendingSharedMediaCount) return;
    _pendingSharedMediaCount = next;
    if (notify) notifyListeners();
  }

  Future<void> flushSharedMediaUploads({
    String? spaceId,
  }) async {
    final cloud = CloudSyncService.instance;
    final ownerId = _activeAccountId;
    if (!cloud.signedIn ||
        ownerId == null ||
        cloud.userId != ownerId ||
        _sharedMediaFlushRunning) {
      return;
    }

    _sharedMediaFlushRunning = true;
    final before = _pendingSharedMediaCount;
    var changed = false;
    try {
      final prefs = await _localState();
      final prefix = 'shared_media_pending_${ownerId}_';
      final keys = prefs
          .getKeys()
          .where(
            (key) =>
                key.startsWith(prefix) &&
                (spaceId == null ||
                    key == sharedMediaPendingStorageKey(spaceId)),
          )
          .toList();

      for (final key in keys) {
        final currentSpaceId = key.substring(prefix.length);
        final uploads = await loadSharedMediaPendingUploads(currentSpaceId);

        for (final upload in List<SharedMediaPendingUpload>.from(uploads)) {
          try {
            final mediaBytes = await _sharedMediaUploadBytes(
              upload,
              thumbnail: false,
            );
            if (mediaBytes == null || mediaBytes.isEmpty) {
              throw StateError('shared_media_missing');
            }
            final thumbnailBytes = await _sharedMediaUploadBytes(
              upload,
              thumbnail: true,
            );

            final mediaPath = await cloud.uploadSharedMedia(
              spaceId: currentSpaceId,
              entryId: upload.entryId,
              bytes: mediaBytes,
            );
            final remoteCacheId =
                MediaAssetStore.instance.namedAssetId('remote', mediaPath);
            await MediaAssetStore.instance.putNamed(
              remoteCacheId,
              mediaBytes,
            );

            final entry = SharedEntry(
              id: upload.entryId,
              type: SharedEntryType.photo,
              title: upload.title,
              note: upload.note,
              date: upload.date,
              createdAt: upload.createdAt,
              mediaPath: mediaPath,
              mediaThumbnailBase64: thumbnailBytes == null
                  ? ''
                  : base64Encode(thumbnailBytes),
              mediaThumbnailAssetId: upload.thumbnailAssetId,
            );
            await enqueueSharedUpsert(
              spaceId: currentSpaceId,
              entry: entry,
            );

            final latest = await loadSharedMediaPendingUploads(currentSpaceId);
            latest.removeWhere((candidate) => candidate.id == upload.id);
            await _saveSharedMediaPendingUploads(currentSpaceId, latest);
            changed = true;

            await flushSharedPendingOperations(spaceId: currentSpaceId);
            final stillPending =
                await pendingSharedEntityIds(currentSpaceId);
            if (!stillPending.contains(upload.entryId) &&
                upload.oldMediaPath.isNotEmpty &&
                upload.oldMediaPath != mediaPath) {
              try {
                await cloud.deleteSharedMedia(upload.oldMediaPath);
              } catch (_) {}
            }
          } catch (_) {
            // Keep compressed bytes locally and retry automatically later.
          }
        }
      }
    } finally {
      _sharedMediaFlushRunning = false;
      await refreshPendingSharedMediaCount(notify: false);
      if (changed || before != _pendingSharedMediaCount) {
        notifyListeners();
      }
    }
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
      final prefs = await _localState();
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
              final mediaPath =
                  operation.payload?['mediaPath']?.toString().trim() ?? '';
              if (mediaPath.isNotEmpty) {
                try {
                  await cloud.deleteSharedMedia(mediaPath);
                } catch (_) {
                  // Record deletion is authoritative; stale media cleanup can
                  // be retried manually without resurrecting the entry.
                }
              }
            } else if (operation.payload != null) {
              final portablePayload =
                  await _materializeSharedQueuePayload(
                operation.payload!,
              );
              await cloud.upsertSharedRecord(
                spaceId: currentSpaceId,
                entityType: 'shared_entry',
                entityId: operation.entityId,
                payload: portablePayload,
                updatedAt: operation.updatedAt,
              );
            } else {
              continue;
            }

            if (cloud.userId != ownerId || _activeAccountId != ownerId) {
              return;
            }

            await removeExactOperation(operation);

            try {
              final eventId = [
                currentSpaceId,
                operation.entityId,
                operation.updatedAt.toUtc().toIso8601String(),
                operation.action.name,
              ].join(':');
              var pushAction = operation.action.name;
              final type = operation.payload?['type']?.toString();
              if (operation.action == SharedPendingAction.upsert) {
                if (type == SharedEntryType.photo.name) {
                  pushAction = 'photo';
                } else if (type == SharedEntryType.sketch.name) {
                  pushAction = 'sketch';
                }
              }
              await cloud.sendSharedPush(
                spaceId: currentSpaceId,
                eventId: eventId,
                action: pushAction,
                entityId: operation.entityId,
              );
            } catch (_) {
              // Push is best-effort and must never requeue a synced change.
            }

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
    final entry = InboxEntry(
      id: const Uuid().v4(),
      text: value,
      createdAt: DateTime.now(),
    );
    inbox.insert(0, entry);
    await _persistEntityMutation(
      type: 'inbox',
      id: entry.id,
      payload: entry.toJson(),
    );
    notifyListeners();
  }

  Future<void> deleteInboxEntry(String id) async {
    inbox.removeWhere((e) => e.id == id);
    await _persistEntityMutation(
      type: 'inbox',
      id: id,
      deleted: true,
    );
    notifyListeners();
  }

  Future<void> toggleInboxPinned(String id) async {
    final index = inbox.indexWhere((e) => e.id == id);
    if (index < 0) return;
    inbox[index] = inbox[index].copyWith(pinned: !inbox[index].pinned);
    await _persistEntityMutation(
      type: 'inbox',
      id: inbox[index].id,
      payload: inbox[index].toJson(),
    );
    notifyListeners();
  }

  Future<void> toggleItemPinned(String id) async {
    final index = items.indexWhere((e) => e.id == id);
    if (index < 0) return;
    items[index] = items[index].copyWith(pinned: !items[index].pinned);
    _invalidateDayIndex();
    await _persistEntityMutation(
      type: 'item',
      id: items[index].id,
      payload: items[index].toJson(),
    );
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
    final prefs = await _localState();
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
    _notifyShellChanged();
    notifyListeners();
  }

  Future<void> resetPreferences() async {
    await savePreferences(const AgendaPreferences());
  }

  Future<void> addHabit(String name) async {
    final value = name.trim();
    if (value.isEmpty) return;
    final habit = HabitDefinition(
      id: const Uuid().v4(),
      name: value,
    );
    habits.add(habit);
    await _persistEntityMutation(
      type: 'habit',
      id: habit.id,
      payload: habit.toJson(),
    );
    notifyListeners();
  }

  Future<void> removeHabit(String id) async {
    habits.removeWhere((e) => e.id == id);
    final mutations = <
        ({
          String type,
          String id,
          Map<String, dynamic>? payload,
          bool deleted,
        })>[
      (
        type: 'habit',
        id: id,
        payload: null,
        deleted: true,
      ),
    ];

    for (final entry in journals.entries.toList()) {
      final journal = entry.value;
      if (!journal.completedHabitIds.contains(id)) continue;

      final updated = journal.copyWith(
        completedHabitIds: journal.completedHabitIds
            .where((habitId) => habitId != id)
            .toList(),
      );
      journals[entry.key] = updated;
      mutations.add(
        (
          type: 'journal',
          id: entry.key,
          payload: updated.toLocalJson(),
          deleted: false,
        ),
      );
    }

    await _persistEntityMutations(mutations);
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
    final key = dateKey(date);
    final updated = current.copyWith(completedHabitIds: completed);
    journals[key] = updated;
    await _persistEntityMutation(
      type: 'journal',
      id: key,
      payload: updated.toLocalJson(),
    );
    notifyListeners();
  }

  MonthlyData month(int year, int month) => months[monthKey(year, month)] ?? const MonthlyData();

  Future<void> saveMonth(int year, int month, MonthlyData value) async {
    final key = monthKey(year, month);
    months[key] = value;
    await _persistEntityMutation(
      type: 'month',
      id: key,
      payload: value.toJson(),
    );
    notifyListeners();
  }

  WeekData week(DateTime anyDay) {
    final monday = mondayOf(anyDay);
    return weeks[dateKey(monday)] ?? const WeekData();
  }

  Future<void> saveWeek(DateTime anyDay, WeekData value) async {
    final monday = mondayOf(anyDay);
    final key = dateKey(monday);
    weeks[key] = value;
    await _persistEntityMutation(
      type: 'week',
      id: key,
      payload: value.toJson(),
    );
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
    _deferredCloudSyncTimer?.cancel();
    for (final spaceId in _unifiedRealtimeSpaceIds.toList()) {
      unawaited(
        CloudSyncService.instance.unsubscribeSharedSpace(
          spaceId: spaceId,
          listenerKey: 'unified-agenda',
        ),
      );
    }
    _unifiedRealtimeSpaceIds.clear();
    shellRevision.dispose();
    super.dispose();
  }
}
