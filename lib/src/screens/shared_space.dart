part of '../../main.dart';

class SharedSpaceHubScreen extends StatefulWidget {
  final AgendaStore store;

  const SharedSpaceHubScreen({super.key, required this.store});

  @override
  State<SharedSpaceHubScreen> createState() => _SharedSpaceHubScreenState();
}

class _SharedSpaceHubScreenState extends State<SharedSpaceHubScreen> {
  bool loading = true;
  List<SharedSpace> spaces = const [];
  final Map<String, int> pendingBySpace = {};
  @override
  void initState() {
    super.initState();
    _loadCachedThenReload();
  }

  Future<void> _loadCachedThenReload() async {
    final prefs = await widget.store._localState();
    final raw = prefs.getString(widget.store.sharedSpacesCacheStorageKey);
    if (raw != null) {
      try {
        final cached = (jsonDecode(raw) as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .map(
              (e) => SharedSpace.fromJson(
                e,
                role: e['role'] as String? ?? 'member',
              ),
            )
            .toList();
        if (mounted) {
          setState(() {
            spaces = cached;
            loading = false;
          });
        }
        await _refreshIndicators(cached);
      } catch (_) {}
    }
    await _reload();
  }

  Future<void> _saveSpacesCache(List<SharedSpace> value) async {
    final prefs = await widget.store._localState();
    await prefs.setString(
      widget.store.sharedSpacesCacheStorageKey,
      jsonEncode(
        value
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
    await widget.store.refreshSharedAgendaCache();
  }

  Future<void> _refreshIndicators(List<SharedSpace> value) async {
    final next = <String, int>{};
    for (final space in value) {
      next[space.id] = await widget.store.pendingSharedChanges(space.id);
    }
    if (mounted) {
      setState(() {
        pendingBySpace
          ..clear()
          ..addAll(next);
      });
    }
  }

  Future<void> _reload() async {
    final cloud = CloudSyncService.instance;
    if (!cloud.signedIn) {
      if (mounted) setState(() => loading = false);
      return;
    }
    try {
      final result = await cloud.listSharedSpaces();
      await _saveSpacesCache(result);
      await _refreshIndicators(result);
      await widget.store.refreshSharedAgendaCache(pullRemote: true);
      if (mounted) {
        setState(() {
          spaces = result;
          loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _createSpace() async {
    final controller = TextEditingController(text: 'Noi ♡');
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AnnaStrings.of(context).d3('createSharedSpace')),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: AnnaStrings.of(context).d3('spaceName'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AnnaStrings.of(context).cancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: Text(AnnaStrings.of(context).d3('create')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;

    setState(() => loading = true);
    try {
      await CloudSyncService.instance.createSharedSpace(name: name);
      await _reload();
    } catch (error) {
      if (!mounted) return;
      setState(() => loading = false);
      _message(AnnaStrings.of(context).d3('spaceCreateFailed'));
    }
  }

  Future<void> _joinSpace() async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AnnaStrings.of(context).d3('joinWithCode')),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          maxLength: 8,
          decoration: InputDecoration(
            labelText: AnnaStrings.of(context).d3('inviteCode'),
            hintText: 'Es. A1B2C3D4',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AnnaStrings.of(context).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              controller.text.trim().toUpperCase(),
            ),
            child: Text(AnnaStrings.of(context).d3('join')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (code == null || code.isEmpty) return;

    setState(() => loading = true);
    try {
      await CloudSyncService.instance.joinSharedSpace(code);
      await _reload();
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
      _message(AnnaStrings.of(context).d3('invalidInvite'));
    }
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cloud = CloudSyncService.instance;
    return AnimatedBuilder(
      animation: Listenable.merge([
        cloud,
        widget.store.sharedRevision,
        widget.store.accountRevision,
      ]),
      builder: (context, _) {
        final accent = context.accentSurface;
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Noi ♡',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            actions: [
              if (cloud.signedIn)
                IconButton(
                  tooltip: AnnaStrings.of(context).d3('refresh'),
                  onPressed: loading ? null : _reload,
                  icon: const Icon(Icons.refresh),
                ),
            ],
          ),
          body: !cloud.signedIn
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_off_outlined, size: 50),
                        const SizedBox(height: 12),
                        Text(
                          'Sessione account scaduta',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Noi ♡ usa automaticamente l’account generale di Anna\'s Diary. '
                          'Non esiste più un login separato qui.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        FilledButton(
                          onPressed: () => Navigator.of(context)
                              .popUntil((route) => route.isFirst),
                          child: Text(AnnaStrings.of(context).d3('backToAccess')),
                        ),
                      ],
                    ),
                  ),
                )
              : loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: accent.gradient,
                            borderRadius: BorderRadius.circular(26),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.favorite_outline,
                                size: 30,
                                color: accent.foreground,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                AnnaStrings.of(context).d3('sharedSpace'),
                                style: TextStyle(
                                  color: accent.foreground,
                                  fontSize: 23,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Gli aggiornamenti arrivano in tempo reale. '
                                AnnaStrings.of(context).d3('offlineQueue'),
                                style: TextStyle(
                                  color: accent.secondaryForeground,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (spaces.isEmpty)
                          SimpleCard(
                            child: Column(
                              children: [
                                Text(
                                  AnnaStrings.of(context).d3('noSharedSpace'),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    onPressed: _createSpace,
                                    icon: const Icon(Icons.add),
                                    label: Text(AnnaStrings.of(context).d3('createOurSpace')),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: _joinSpace,
                                    icon: const Icon(Icons.link),
                                    label: Text(AnnaStrings.of(context).d3('enterCode')),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else ...[
                          ...spaces.map(
                            (space) {
                              final unread = widget.store.sharedUnreadCount(space.id);
                              final pending = pendingBySpace[space.id] ?? 0;
                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    child: Icon(
                                      space.isOwner
                                          ? Icons.favorite
                                          : Icons.favorite_outline,
                                    ),
                                  ),
                                  title: Text(
                                    space.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  subtitle: Text(
                                    pending > 0
                                        ? '$pending modifiche da sincronizzare'
                                        : space.isOwner
                                            ? 'Creato da te · sincronizzato'
                                            : AnnaStrings.of(context).d3('sharedSynced'),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (unread > 0)
                                        Badge(
                                          label: Text(
                                            unread > 99 ? '99+' : '$unread',
                                          ),
                                          child: const Icon(
                                            Icons.notifications_none,
                                          ),
                                        ),
                                      const SizedBox(width: 6),
                                      const Icon(Icons.chevron_right),
                                    ],
                                  ),
                                  onTap: () async {
                                    await widget.store.markSharedSpaceRead(
                                      space.id,
                                    );
                                    if (!context.mounted) return;
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => SharedSpaceScreen(
                                          store: widget.store,
                                          space: space,
                                        ),
                                      ),
                                    );
                                    if (!mounted) return;
                                    await widget.store.markSharedSpaceRead(
                                      space.id,
                                    );
                                    await _reload();
                                  },
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 6),
                          OutlinedButton.icon(
                            onPressed: _joinSpace,
                            icon: const Icon(Icons.link),
                            label: Text(AnnaStrings.of(context).d3('joinAnother')),
                          ),
                        ],
                      ],
                    ),
        );
      },
    );
  }
}
class SharedSpaceScreen extends StatefulWidget {
  final AgendaStore store;
  final SharedSpace space;

  const SharedSpaceScreen({
    super.key,
    required this.store,
    required this.space,
  });

  @override
  State<SharedSpaceScreen> createState() => _SharedSpaceScreenState();
}

class _SharedSpaceScreenState extends State<SharedSpaceScreen> {
  bool loading = true;
  bool realtimeConnected = false;
  List<SharedEntry> entries = [];
  Set<String> pendingIds = {};
  DateTime selected = DateTime.now();
  DateTime? lastRefreshAt;
  Timer? _realtimeDebounce;
  int _seenConflictCount = 0;
  bool feedMode = true;
  bool interactionsLoading = false;
  bool sharedPhotoBusy = false;
  Map<String, List<SharedEntryComment>> commentsByEntry = {};
  Map<String, Set<String>> heartsByEntry = {};
  Map<String, DateTime> memberReads = {};
  Timer? _interactionDebounce;

  String get _cacheKey =>
      widget.store.sharedCacheStorageKey(widget.space.id);
  String get _pendingKey =>
      widget.store.sharedPendingStorageKey(widget.space.id);
  String get _interactionCacheKey =>
      'shared_interactions_cache_${widget.store.activeAccountId ?? 'guest'}_${widget.space.id}';

  @override
  void initState() {
    super.initState();
    _seenConflictCount = widget.store.sharedConflictCount;
    _loadCachedThenRefresh();
    _bindRealtime();
  }

  @override
  void dispose() {
    _realtimeDebounce?.cancel();
    _interactionDebounce?.cancel();
    unawaited(
      CloudSyncService.instance.unsubscribeSharedSpace(
        spaceId: widget.space.id,
        listenerKey: 'screen',
      ),
    );
    super.dispose();
  }

  void _bindRealtime() {
    if (!CloudSyncService.instance.signedIn) return;
    CloudSyncService.instance.subscribeSharedSpace(
      spaceId: widget.space.id,
      listenerKey: 'screen',
      onChanged: () {
        _realtimeDebounce?.cancel();
        _realtimeDebounce = Timer(const Duration(milliseconds: 350), () {
          if (mounted) {
            unawaited(
              _refresh(
                silent: true,
                refreshInteractions: false,
              ),
            );
          }
        });
      },
      onInteractionChanged: (change) {
        _interactionDebounce?.cancel();
        _interactionDebounce = Timer(const Duration(milliseconds: 80), () {
          if (mounted) unawaited(_applyRealtimeInteractionChange(change));
        });
      },
      onConnectionChanged: (connected) {
        if (!mounted) return;
        setState(() => realtimeConnected = connected);
      },
    );
  }

  Future<void> _applyRealtimeInteractionChange(
    SharedRealtimeInteractionChange change,
  ) async {
    final record = change.record;
    final changeSpaceId = record['space_id']?.toString();
    if (changeSpaceId == null || changeSpaceId.isEmpty) {
      await _loadInteractions();
      return;
    }
    if (changeSpaceId != widget.space.id) return;

    final nextComments = <String, List<SharedEntryComment>>{
      for (final entry in commentsByEntry.entries)
        entry.key: List<SharedEntryComment>.from(entry.value),
    };
    final nextHearts = <String, Set<String>>{
      for (final entry in heartsByEntry.entries)
        entry.key: Set<String>.from(entry.value),
    };
    final nextReads = Map<String, DateTime>.from(memberReads);

    switch (change.kind) {
      case SharedRealtimeInteractionKind.comment:
        final id = record['id']?.toString() ?? '';
        final entryId = record['entry_id']?.toString() ?? '';
        if (id.isEmpty || entryId.isEmpty) {
          await _loadInteractions();
          return;
        }
        final bucket =
            nextComments.putIfAbsent(entryId, () => <SharedEntryComment>[]);
        bucket.removeWhere((comment) => comment.id == id);
        if (!change.deleted && change.newRecord.isNotEmpty) {
          bucket.add(SharedEntryComment.fromJson(change.newRecord));
          bucket.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        }
        break;
      case SharedRealtimeInteractionKind.reaction:
        final entryId = record['entry_id']?.toString() ?? '';
        final userId = record['user_id']?.toString() ?? '';
        final kind = record['kind']?.toString() ?? '';
        if (entryId.isEmpty || userId.isEmpty || kind != 'heart') {
          await _loadInteractions();
          return;
        }
        final hearts = nextHearts.putIfAbsent(entryId, () => <String>{});
        if (change.deleted) {
          hearts.remove(userId);
        } else {
          hearts.add(userId);
        }
        break;
      case SharedRealtimeInteractionKind.memberRead:
        final userId = record['user_id']?.toString() ?? '';
        if (userId.isEmpty) {
          await _loadInteractions();
          return;
        }
        if (change.deleted) {
          nextReads.remove(userId);
        } else {
          final seenAt =
              DateTime.tryParse(record['last_seen_at']?.toString() ?? '');
          if (seenAt != null) nextReads[userId] = seenAt;
        }
        break;
    }

    await _saveInteractionCache(nextComments, nextHearts, nextReads);
    if (!mounted) return;
    setState(() {
      commentsByEntry = nextComments;
      heartsByEntry = nextHearts;
      memberReads = nextReads;
      interactionsLoading = false;
    });
  }

  Future<void> _loadInteractionCache(
    LocalStateStore prefs,
  ) async {
    final raw = prefs.getString(_interactionCacheKey);
    if (raw == null) return;
    try {
      final decoded = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      final commentsRaw = decoded['comments'] as List? ?? const [];
      final heartsRaw = decoded['hearts'] is Map
          ? Map<String, dynamic>.from(decoded['hearts'] as Map)
          : <String, dynamic>{};
      final readsRaw = decoded['reads'] is Map
          ? Map<String, dynamic>.from(decoded['reads'] as Map)
          : <String, dynamic>{};

      final cachedComments = <String, List<SharedEntryComment>>{};
      for (final rawComment in commentsRaw.whereType<Map>()) {
        final comment = SharedEntryComment.fromJson(
          Map<String, dynamic>.from(rawComment),
        );
        cachedComments
            .putIfAbsent(comment.entryId, () => <SharedEntryComment>[])
            .add(comment);
      }

      commentsByEntry = cachedComments;
      heartsByEntry = {
        for (final entry in heartsRaw.entries)
          entry.key: (entry.value as List? ?? const [])
              .map((value) => value.toString())
              .toSet(),
      };
      memberReads = {
        for (final entry in readsRaw.entries)
          if (DateTime.tryParse(entry.value.toString()) != null)
            entry.key: DateTime.parse(entry.value.toString()),
      };
    } catch (_) {}
  }

  Future<void> _saveInteractionCache(
    Map<String, List<SharedEntryComment>> comments,
    Map<String, Set<String>> hearts,
    Map<String, DateTime> reads,
  ) async {
    final prefs = await widget.store._localState();
    final flatComments = <Map<String, dynamic>>[
      for (final bucket in comments.values)
        for (final comment in bucket)
          {
            'id': comment.id,
            'space_id': comment.spaceId,
            'entry_id': comment.entryId,
            'user_id': comment.userId,
            'author_name': comment.authorName,
            'body': comment.body,
            'created_at': comment.createdAt.toUtc().toIso8601String(),
            'updated_at': comment.updatedAt.toUtc().toIso8601String(),
          },
    ];
    await prefs.setString(
      _interactionCacheKey,
      jsonEncode({
        'comments': flatComments,
        'hearts': {
          for (final entry in hearts.entries)
            entry.key: entry.value.toList(),
        },
        'reads': {
          for (final entry in reads.entries)
            entry.key: entry.value.toUtc().toIso8601String(),
        },
      }),
    );
  }

  Future<void> _loadCachedThenRefresh() async {
    final prefs = await widget.store._localState();
    final raw = prefs.getString(_cacheKey);
    if (raw != null) {
      try {
        entries = (jsonDecode(raw) as List)
            .map(
              (e) => SharedEntry.fromCacheJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList();
      } catch (_) {}
    }
    await _loadInteractionCache(prefs);
    await _updatePendingState();
    await _loadInteractions();
    if (mounted) setState(() => loading = false);
    await _refresh(
      silent: entries.isNotEmpty,
      refreshInteractions: false,
    );
  }

  Future<void> _saveCache() async {
    final prefs = await widget.store._localState();
    final localized = <SharedEntry>[];
    for (final entry in entries) {
      localized.add(await widget.store._localizeSharedThumbnail(entry));
    }
    entries = localized;
    await prefs.setString(
      _cacheKey,
      jsonEncode(entries.map((e) => e.toCacheJson()).toList()),
    );
    await widget.store.refreshSharedAgendaCache();
  }

  Future<List<SharedPendingOperation>> _loadPending() =>
      widget.store.loadSharedPendingOperations(widget.space.id);

  Future<void> _updatePendingState() async {
    final operations = await _loadPending();
    if (!mounted) return;
    setState(() {
      pendingIds = operations.map((operation) => operation.entityId).toSet();
    });
  }

  Future<void> _flushPending() async {
    final conflictsBefore = widget.store.sharedConflictCount;
    await widget.store.flushSharedMediaUploads(
      spaceId: widget.space.id,
    );
    await widget.store.flushSharedInteractionOperations(
      spaceId: widget.space.id,
    );
    await widget.store.flushSharedPendingOperations(
      spaceId: widget.space.id,
    );
    await _updatePendingState();
    if (widget.store.sharedConflictCount > conflictsBefore &&
        widget.store.sharedConflictCount > _seenConflictCount) {
      _seenConflictCount = widget.store.sharedConflictCount;
      _message(
        AnnaStrings.of(context).d3('conflictResolved'),
      );
    }
  }

  Future<void> _refresh({
    bool silent = false,
    bool refreshInteractions = true,
  }) async {
    final cloud = CloudSyncService.instance;
    if (!cloud.signedIn) {
      await _updatePendingState();
      await _loadInteractions();
      if (mounted) setState(() => loading = false);
      return;
    }
    if (!silent && mounted) setState(() => loading = true);
    try {
      await _flushPending();
      await widget.store.refreshSharedAgendaCache(
        pullRemote: true,
        notify: false,
        targetSpaceId: widget.space.id,
      );

      final next = List<SharedEntry>.from(
        widget.store._sharedAgendaEntriesBySpace[widget.space.id] ??
            const <SharedEntry>[],
      )..sort((a, b) {
          final date = b.date.compareTo(a.date);
          if (date != 0) return date;
          final am =
              a.start == null ? -1 : a.start!.hour * 60 + a.start!.minute;
          final bm =
              b.start == null ? -1 : b.start!.hour * 60 + b.start!.minute;
          final time = bm.compareTo(am);
          if (time != 0) return time;
          final aUpdated = a.updatedAt ?? a.date;
          final bUpdated = b.updatedAt ?? b.date;
          return bUpdated.compareTo(aUpdated);
        });

      final pending = await _loadPending();
      entries = next;
      pendingIds = pending.map((operation) => operation.entityId).toSet();
      lastRefreshAt = DateTime.now();
      await cloud.markSharedSpaceSeen(widget.space.id);
      if (refreshInteractions) {
        await _loadInteractions();
      }
      await widget.store.markSharedSpaceRead(widget.space.id);
    } catch (_) {
      if (!silent) {
        _message(
          AnnaStrings.of(context).d3('updateFromCache'),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _loadInteractions() async {
    final cloud = CloudSyncService.instance;
    if (mounted) setState(() => interactionsLoading = true);

    final nextComments = <String, List<SharedEntryComment>>{
      for (final entry in commentsByEntry.entries)
        entry.key: List<SharedEntryComment>.from(entry.value),
    };
    final nextHearts = <String, Set<String>>{
      for (final entry in heartsByEntry.entries)
        entry.key: Set<String>.from(entry.value),
    };
    var nextReads = Map<String, DateTime>.from(memberReads);

    if (cloud.signedIn) {
      try {
        await widget.store.flushSharedInteractionOperations(
          spaceId: widget.space.id,
        );
        final comments =
            await cloud.listSharedEntryComments(widget.space.id);
        final reactions =
            await cloud.listSharedEntryReactions(widget.space.id);
        final reads =
            await cloud.listSharedMemberReads(widget.space.id);

        nextComments.clear();
        for (final comment in comments) {
          nextComments.putIfAbsent(comment.entryId, () => []).add(comment);
        }
        nextHearts.clear();
        for (final reaction in reactions) {
          if (reaction.kind != 'heart') continue;
          nextHearts
              .putIfAbsent(reaction.entryId, () => <String>{})
              .add(reaction.userId);
        }
        nextReads = {
          for (final read in reads) read.userId: read.lastSeenAt,
        };
      } catch (_) {
        // Preserve the last known interaction cache and overlay the offline
        // queue below.
      }
    }

    final pending = await widget.store
        .loadSharedInteractionPendingOperations(widget.space.id);
    final uid = widget.store.activeAccountId ?? cloud.userId ?? '';
    for (final operation in pending) {
      switch (operation.type) {
        case SharedInteractionPendingType.addComment:
          final commentId =
              operation.payload['commentId']?.toString() ?? operation.id;
          final bucket =
              nextComments.putIfAbsent(operation.entryId, () => []);
          if (!bucket.any((comment) => comment.id == commentId)) {
            bucket.add(
              SharedEntryComment(
                id: commentId,
                spaceId: widget.space.id,
                entryId: operation.entryId,
                userId: uid,
                authorName:
                    operation.payload['authorName']?.toString() ?? '',
                body: operation.payload['body']?.toString() ?? '',
                createdAt: operation.createdAt,
                updatedAt: operation.createdAt,
              ),
            );
          }
          break;
        case SharedInteractionPendingType.deleteComment:
          final commentId =
              operation.payload['commentId']?.toString() ?? '';
          nextComments[operation.entryId]
              ?.removeWhere((comment) => comment.id == commentId);
          break;
        case SharedInteractionPendingType.setHeart:
          final hearts =
              nextHearts.putIfAbsent(operation.entryId, () => <String>{});
          if (operation.payload['active'] == true) {
            if (uid.isNotEmpty) hearts.add(uid);
          } else {
            hearts.remove(uid);
          }
          break;
      }
    }

    for (final bucket in nextComments.values) {
      bucket.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }

    await _saveInteractionCache(
      nextComments,
      nextHearts,
      nextReads,
    );
    if (!mounted) return;
    setState(() {
      commentsByEntry = nextComments;
      heartsByEntry = nextHearts;
      memberReads = nextReads;
      interactionsLoading = false;
    });
  }

  String? _seenLabel(SharedEntry entry) {
    final uid = CloudSyncService.instance.userId;
    if (uid == null || entry.updatedBy != uid || entry.updatedAt == null) {
      return null;
    }
    final seenCount = memberReads.entries
        .where(
          (read) =>
              read.key != uid &&
              !read.value.isBefore(entry.updatedAt!.toUtc()),
        )
        .length;
    if (seenCount == 0) return null;
    return seenCount == 1 ? 'Visto' : 'Visto da $seenCount';
  }

  Future<void> _toggleHeart(SharedEntry entry) async {
    final uid =
        widget.store.activeAccountId ?? CloudSyncService.instance.userId;
    if (uid == null) {
      _message('Accedi al cloud almeno una volta per usare le reazioni.');
      return;
    }

    final mine = heartsByEntry[entry.id]?.contains(uid) ?? false;
    setState(() {
      final hearts = heartsByEntry.putIfAbsent(entry.id, () => <String>{});
      if (mine) {
        hearts.remove(uid);
      } else {
        hearts.add(uid);
      }
    });

    await widget.store.enqueueSharedHeart(
      spaceId: widget.space.id,
      entryId: entry.id,
      active: !mine,
    );

    if (CloudSyncService.instance.signedIn) {
      await widget.store.flushSharedInteractionOperations(
        spaceId: widget.space.id,
      );
    }
    await _saveInteractionCache(
      commentsByEntry,
      heartsByEntry,
      memberReads,
    );
  }

  Future<void> _deleteComment(SharedEntryComment comment) async {
    await widget.store.enqueueSharedCommentDelete(
      spaceId: widget.space.id,
      entryId: comment.entryId,
      commentId: comment.id,
    );
    setState(() {
      commentsByEntry[comment.entryId]
          ?.removeWhere((candidate) => candidate.id == comment.id);
    });
    if (CloudSyncService.instance.signedIn) {
      await widget.store.flushSharedInteractionOperations(
        spaceId: widget.space.id,
      );
    }
    await _saveInteractionCache(
      commentsByEntry,
      heartsByEntry,
      memberReads,
    );
  }

  Future<void> _openComments(SharedEntry entry) async {
    if (widget.store.activeAccountId == null) {
      _message('Accedi al cloud almeno una volta per commentare.');
      return;
    }

    final controller = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final comments =
              commentsByEntry[entry.id] ?? const <SharedEntryComment>[];
          final uid = CloudSyncService.instance.userId;
          return Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              0,
              16,
              MediaQuery.viewInsetsOf(sheetContext).bottom + 16,
            ),
            child: SizedBox(
              height: MediaQuery.sizeOf(sheetContext).height * 0.68,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 19,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${comments.length} commenti',
                    style: Theme.of(sheetContext).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: comments.isEmpty
                        ? const Center(
                            child: Text(
                              AnnaStrings.of(context).d3('noComments'),
                            ),
                          )
                        : ListView.builder(
                            itemCount: comments.length,
                            itemBuilder: (context, index) {
                              final comment = comments[index];
                              final mine = comment.userId == uid;
                              final author = mine
                                  ? 'Tu'
                                  : (comment.authorName.trim().isEmpty
                                      ? AnnaStrings.of(context).d3('otherPerson')
                                      : comment.authorName.trim());
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  child: Text(
                                    author.substring(0, 1).toUpperCase(),
                                  ),
                                ),
                                title: Text(
                                  author,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                subtitle: Text(
                                  '${comment.body}\n${DateFormat('d MMM · HH:mm', AnnaStrings.intlLocale(context)).format(comment.createdAt.toLocal())}',
                                ),
                                isThreeLine: true,
                                trailing: mine
                                    ? IconButton(
                                        tooltip: AnnaStrings.of(context).d3('deleteComment'),
                                        onPressed: () async {
                                          await _deleteComment(comment);
                                          if (sheetContext.mounted) {
                                            setSheetState(() {});
                                          }
                                        },
                                        icon: const Icon(Icons.delete_outline),
                                      )
                                    : null,
                              );
                            },
                          ),
                  ),
                  const Divider(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          minLines: 1,
                          maxLines: 4,
                          maxLength: 500,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: AnnaStrings.of(context).d3('writeComment'),
                            border: OutlineInputBorder(),
                            counterText: '',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        tooltip: AnnaStrings.of(context).d3('send'),
                        onPressed: () async {
                          final text = controller.text.trim();
                          if (text.isEmpty) return;
                          try {
                            final author = widget
                                    .store.preferences.displayName.trim().isEmpty
                                ? 'Utente'
                                : widget.store.preferences.displayName.trim();
                            final comment =
                                await widget.store.enqueueSharedComment(
                              spaceId: widget.space.id,
                              entryId: entry.id,
                              authorName: author,
                              body: text,
                            );
                            controller.clear();
                            setState(() {
                              commentsByEntry
                                  .putIfAbsent(entry.id, () => [])
                                  .add(comment);
                            });
                            if (CloudSyncService.instance.signedIn) {
                              await widget.store
                                  .flushSharedInteractionOperations(
                                spaceId: widget.space.id,
                              );
                            }
                            commentsByEntry[entry.id]?.sort(
                              (a, b) =>
                                  a.createdAt.compareTo(b.createdAt),
                            );
                            await _saveInteractionCache(
                              commentsByEntry,
                              heartsByEntry,
                              memberReads,
                            );
                            if (sheetContext.mounted) {
                              setSheetState(() {});
                            }
                            if (!CloudSyncService.instance.signedIn) {
                              _message(
                                AnnaStrings.of(context).d3('commentOffline'),
                              );
                            }
                          } catch (_) {
                            _message('Commento non salvato.');
                          }
                        },
                        icon: const Icon(Icons.send_outlined),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    controller.dispose();
  }

  List<SharedEntry> get _selectedEntries {
    final selectedEntries = entries
        .where(
          (entry) =>
              entry.type != SharedEntryType.shopping &&
              AgendaStore.sameDay(entry.date, selected),
        )
        .toList();
    selectedEntries.sort((a, b) {
      final aMinutes =
          a.start == null ? -1 : a.start!.hour * 60 + a.start!.minute;
      final bMinutes =
          b.start == null ? -1 : b.start!.hour * 60 + b.start!.minute;
      final time = bMinutes.compareTo(aMinutes);
      if (time != 0) return time;

      final aUpdated =
          a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
      final bUpdated =
          b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
      return bUpdated.compareTo(aUpdated);
    });
    return selectedEntries;
  }

  List<SharedEntry> get _feedEntries {
    final feed = entries
        .where((entry) => entry.type != SharedEntryType.shopping)
        .toList();
    feed.sort((a, b) {
      final aUpdated = a.updatedAt ?? a.date;
      final bUpdated = b.updatedAt ?? b.date;
      final updated = bUpdated.compareTo(aUpdated);
      if (updated != 0) return updated;

      final aMinutes =
          a.start == null ? -1 : a.start!.hour * 60 + a.start!.minute;
      final bMinutes =
          b.start == null ? -1 : b.start!.hour * 60 + b.start!.minute;
      return bMinutes.compareTo(aMinutes);
    });
    return feed;
  }

  String _editorLabel(SharedEntry entry) {
    final explicit = entry.editorName.trim();
    if (explicit.isNotEmpty) {
      if (explicit == widget.store.preferences.displayName.trim()) {
        return 'Modificato da te';
      }
      return 'Modificato da $explicit';
    }
    if (entry.updatedBy != null &&
        entry.updatedBy == CloudSyncService.instance.userId) {
      return 'Modificato da te';
    }
    if (entry.updatedBy != null) return AnnaStrings.of(context).d3('editedByOther');
    return '';
  }

  SharedEntry _withLocalMetadata(
    SharedEntry entry,
    DateTime revision,
  ) =>
      entry.copyWith(
        editorName: widget.store.preferences.displayName.trim().isEmpty
            ? 'Utente'
            : widget.store.preferences.displayName.trim(),
        updatedBy: CloudSyncService.instance.userId,
        updatedAt: revision,
      );

  String? get _currentSharedUserId =>
      CloudSyncService.instance.userId ?? widget.store.activeAccountId;

  bool _canEditSharedEntry(SharedEntry entry) =>
      entry.canEditFor(_currentSharedUserId);

  bool _canManageSharedPermissions(SharedEntry entry) =>
      entry.isEditOwner(_currentSharedUserId);

  SharedEntry _permissionAwareNewEntry(SharedEntry entry) {
    if (!entry.supportsEditPermissions || entry.editOwnerId.isNotEmpty) {
      return entry;
    }
    return entry.copyWith(editOwnerId: _currentSharedUserId ?? '');
  }

  Future<void> _persistSharedEntry(
    SharedEntry result, {
    bool permissionChange = false,
  }) async {
    final currentIndex = entries.indexWhere((entry) => entry.id == result.id);
    final current = currentIndex < 0 ? null : entries[currentIndex];

    if (current != null && !_canEditSharedEntry(current)) {
      _message(AnnaStrings.of(context).d3('readOnlyMemory'));
      return;
    }

    var normalized = _permissionAwareNewEntry(result);
    if (current != null && !permissionChange) {
      normalized = normalized.copyWith(
        membersCanEdit: current.membersCanEdit,
        editOwnerId: current.editOwnerId,
      );
    }

    final revision = DateTime.now().toUtc();
    final updated = _withLocalMetadata(normalized, revision);
    final index = entries.indexWhere((entry) => entry.id == updated.id);
    setState(() {
      if (index < 0) {
        entries.add(updated);
      } else {
        entries[index] = updated;
      }
      pendingIds.add(updated.id);
    });
    await widget.store.enqueueSharedUpsert(
      spaceId: widget.space.id,
      entry: updated,
      updatedAt: revision,
    );
    await _saveCache();

    if (CloudSyncService.instance.signedIn) {
      await _flushPending();
      await _refresh(silent: true);
    } else {
      _message(AnnaStrings.of(context).d3('savedOffline'));
    }
  }

  Future<void> _setSharedEditPermission(SharedEntry entry) async {
    if (!_canManageSharedPermissions(entry)) {
      _message(AnnaStrings.of(context).d3('permissionsOnlyCreator'));
      return;
    }

    final next = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AnnaStrings.of(context).d3('whoCanEdit')),
        content: RadioGroup<bool>(
          groupValue: entry.membersCanEdit,
          onChanged: (value) {
            if (value != null) Navigator.pop(dialogContext, value);
          },
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<bool>(
                value: true,
                title: Text(AnnaStrings.of(context).d3('everyoneInSpace')),
                subtitle: Text('I membri di Noi ♡ possono modificare questo ricordo.'),
              ),
              RadioListTile<bool>(
                value: false,
                title: Text(AnnaStrings.of(context).d3('onlyMe')),
                subtitle: Text('Gli altri possono vedere, commentare e reagire.'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AnnaStrings.of(context).cancel),
          ),
        ],
      ),
    );
    if (next == null || next == entry.membersCanEdit) return;
    await _persistSharedEntry(
      entry.copyWith(membersCanEdit: next),
      permissionChange: true,
    );
  }

  Future<void> _viewReadOnlySharedEntry(
    BuildContext context,
    SharedEntry entry,
  ) async {
    if (entry.type == SharedEntryType.photo) {
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => SharedPhotoViewerScreen(
            space: widget.space,
            entry: entry,
          ),
        ),
      );
      return;
    }
    if (entry.type == SharedEntryType.sketch) {
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => SharedSketchViewerScreen(
            space: widget.space,
            entry: entry,
          ),
        ),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(entry.title.trim().isEmpty ? AnnaStrings.of(context).d3('note') : entry.title),
        content: SingleChildScrollView(
          child: SelectableText(
            entry.note.trim().isEmpty ? entry.title : entry.note,
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AnnaStrings.of(context).close),
          ),
        ],
      ),
    );
  }

  Future<void> _edit([
    SharedEntry? existing,
    SharedEntryType? initialType,
  ]) async {
    if (existing != null && !_canEditSharedEntry(existing)) {
      await _viewReadOnlySharedEntry(context, existing);
      return;
    }
    if (widget.store.activeAccountId == null) {
      _message(
        AnnaStrings.of(context).d3('cloudRequiredShared'),
      );
      return;
    }

    if (existing?.type == SharedEntryType.photo) {
      await _addSharedPhoto(existing);
      return;
    }
    if (existing?.type == SharedEntryType.sketch) {
      await _addSharedSketch(existing);
      return;
    }

    final result = await _openSharedEntryEditor(
      context,
      initialDate: selected,
      existing: existing,
      initialType: initialType,
    );
    if (result == null) return;
    await _persistSharedEntry(
      existing == null
          ? result
          : result.copyWith(memoryPinned: existing.memoryPinned),
    );
  }


  Future<void> _addSharedNote([SharedEntry? existing]) async {
    final value = await showDiaryNoteEditor(
      context,
      initialText: existing?.note.isNotEmpty == true
          ? existing!.note
          : existing?.title ?? '',
      editing: existing != null,
    );
    if (value == null || value.isEmpty) return;

    final compactTitle = value
        .split(RegExp(r'\s+'))
        .take(7)
        .join(' ')
        .trim();

    await _persistSharedEntry(
      SharedEntry(
        id: existing?.id ?? const Uuid().v4(),
        type: SharedEntryType.note,
        title: compactTitle.isEmpty ? AnnaStrings.of(context).d3('note') : compactTitle,
        note: value,
        date: existing?.date ?? selected,
        createdAt:
            existing?.createdAt ?? existing?.updatedAt ?? DateTime.now(),
        memoryPinned: existing?.memoryPinned ?? false,
        membersCanEdit: existing?.membersCanEdit ?? true,
        editOwnerId: existing?.editOwnerId ?? (_currentSharedUserId ?? ''),
      ),
    );
  }

  Future<void> _editSharedPhotoCaption(SharedEntry entry) async {
    if (!_canEditSharedEntry(entry)) {
      _message(AnnaStrings.of(context).d3('readOnlyPhoto'));
      return;
    }
    final value = await showDiaryCaptionEditor(
      context,
      initialText: entry.note,
    );
    if (value == null) return;
    await _persistSharedEntry(entry.copyWith(note: value));
  }

  Future<void> _addSharedPhoto([SharedEntry? existing]) async {
    if (existing != null && !_canEditSharedEntry(existing)) {
      await _viewReadOnlySharedEntry(context, existing);
      return;
    }
    if (sharedPhotoBusy) return;
    if (widget.store.activeAccountId == null) {
      _message(
        AnnaStrings.of(context).d3('cloudPhotoRequired'),
      );
      return;
    }

    final source = await _chooseDiaryImageSource(context);
    if (source == null || !mounted) return;

    setState(() => sharedPhotoBusy = true);
    try {
      final fullBytes = await _pickCompressedDiaryImageBytes(
        source,
        maxSide: 1920,
        quality: 84,
        fallbackMaxSide: 1440,
        fallbackQuality: 78,
      );
      if (fullBytes == null || !mounted) return;

      String? caption = existing?.note;
      if (existing == null) {
        caption = await showDiaryCaptionEditor(
          context,
          adding: true,
        );
        if (caption == null) return;
      }

      final thumbnailBytes = await _diaryThumbnailBytes(fullBytes);
      final mediaAssetId = await MediaAssetStore.instance.put(fullBytes);
      final thumbnailAssetId =
          await MediaAssetStore.instance.put(thumbnailBytes);

      final entryId = existing?.id ?? const Uuid().v4();
      final localPreview = SharedEntry(
        id: entryId,
        type: SharedEntryType.photo,
        title: existing?.title.trim().isNotEmpty == true
            ? existing!.title
            : AnnaStrings.of(context).d3('photo'),
        note: caption ?? '',
        date: existing?.date ?? selected,
        createdAt:
            existing?.createdAt ?? existing?.updatedAt ?? DateTime.now(),
        // While a replacement is pending, do not display the previous
        // remote full-resolution image over the new local preview.
        mediaPath: '',
        mediaThumbnailAssetId: thumbnailAssetId,
        memoryPinned: existing?.memoryPinned ?? false,
        membersCanEdit: existing?.membersCanEdit ?? true,
        editOwnerId: existing?.editOwnerId ?? (_currentSharedUserId ?? ''),
      );

      final revision = DateTime.now().toUtc();
      final preview = _withLocalMetadata(localPreview, revision);
      setState(() {
        entries.removeWhere((entry) => entry.id == entryId);
        entries.add(preview);
        pendingIds.add(entryId);
      });
      await _saveCache();

      await widget.store.enqueueSharedMediaUpload(
        SharedMediaPendingUpload(
          id: const Uuid().v4(),
          spaceId: widget.space.id,
          entryId: entryId,
          title: localPreview.title,
          note: localPreview.note,
          date: localPreview.date,
          mediaAssetId: mediaAssetId,
          thumbnailAssetId: thumbnailAssetId,
          membersCanEdit: localPreview.membersCanEdit,
          editOwnerId: localPreview.editOwnerId,
          oldMediaPath: existing?.mediaPath ?? '',
          createdAt: localPreview.createdAt ?? revision,
        ),
      );

      if (CloudSyncService.instance.signedIn) {
        await widget.store.flushSharedMediaUploads(
          spaceId: widget.space.id,
        );
        await _refresh(silent: true);
      } else {
        _message(
          AnnaStrings.of(context).d3('photoSavedLocal'),
        );
      }
    } catch (_) {
      _message(
        AnnaStrings.of(context).d3('photoRetryUpload'),
      );
    } finally {
      if (mounted) setState(() => sharedPhotoBusy = false);
    }
  }

  Future<void> _addSharedSketch([SharedEntry? existing]) async {
    if (existing != null && !_canEditSharedEntry(existing)) {
      await _viewReadOnlySharedEntry(context, existing);
      return;
    }
    final initialPages = existing?.sketchPages.isNotEmpty == true
        ? existing!.sketchPages
        : [DiarySketchPage(id: const Uuid().v4())];

    final pages = await Navigator.push<List<DiarySketchPage>>(
      context,
      MaterialPageRoute(
        builder: (_) => DiarySketchbookScreen(initialPages: initialPages),
      ),
    );
    if (pages == null || pages.isEmpty || !mounted) return;

    await _persistSharedEntry(
      SharedEntry(
        id: existing?.id ?? const Uuid().v4(),
        type: SharedEntryType.sketch,
        title: existing?.title.trim().isNotEmpty == true
            ? existing!.title
            : 'Sketch',
        note: existing?.note ?? '',
        date: existing?.date ?? selected,
        createdAt:
            existing?.createdAt ?? existing?.updatedAt ?? DateTime.now(),
        sketchPages: pages,
        memoryPinned: existing?.memoryPinned ?? false,
        membersCanEdit: existing?.membersCanEdit ?? true,
        editOwnerId: existing?.editOwnerId ?? (_currentSharedUserId ?? ''),
      ),
    );
  }

  Future<void> _createSharedContent() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  AnnaStrings.of(context).d3('sharedDiary'),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 19,
                  ),
                ),
                subtitle: Text(
                  AnnaStrings.of(context).d3('sameDiaryTools'),
                ),
              ),
              ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.sticky_note_2_outlined),
                ),
                title: Text(AnnaStrings.of(context).d3('note')),
                subtitle: Text(AnnaStrings.of(context).d3('sharedThought')),
                onTap: () => Navigator.pop(sheetContext, 'note'),
              ),
              ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.draw_outlined),
                ),
                title: Text('Sketch'),
                subtitle: Text(
                  AnnaStrings.of(context).d3('sameSketchbook'),
                ),
                onTap: () => Navigator.pop(sheetContext, 'sketch'),
              ),
              ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.add_photo_alternate_outlined),
                ),
                title: Text(AnnaStrings.of(context).d3('photo')),
                subtitle: Text('Fotocamera o galleria + didascalia'),
                onTap: () => Navigator.pop(sheetContext, 'photo'),
              ),
              const Divider(height: 24),
              ListTile(
                dense: true,
                title: Text(
                  AnnaStrings.of(context).d3('sharedAgenda'),
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.event_outlined),
                ),
                title: Text(AnnaStrings.of(context).d3('appointment')),
                onTap: () => Navigator.pop(sheetContext, 'appointment'),
              ),
              ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.check_circle_outline),
                ),
                title: Text(AnnaStrings.of(context).d3('toDo')),
                onTap: () => Navigator.pop(sheetContext, 'task'),
              ),
              ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.shopping_cart_outlined),
                ),
                title: Text(AnnaStrings.of(context).d3('shoppingList')),
                subtitle: Text(
                  AnnaStrings.of(context).d3('openShopping'),
                ),
                onTap: () => Navigator.pop(sheetContext, 'shopping'),
              ),
            ],
          ),
        ),
      ),
    );
    if (action == null || !mounted) return;

    switch (action) {
      case 'note':
        await _addSharedNote();
        return;
      case 'photo':
        await _addSharedPhoto();
        return;
      case 'sketch':
        await _addSharedSketch();
        return;
      case 'appointment':
        await _edit(null, SharedEntryType.appointment);
        return;
      case 'task':
        await _edit(null, SharedEntryType.task);
        return;
      case 'shopping':
        await _openSharedShopping();
        return;
    }
  }

  Widget _sharedDiaryCard(BuildContext context) {
    final blocks = entries
        .where(
          (entry) =>
              AgendaStore.sameDay(entry.date, selected) &&
              (entry.type == SharedEntryType.note ||
                  entry.type == SharedEntryType.photo ||
                  entry.type == SharedEntryType.sketch),
        )
        .toList()
      ..sort(
        (a, b) => (b.createdAt ?? b.updatedAt ?? b.date)
            .compareTo(a.createdAt ?? a.updatedAt ?? a.date),
      );

    return DiaryComposerSection(
      title: AnnaStrings.of(context).d3('ourDiary'),
      subtitle: AnnaStrings.of(context).d3('sharedDiarySubtitle'),
      memoriesLabel: AnnaStrings.of(context).memories,
      emptyText: AnnaStrings.of(context).d3('sharedDiaryBuild'),
      onMemories: _openSharedMemories,
      onAddNote: () => _addSharedNote(),
      onAddSketch: () => _addSharedSketch(),
      onAddPhoto: () => _addSharedPhoto(),
      photoBusy: sharedPhotoBusy,
      children: blocks
          .map(
            (entry) => _sharedEntryCard(
              context,
              entry,
              showDate: false,
            ),
          )
          .toList(growable: false),
    );
  }

  Future<void> _toggleDone(SharedEntry entry) async {
    final revision = DateTime.now().toUtc();
    final updated = _withLocalMetadata(
      entry.copyWith(done: !entry.done),
      revision,
    );
    final index = entries.indexWhere((candidate) => candidate.id == entry.id);
    if (index >= 0) {
      setState(() {
        entries[index] = updated;
        pendingIds.add(updated.id);
      });
    }
    await widget.store.enqueueSharedUpsert(
      spaceId: widget.space.id,
      entry: updated,
      updatedAt: revision,
    );
    await _saveCache();
    if (CloudSyncService.instance.signedIn) {
      await _flushPending();
    }
  }

  Future<void> _toggleMemoryPin(SharedEntry entry) async {
    if (entry.type != SharedEntryType.appointment &&
        entry.type != SharedEntryType.task) {
      return;
    }

    final next = entry.copyWith(memoryPinned: !entry.memoryPinned);
    await _persistSharedEntry(next);
    if (!mounted) return;
    _message(
      next.memoryPinned
          ? 'Aggiunto a I nostri ricordi.'
          : 'Rimosso da I nostri ricordi.',
    );
  }

  Future<void> _openSharedShopping() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => ShoppingListScreen(
          store: widget.store,
          sharedSpace: widget.space,
        ),
      ),
    );
    if (mounted) {
      await _refresh(silent: true);
    }
  }

  Future<void> _openSharedMemories() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => SharedMemoriesScreen(
          store: widget.store,
          space: widget.space,
          entriesProvider: () => List<SharedEntry>.from(entries),
          commentsProvider: () => commentsByEntry,
          heartsProvider: () => heartsByEntry,
          readsProvider: () => memberReads,
          onRefresh: () => _refresh(silent: true),
          onToggleMemory: _toggleMemoryPin,
        ),
      ),
    );
    if (mounted) {
      await _refresh(silent: true);
    }
  }

  Future<void> _delete(SharedEntry entry) async {
    if (entry.supportsEditPermissions && !_canEditSharedEntry(entry)) {
      _message(AnnaStrings.of(context).d3('readOnlyMemory'));
      return;
    }
    final isDiaryContent =
        entry.type == SharedEntryType.note ||
        entry.type == SharedEntryType.photo ||
        entry.type == SharedEntryType.sketch;
    final confirmed = isDiaryContent
        ? await confirmDiaryContentDelete(context)
        : await showDialog<bool>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: Text(AnnaStrings.of(context).d3('deleteShared')),
                content: Text(entry.title),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: Text(AnnaStrings.of(context).cancel),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: Text(AnnaStrings.of(context).delete),
                  ),
                ],
              ),
            ) ??
            false;
    if (!confirmed) return;

    final revision = DateTime.now().toUtc();
    setState(() {
      entries.removeWhere((candidate) => candidate.id == entry.id);
      pendingIds.add(entry.id);
    });
    await widget.store.enqueueSharedDelete(
      spaceId: widget.space.id,
      entityId: entry.id,
      updatedAt: revision,
      mediaPath:
          entry.type == SharedEntryType.photo ? entry.mediaPath : '',
    );
    await _saveCache();
    if (CloudSyncService.instance.signedIn) {
      await _flushPending();
      await _refresh(silent: true);
    } else {
      _message(AnnaStrings.of(context).d3('deleteSavedOffline'));
    }
  }

  Future<void> _invite() async {
    final prefs = await widget.store._localState();
    final owner = CloudSyncService.instance.userId ?? 'unknown';
    final cacheKey = 'shared_invite_v2_${owner}_${widget.space.id}';

    SpaceInviteDetails? invite;
    final cachedRaw = prefs.getString(cacheKey);
    if (cachedRaw != null) {
      try {
        final cached = SpaceInviteDetails.fromJson(
          Map<String, dynamic>.from(jsonDecode(cachedRaw) as Map),
        );
        if (!cached.expired) invite = cached;
      } catch (_) {}
    }

    try {
      invite = await CloudSyncService.instance
          .createOrGetSpaceInvite(widget.space.id);
      await prefs.setString(cacheKey, jsonEncode(invite.toJson()));
    } catch (_) {
      if (invite == null) {
        _message(AnnaStrings.of(context).d3('inviteCodeLoadFailed'));
        return;
      }
    }

    if (!mounted) return;
    var current = invite;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final remaining = current.expiresAt.difference(DateTime.now());
          final hours = remaining.inHours.clamp(0, 24);
          final minutes = (remaining.inMinutes % 60).clamp(0, 59);

          return AlertDialog(
            title: Text(AnnaStrings.of(context).d3('connectionCode')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(AnnaStrings.of(context).d3('code24h')),
                const SizedBox(height: 18),
                SelectableText(
                  current.code,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Scade tra ${hours}h ${minutes}m · '
                  '${current.usesCount} utilizzi',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () async {
                    try {
                      final next = await CloudSyncService.instance
                          .regenerateSpaceInvite(widget.space.id);
                      await prefs.setString(
                        cacheKey,
                        jsonEncode(next.toJson()),
                      );
                      setDialogState(() => current = next);
                    } catch (_) {
                      if (dialogContext.mounted) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(
                            content: Text(
                              AnnaStrings.of(context).d3('generateCodeFailed'),
                            ),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  label: Text(AnnaStrings.of(context).d3('generateNewCode')),
                ),
              ],
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(AnnaStrings.of(context).close),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openSharedPasswords() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SharedPasswordsScreen(space: widget.space),
      ),
    );
  }

  Future<void> _openMembers() async {
    List<SharedSpaceMember> members;
    try {
      members = await CloudSyncService.instance
          .listSharedSpaceMembers(widget.space.id);
    } catch (_) {
      _message(AnnaStrings.of(context).d3('loadPeopleFailed'));
      return;
    }
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Persone · ${members.length}',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        content: SizedBox(
          width: 440,
          child: members.isEmpty
              ? Text(AnnaStrings.of(context).d3('noPeople'))
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: members.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final member = members[index];
                    final isMe =
                        member.userId == CloudSyncService.instance.userId;
                    final initial = member.displayName.trim().isEmpty
                        ? '?'
                        : member.displayName.trim()[0].toUpperCase();
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(child: Text(initial)),
                      title: Text(
                        isMe
                            ? '${member.displayName} · Tu'
                            : member.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        member.isOwner ? 'Proprietario' : 'Membro',
                      ),
                      trailing: widget.space.isOwner &&
                              !member.isOwner &&
                              !isMe
                          ? IconButton(
                              tooltip: AnnaStrings.of(context).d3('removeFromSpace'),
                              icon: const Icon(Icons.person_remove_outlined),
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                      context: dialogContext,
                                      builder: (confirmContext) => AlertDialog(
                                        title: Text(
                                          AnnaStrings.of(context).d3('removePersonTitle'),
                                        ),
                                        content: Text(
                                          AnnaStrings.of(context).d3('removePersonBody'),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(
                                              confirmContext,
                                              false,
                                            ),
                                            child: Text(AnnaStrings.of(context).cancel),
                                          ),
                                          FilledButton(
                                            onPressed: () => Navigator.pop(
                                              confirmContext,
                                              true,
                                            ),
                                            child: Text(AnnaStrings.of(context).d3('remove')),
                                          ),
                                        ],
                                      ),
                                    ) ??
                                    false;
                                if (!confirmed) return;
                                try {
                                  await CloudSyncService.instance
                                      .removeSharedSpaceMember(
                                    widget.space.id,
                                    member.userId,
                                  );
                                  if (dialogContext.mounted) {
                                    Navigator.pop(dialogContext);
                                  }
                                  if (mounted) {
                                    _message(
                                      AnnaStrings.of(context).d3Format(
                                        'personRemoved',
                                        {'name': member.displayName},
                                      ),
                                    );
                                    await _openMembers();
                                  }
                                } catch (_) {
                                  if (mounted) {
                                    _message(
                                      AnnaStrings.of(context).d3('removePersonFailed'),
                                    );
                                  }
                                }
                              },
                            )
                          : null,
                    );
                  },
                ),
        ),
        actions: [
          if (widget.space.isOwner)
            TextButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                _invite();
              },
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: Text(AnnaStrings.of(context).d3('invite')),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AnnaStrings.of(context).close),
          ),
        ],
      ),
    );
  }

  Future<void> _leaveOrDelete() async {
    final owner = widget.space.isOwner;
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(owner ? AnnaStrings.of(context).d3('deleteSpaceTitle') : AnnaStrings.of(context).d3('leaveSpaceTitle')),
            content: Text(
              owner
                  ? AnnaStrings.of(context).d3('deleteSpaceBody')
                  : AnnaStrings.of(context).d3('leaveSpaceBody'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(AnnaStrings.of(context).cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(
                  owner ? AnnaStrings.of(context).d3('deleteForEveryone') : AnnaStrings.of(context).d3('leaveOnlyMe'),
                ),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;

    try {
      if (owner) {
        final cloud = CloudSyncService.instance;
        for (final entry in entries) {
          if (entry.type == SharedEntryType.photo &&
              entry.mediaPath.isNotEmpty) {
            try {
              await cloud.deleteSharedMedia(entry.mediaPath);
            } catch (_) {}
          }
        }
        await cloud.deleteSharedSpace(widget.space.id);
      } else {
        await CloudSyncService.instance.leaveSharedSpace(widget.space.id);
      }
      await SharedPasswordService.instance.revokeLocalSpace(
        widget.space.id,
      );
      final prefs = await widget.store._localState();
      await prefs.remove(_cacheKey);
      await prefs.remove(_pendingKey);
      await prefs.remove(_interactionCacheKey);
      await prefs.remove(
        widget.store.sharedInteractionPendingStorageKey(widget.space.id),
      );
      await prefs.remove(
        widget.store.sharedMediaPendingStorageKey(widget.space.id),
      );
      final ownerId = CloudSyncService.instance.userId ?? 'unknown';
      await prefs.remove(
        'shared_invite_v2_${ownerId}_${widget.space.id}',
      );
      await widget.store.refreshPendingSharedCount(notify: false);
      await widget.store.refreshPendingSharedInteractionCount(notify: false);
      await widget.store.refreshPendingSharedMediaCount(notify: false);
      await widget.store.refreshSharedAgendaCache(pullRemote: true);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      _message('Operazione non riuscita.');
    }
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Widget _sharedInteractionFooter(
    SharedEntry entry, {
    required Set<String> hearts,
    required List<SharedEntryComment> comments,
    required bool likedByMe,
    required String? seen,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 2, 8, 4),
      child: Row(
        children: [
          TextButton.icon(
            onPressed:
                interactionsLoading ? null : () => _toggleHeart(entry),
            icon: Icon(
              likedByMe ? Icons.favorite : Icons.favorite_border,
              color: likedByMe
                  ? Theme.of(context).colorScheme.error
                  : null,
              size: 20,
            ),
            label: Text(hearts.isEmpty ? 'Mi piace' : '${hearts.length}'),
          ),
          TextButton.icon(
            onPressed: () => _openComments(entry),
            icon: const Icon(Icons.chat_bubble_outline, size: 19),
            label: Text(
              comments.isEmpty ? 'Commenta' : '${comments.length}',
            ),
          ),
          const Spacer(),
          if (seen != null)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Row(
                children: [
                  const Icon(Icons.done_all, size: 17),
                  const SizedBox(width: 4),
                  Text(
                    seen,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _sharedDiaryFooter(
    SharedEntry entry, {
    required Set<String> hearts,
    required List<SharedEntryComment> comments,
    required bool likedByMe,
    required String? seen,
  }) {
    final canManage = _canManageSharedPermissions(entry);
    final restricted = !entry.membersCanEdit && entry.editOwnerId.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (restricted || canManage)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
            child: Row(
              children: [
                Icon(
                  restricted ? Icons.lock_outline : Icons.group_outlined,
                  size: 18,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    restricted
                        ? (_canEditSharedEntry(entry)
                            ? 'Solo tu puoi modificare'
                            : AnnaStrings.of(context).d3('readOnlyAuthor'))
                        : AnnaStrings.of(context).d3('editableEveryone'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                if (canManage)
                  TextButton(
                    onPressed: () => _setSharedEditPermission(entry),
                    child: Text(AnnaStrings.of(context).d3('permissions')),
                  ),
              ],
            ),
          ),
        _sharedInteractionFooter(
          entry,
          hearts: hearts,
          comments: comments,
          likedByMe: likedByMe,
          seen: seen,
        ),
      ],
    );
  }

  Widget _sharedDiaryContentCard(
    BuildContext context,
    SharedEntry entry, {
    required bool showDate,
    required bool pending,
    required Set<String> hearts,
    required List<SharedEntryComment> comments,
    required bool likedByMe,
    required String? seen,
    required String editor,
  }) {
    final kind = switch (entry.type) {
      SharedEntryType.note => DiaryContentKind.note,
      SharedEntryType.photo => DiaryContentKind.photo,
      SharedEntryType.sketch => DiaryContentKind.sketch,
      _ => throw StateError('not_a_diary_entry'),
    };

    final meta = <String>[
      kind.label,
      if (showDate)
        _cap(DateFormat('EEE d MMM', 'it_IT').format(entry.date)),
      if (editor.isNotEmpty) editor,
      if (entry.updatedAt != null)
        'Aggiornato ${DateFormat('HH:mm', 'it_IT').format(entry.updatedAt!.toLocal())}',
      if (pending) AnnaStrings.of(context).d3('pendingSync'),
    ];

    final canEdit = _canEditSharedEntry(entry);
    final VoidCallback openEntry = canEdit
        ? switch (entry.type) {
            SharedEntryType.note => () => _addSharedNote(entry),
            SharedEntryType.photo => () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SharedPhotoViewerScreen(
                      space: widget.space,
                      entry: entry,
                    ),
                  ),
                ),
            SharedEntryType.sketch => () => _addSharedSketch(entry),
            _ => () {},
          }
        : () => _viewReadOnlySharedEntry(context, entry);

    final Widget? preview = switch (entry.type) {
      SharedEntryType.photo
          when entry.mediaThumbnailAssetId.isNotEmpty ||
              entry.mediaThumbnailBase64.isNotEmpty =>
        DiaryMediaImage(
          assetId: entry.mediaThumbnailAssetId,
          fallbackBase64: entry.mediaThumbnailBase64,
          fit: BoxFit.cover,
          cacheWidth: 720,
        ),
      SharedEntryType.sketch when entry.sketchPages.isNotEmpty =>
        DiarySketchPagePreview(page: entry.sketchPages.first),
      _ => null,
    };

    final title = switch (entry.type) {
      SharedEntryType.note =>
        entry.note.trim().isEmpty ? entry.title : entry.note.trim(),
      SharedEntryType.photo =>
        entry.note.trim().isEmpty ? AnnaStrings.of(context).d3('photoOfDay') : entry.note.trim(),
      SharedEntryType.sketch => entry.sketchPages.length <= 1
          ? 'Sketch'
          : 'Sketch · ${entry.sketchPages.length} pagine',
      _ => entry.title,
    };

    return DiaryContentCard(
      kind: kind,
      title: title,
      subtitle: meta.join(' · '),
      preview: preview,
      onOpen: openEntry,
      onEdit: canEdit && kind != DiaryContentKind.photo ? openEntry : null,
      onEditCaption: canEdit && kind == DiaryContentKind.photo
          ? () => _editSharedPhotoCaption(entry)
          : null,
      onReplacePhoto: canEdit && kind == DiaryContentKind.photo
          ? () => _addSharedPhoto(entry)
          : null,
      onDelete: canEdit ? () => _delete(entry) : null,
      statusIcon:
          pending ? const Icon(Icons.schedule_outlined, size: 20) : null,
      footer: _sharedDiaryFooter(
        entry,
        hearts: hearts,
        comments: comments,
        likedByMe: likedByMe,
        seen: seen,
      ),
    );
  }

  Widget _sharedEntryCard(
    BuildContext context,
    SharedEntry entry, {
    bool showDate = false,
  }) {
    final editor = _editorLabel(entry);
    final pending = pendingIds.contains(entry.id);
    final uid = CloudSyncService.instance.userId;
    final hearts = heartsByEntry[entry.id] ?? const <String>{};
    final likedByMe = uid != null && hearts.contains(uid);
    final comments = commentsByEntry[entry.id] ?? const <SharedEntryComment>[];
    final seen = _seenLabel(entry);

    if (entry.type == SharedEntryType.note ||
        entry.type == SharedEntryType.photo ||
        entry.type == SharedEntryType.sketch) {
      return _sharedDiaryContentCard(
        context,
        entry,
        showDate: showDate,
        pending: pending,
        hearts: hearts,
        comments: comments,
        likedByMe: likedByMe,
        seen: seen,
        editor: editor,
      );
    }

    final details = <String>[
      if (showDate)
        _cap(DateFormat('EEE d MMM', 'it_IT').format(entry.date)),
      if (entry.start != null) formatTime(entry.start!),
      if (entry.note.isNotEmpty) entry.note,
      if (editor.isNotEmpty) editor,
      if (entry.memoryPinned) AnnaStrings.of(context).d3('inMemories'),
      if (entry.updatedAt != null)
        'Aggiornato ${DateFormat('HH:mm', 'it_IT').format(entry.updatedAt!.toLocal())}',
      if (pending) AnnaStrings.of(context).d3('pendingSync'),
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            leading: entry.type == SharedEntryType.task
                ? Checkbox(
                    value: entry.done,
                    onChanged: (_) => _toggleDone(entry),
                  )
                : CircleAvatar(child: Icon(entry.type.icon)),
            title: Text(
              entry.title,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                decoration: entry.done ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Text(
              details.join(' · '),
              maxLines: showDate ? 4 : 3,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => _edit(entry),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (pending) ...[
                  const Icon(Icons.schedule_outlined, size: 20),
                  const SizedBox(width: 2),
                ],
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') _edit(entry);
                    if (value == 'memory') _toggleMemoryPin(entry);
                    if (value == 'delete') _delete(entry);
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text(AnnaStrings.of(context).edit),
                    ),
                    PopupMenuItem(
                      value: 'memory',
                      child: Text(
                        entry.memoryPinned
                            ? AnnaStrings.of(context).d3('mem_removeMemory')
                            : AnnaStrings.of(context).d3('addToMemories'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(AnnaStrings.of(context).delete),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _sharedInteractionFooter(
            entry,
            hearts: hearts,
            comments: comments,
            likedByMe: likedByMe,
            seen: seen,
          ),
        ],
      ),
    );
  }

  Widget _syncCard(BuildContext context) {
    final cloud = CloudSyncService.instance;
    final pendingEntries = pendingIds.length;
    final pendingInteractions = widget.store.pendingSharedInteractionCount;
    final pendingMedia = widget.store.pendingSharedMediaCount;
    final pendingTotal =
        pendingEntries + pendingInteractions + pendingMedia;
    final scheme = Theme.of(context).colorScheme;
    final IconData icon;
    final String title;
    final String subtitle;

    if (pendingTotal > 0) {
      icon = cloud.signedIn ? Icons.sync : Icons.cloud_off_outlined;
      title = '$pendingTotal modifiche in attesa';
      final parts = <String>[
        if (pendingEntries > 0) '$pendingEntries contenuti',
        if (pendingInteractions > 0) '$pendingInteractions interazioni',
        if (pendingMedia > 0) '$pendingMedia media',
      ];
      subtitle = cloud.signedIn
          ? '${parts.join(' · ')} · retry automatico attivo.'
          : '${parts.join(' · ')} · salvati sul dispositivo fino al ritorno online.';
    } else if (!cloud.signedIn) {
      icon = Icons.cloud_off_outlined;
      title = AnnaStrings.of(context).d3('offline');
      subtitle = AnnaStrings.of(context).d3('offlineLocalCopy');
    } else if (realtimeConnected) {
      icon = Icons.bolt;
      title = 'Sincronizzato in tempo reale';
      subtitle = lastRefreshAt == null
          ? 'In ascolto degli aggiornamenti.'
          : 'Ultimo aggiornamento ${DateFormat('HH:mm').format(lastRefreshAt!)}.';
    } else {
      icon = Icons.cloud_done_outlined;
      title = 'Sincronizzato';
      subtitle = 'La connessione realtime si ristabilirà automaticamente.';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: scheme.primary),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          if (pendingTotal > 0 && cloud.signedIn)
            IconButton(
              tooltip: AnnaStrings.of(context).d3('retryNow'),
              onPressed: () => _refresh(),
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dayEntries = _selectedEntries;
    return AnimatedBuilder(
      animation: Listenable.merge([
        CloudSyncService.instance,
        widget.store.sharedRevision,
        widget.store.syncRevision,
      ]),
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: Text(
            widget.space.name,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          actions: [
            IconButton(
              tooltip: AnnaStrings.of(context).d3('ourMemories'),
              onPressed: _openSharedMemories,
              icon: const Icon(Icons.photo_library_outlined),
            ),
            IconButton(
              tooltip: 'Password Noi ♡',
              onPressed: _openSharedPasswords,
              icon: const Icon(Icons.password_outlined),
            ),
            IconButton(
              tooltip: AnnaStrings.of(context).d3('peopleInSpace'),
              onPressed: _openMembers,
              icon: const Icon(Icons.group_outlined),
            ),
            if (widget.space.isOwner)
              IconButton(
                tooltip: AnnaStrings.of(context).d3('invite'),
                onPressed: _invite,
                icon: const Icon(Icons.person_add_alt_1_outlined),
              ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'refresh') _refresh();
                if (value == 'leave') _leaveOrDelete();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'refresh',
                  child: Text(AnnaStrings.of(context).d3('refresh')),
                ),
                PopupMenuItem(
                  value: 'leave',
                  child: Text(
                    widget.space.isOwner
                        ? AnnaStrings.of(context).d3('deleteSpace')
                        : AnnaStrings.of(context).d3('leaveSpace'),
                  ),
                ),
              ],
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _createSharedContent,
          icon: const Icon(Icons.add),
          label: Text(AnnaStrings.of(context).d3('share')),
        ),
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 100),
            children: [
              Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.favorite_outline),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Noi ♡ · tutto ciò che crei qui è condiviso. '
                        AnnaStrings.of(context).d3('restPrivate'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _syncCard(context),
              const SizedBox(height: 10),
              _sharedDiaryCard(context),
              const SizedBox(height: 10),
              Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.shopping_cart_outlined),
                  ),
                  title: Text(
                    AnnaStrings.of(context).d3('shoppingList'),
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(
                    AnnaStrings.of(context).d3Format(
                      'shoppingSummary',
                      {
                        'count': widget.store.sharedShoppingItems(widget.space.id).where((entry) => !entry.done).length,
                      },
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _openSharedShopping,
                ),
              ),
              const SizedBox(height: 10),
              Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.photo_library_outlined),
                  ),
                  title: Text(
                    AnnaStrings.of(context).d3('ourMemories'),
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(
                    '${AnnaStrings.of(context).memoriesCount(entries.where((entry) => entry.appearsInSharedMemories).length)} · '
                    '${AnnaStrings.of(context).d3('sharedMediaSummary')}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _openSharedMemories,
                ),
              ),
              const SizedBox(height: 14),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(
                    value: true,
                    icon: Icon(Icons.dynamic_feed_outlined),
                    label: Text(AnnaStrings.of(context).d3('feed')),
                  ),
                  ButtonSegment<bool>(
                    value: false,
                    icon: Icon(Icons.calendar_month_outlined),
                    label: Text(AnnaStrings.of(context).d3('calendar')),
                  ),
                ],
                selected: {feedMode},
                onSelectionChanged: (value) =>
                    setState(() => feedMode = value.first),
              ),
              const SizedBox(height: 14),
              if (loading && entries.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (feedMode) ...[
                const SectionTitle('Ultimi aggiornamenti'),
                const SizedBox(height: 10),
                if (_feedEntries.isEmpty)
                  const SimpleCard(
                    child: Text(AnnaStrings.of(context).d3('nothingNoi')),
                  )
                else
                  ..._feedEntries.map(
                    (entry) => _sharedEntryCard(
                      context,
                      entry,
                      showDate: true,
                    ),
                  ),
              ] else ...[
                TableCalendar<SharedEntry>(
                  locale: 'it_IT',
                  firstDay: DateTime(2020),
                  lastDay: DateTime(2040),
                  focusedDay: selected,
                  selectedDayPredicate: (day) =>
                      AgendaStore.sameDay(day, selected),
                  eventLoader: (day) => entries
                      .where((entry) => AgendaStore.sameDay(entry.date, day))
                      .toList(),
                  onDaySelected: (day, _) => setState(() => selected = day),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                ),
                const SizedBox(height: 16),
                SectionTitle(
                  _cap(DateFormat('EEEE d MMMM', 'it_IT').format(selected)),
                ),
                const SizedBox(height: 10),
                if (dayEntries.isEmpty)
                  const SimpleCard(
                    child: Text(AnnaStrings.of(context).d3('nothingSharedDay')),
                  )
                else
                  ...dayEntries.map(
                    (entry) => _sharedEntryCard(context, entry),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
class _CachedBase64Image extends StatefulWidget {
  final String data;
  final BoxFit fit;
  const _CachedBase64Image({
    required this.data,
    required this.fit,
  });

  @override
  State<_CachedBase64Image> createState() => _CachedBase64ImageState();
}

class _CachedBase64ImageState extends State<_CachedBase64Image> {
  Uint8List? bytes;

  @override
  void initState() {
    super.initState();
    _decode();
  }

  @override
  void didUpdateWidget(covariant _CachedBase64Image oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) _decode();
  }

  void _decode() {
    try {
      bytes = base64Decode(widget.data);
    } catch (_) {
      bytes = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = bytes;
    if (image == null) {
      return const Center(child: Icon(Icons.broken_image_outlined));
    }
    return Image.memory(
      image,
      fit: widget.fit,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) =>
          const Center(child: Icon(Icons.broken_image_outlined)),
    );
  }
}

class SharedPhotoViewerScreen extends StatefulWidget {
  final SharedSpace space;
  final SharedEntry entry;

  const SharedPhotoViewerScreen({
    super.key,
    required this.space,
    required this.entry,
  });

  @override
  State<SharedPhotoViewerScreen> createState() =>
      _SharedPhotoViewerScreenState();
}

class _SharedPhotoViewerScreenState extends State<SharedPhotoViewerScreen> {
  late final Future<Uint8List> _imageFuture = _load();

  Future<Uint8List> _load() async {
    final path = widget.entry.mediaPath.trim();
    if (path.isNotEmpty) {
      final cacheId =
          MediaAssetStore.instance.namedAssetId('remote', path);
      final cached = await MediaAssetStore.instance.read(cacheId);
      if (cached != null) return cached;

      if (CloudSyncService.instance.signedIn) {
        try {
          final downloaded =
              await CloudSyncService.instance.downloadSharedMedia(path);
          await MediaAssetStore.instance.putNamed(cacheId, downloaded);
          return downloaded;
        } catch (_) {}
      }
    }

    if (widget.entry.mediaThumbnailAssetId.isNotEmpty) {
      final thumbnail = await MediaAssetStore.instance
          .read(widget.entry.mediaThumbnailAssetId);
      if (thumbnail != null) return thumbnail;
    }
    if (widget.entry.mediaThumbnailBase64.isNotEmpty) {
      return base64Decode(widget.entry.mediaThumbnailBase64);
    }
    throw StateError('shared_photo_unavailable');
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = _cap(
      DateFormat(
        'EEEE d MMMM yyyy',
        'it_IT',
      ).format(widget.entry.date),
    );

    return DiaryPhotoViewerShell(
      title: dateLabel,
      caption: widget.entry.note,
      image: FutureBuilder<Uint8List>(
        future: _imageFuture,
        builder: (context, snapshot) => DiaryZoomableImage(
          bytes: snapshot.data,
          loading: snapshot.connectionState != ConnectionState.done,
        ),
      ),
      metadata: [
        Text(
          widget.space.name,
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

Future<SharedEntry?> _openSharedEntryEditor(
  BuildContext context, {
  required DateTime initialDate,
  SharedEntry? existing,
  SharedEntryType? initialType,
  TimeOfDay? initialTime,
}) async {
  final title = TextEditingController(text: existing?.title ?? '');
  final note = TextEditingController(text: existing?.note ?? '');
  var type = existing?.type ?? initialType ?? SharedEntryType.appointment;
  var date = existing?.date ?? initialDate;
  var start = existing?.start ?? initialTime;
  var end = existing?.end ??
      (start == null ? null : _timePlusMinutes(start, 60));

  final result = await showDialog<SharedEntry>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setLocal) => AlertDialog(
        title: Text(
          existing == null ? AnnaStrings.of(context).d3('shareSomething') : AnnaStrings.of(context).d3('editItem'),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  avatar: Icon(Icons.favorite_outline, size: 18),
                  label: Text(AnnaStrings.of(context).d3('visibilityNoi')),
                ),
              ),
              const SizedBox(height: 10),
              SegmentedButton<SharedEntryType>(
                segments: const [
                  SharedEntryType.appointment,
                  SharedEntryType.task,
                  SharedEntryType.note,
                ]
                    .map(
                      (value) => ButtonSegment(
                        value: value,
                        icon: Icon(value.icon),
                        label: Text(value.label),
                      ),
                    )
                    .toList(),
                selected: {type},
                onSelectionChanged: (value) =>
                    setLocal(() => type = value.first),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: title,
                autofocus: existing == null,
                decoration: InputDecoration(labelText: AnnaStrings.of(context).d3('title')),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: note,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(labelText: AnnaStrings.of(context).d3('note')),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined),
                title: Text(
                  DateFormat('d MMMM yyyy', 'it_IT').format(date),
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2040),
                  );
                  if (picked != null) setLocal(() => date = picked);
                },
              ),
              if (type.supportsTime)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.schedule_outlined),
                  title: Text(
                    start == null ? 'Senza orario' : formatTime(start!),
                  ),
                  trailing: start == null
                      ? null
                      : IconButton(
                          onPressed: () => setLocal(() {
                            start = null;
                            end = null;
                          }),
                          icon: const Icon(Icons.close),
                        ),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: start ?? TimeOfDay.now(),
                    );
                    if (picked != null) {
                      setLocal(() {
                        start = picked;
                        end ??= _timePlusMinutes(picked, 60);
                      });
                    }
                  },
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AnnaStrings.of(context).cancel),
          ),
          FilledButton(
            onPressed: () {
              final value = title.text.trim();
              if (value.isEmpty) return;
              Navigator.pop(
                dialogContext,
                SharedEntry(
                  id: existing?.id ?? const Uuid().v4(),
                  type: type,
                  title: value,
                  note: note.text.trim(),
                  date: date,
                  createdAt:
                      existing?.createdAt ??
                      existing?.updatedAt ??
                      DateTime.now(),
                  start: type.supportsTime ? start : null,
                  end: type.supportsTime ? end : null,
                  done: existing?.done ?? false,
                ),
              );
            },
            child: Text(AnnaStrings.of(context).save),
          ),
        ],
      ),
    ),
  );

  title.dispose();
  note.dispose();
  return result;
}
