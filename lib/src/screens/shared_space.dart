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
        title: const Text('Crea uno spazio condiviso'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nome dello spazio'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Crea'),
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
      _message('Impossibile creare lo spazio: $error');
    }
  }

  Future<void> _joinSpace() async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Collegati con un codice'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          maxLength: 8,
          decoration: const InputDecoration(
            labelText: 'Codice invito',
            hintText: 'Es. A1B2C3D4',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              controller.text.trim().toUpperCase(),
            ),
            child: const Text('Collegati'),
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
      _message('Codice non valido, già usato o scaduto.');
    }
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
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
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Noi ♡',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            actions: [
              if (cloud.signedIn)
                IconButton(
                  tooltip: 'Aggiorna',
                  onPressed: loading ? null : _reload,
                  icon: const Icon(Icons.refresh),
                ),
            ],
          ),
          body: !cloud.signedIn
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(28),
                    child: Text(
                      'La sessione dell’account non è disponibile. '
                      'Torna alla schermata principale per riconnetterti.',
                      textAlign: TextAlign.center,
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
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFE4EC), Color(0xFFF0E8FF)],
                        ),
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.favorite_outline, size: 30),
                          SizedBox(height: 10),
                          Text(
                            'Spazio condiviso',
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Gli aggiornamenti arrivano in tempo reale. '
                            'Se siete offline, le modifiche restano in coda e vengono inviate dopo.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (spaces.isEmpty)
                      SimpleCard(
                        child: Column(
                          children: [
                            const Text(
                              'Non sei ancora collegato a nessuno spazio.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: _createSpace,
                                icon: const Icon(Icons.add),
                                label: const Text('Crea il nostro spazio'),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _joinSpace,
                                icon: const Icon(Icons.link),
                                label: const Text('Inserisci un codice'),
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      ...spaces.map((space) {
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
                                  : 'Spazio condiviso · sincronizzato',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (unread > 0)
                                  Badge(
                                    label: Text(
                                      unread > 99 ? '99+' : '$unread',
                                    ),
                                    child: const Icon(Icons.notifications_none),
                                  ),
                                const SizedBox(width: 6),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                            onTap: () async {
                              await widget.store.markSharedSpaceRead(space.id);
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
                              await widget.store.markSharedSpaceRead(space.id);
                              await _reload();
                            },
                          ),
                        );
                      }),
                      const SizedBox(height: 6),
                      OutlinedButton.icon(
                        onPressed: _joinSpace,
                        icon: const Icon(Icons.link),
                        label: const Text('Collegati a un altro spazio'),
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

  String get _cacheKey => widget.store.sharedCacheStorageKey(widget.space.id);
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
            unawaited(_refresh(silent: true, refreshInteractions: false));
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
        final bucket = nextComments.putIfAbsent(
          entryId,
          () => <SharedEntryComment>[],
        );
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
          final seenAt = DateTime.tryParse(
            record['last_seen_at']?.toString() ?? '',
          );
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

  Future<void> _loadInteractionCache(LocalStateStore prefs) async {
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
          for (final entry in hearts.entries) entry.key: entry.value.toList(),
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
    await _refresh(silent: entries.isNotEmpty, refreshInteractions: false);
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
    await widget.store.flushSharedMediaUploads(spaceId: widget.space.id);
    await widget.store.flushSharedInteractionOperations(
      spaceId: widget.space.id,
    );
    await widget.store.flushSharedPendingOperations(spaceId: widget.space.id);
    await _updatePendingState();
    if (widget.store.sharedConflictCount > conflictsBefore &&
        widget.store.sharedConflictCount > _seenConflictCount) {
      _seenConflictCount = widget.store.sharedConflictCount;
      _message('Conflitto risolto: è stata mantenuta la modifica più recente.');
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

      final next =
          List<SharedEntry>.from(
            widget.store._sharedAgendaEntriesBySpace[widget.space.id] ??
                const <SharedEntry>[],
          )..sort((a, b) {
            final date = b.date.compareTo(a.date);
            if (date != 0) return date;
            final am = a.start == null
                ? -1
                : a.start!.hour * 60 + a.start!.minute;
            final bm = b.start == null
                ? -1
                : b.start!.hour * 60 + b.start!.minute;
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
          'Impossibile aggiornare ora. Mostro l’ultima copia disponibile.',
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
        final comments = await cloud.listSharedEntryComments(widget.space.id);
        final reactions = await cloud.listSharedEntryReactions(widget.space.id);
        final reads = await cloud.listSharedMemberReads(widget.space.id);

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
        nextReads = {for (final read in reads) read.userId: read.lastSeenAt};
      } catch (_) {
        // Preserve the last known interaction cache and overlay the offline
        // queue below.
      }
    }

    final pending = await widget.store.loadSharedInteractionPendingOperations(
      widget.space.id,
    );
    final uid = widget.store.activeAccountId ?? cloud.userId ?? '';
    for (final operation in pending) {
      switch (operation.type) {
        case SharedInteractionPendingType.addComment:
          final commentId =
              operation.payload['commentId']?.toString() ?? operation.id;
          final bucket = nextComments.putIfAbsent(operation.entryId, () => []);
          if (!bucket.any((comment) => comment.id == commentId)) {
            bucket.add(
              SharedEntryComment(
                id: commentId,
                spaceId: widget.space.id,
                entryId: operation.entryId,
                userId: uid,
                authorName: operation.payload['authorName']?.toString() ?? '',
                body: operation.payload['body']?.toString() ?? '',
                createdAt: operation.createdAt,
                updatedAt: operation.createdAt,
              ),
            );
          }
          break;
        case SharedInteractionPendingType.deleteComment:
          final commentId = operation.payload['commentId']?.toString() ?? '';
          nextComments[operation.entryId]?.removeWhere(
            (comment) => comment.id == commentId,
          );
          break;
        case SharedInteractionPendingType.setHeart:
          final hearts = nextHearts.putIfAbsent(
            operation.entryId,
            () => <String>{},
          );
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

    await _saveInteractionCache(nextComments, nextHearts, nextReads);
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
              read.key != uid && !read.value.isBefore(entry.updatedAt!.toUtc()),
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
    await _saveInteractionCache(commentsByEntry, heartsByEntry, memberReads);
  }

  Future<void> _deleteComment(SharedEntryComment comment) async {
    await widget.store.enqueueSharedCommentDelete(
      spaceId: widget.space.id,
      entryId: comment.entryId,
      commentId: comment.id,
    );
    setState(() {
      commentsByEntry[comment.entryId]?.removeWhere(
        (candidate) => candidate.id == comment.id,
      );
    });
    if (CloudSyncService.instance.signedIn) {
      await widget.store.flushSharedInteractionOperations(
        spaceId: widget.space.id,
      );
    }
    await _saveInteractionCache(commentsByEntry, heartsByEntry, memberReads);
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
                              'Nessun commento. Scrivi il primo messaggio.',
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
                                        ? 'L’altra persona'
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
                                  '${comment.body}\n${DateFormat('d MMM · HH:mm', 'it_IT').format(comment.createdAt.toLocal())}',
                                ),
                                isThreeLine: true,
                                trailing: mine
                                    ? IconButton(
                                        tooltip: 'Elimina commento',
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
                          decoration: const InputDecoration(
                            hintText: 'Scrivi un commento...',
                            border: OutlineInputBorder(),
                            counterText: '',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        tooltip: 'Invia',
                        onPressed: () async {
                          final text = controller.text.trim();
                          if (text.isEmpty) return;
                          try {
                            final author =
                                widget.store.preferences.displayName
                                    .trim()
                                    .isEmpty
                                ? 'Utente'
                                : widget.store.preferences.displayName.trim();
                            final comment = await widget.store
                                .enqueueSharedComment(
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
                              (a, b) => a.createdAt.compareTo(b.createdAt),
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
                                'Commento salvato offline: verrà inviato automaticamente.',
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
        .where((entry) => AgendaStore.sameDay(entry.date, selected))
        .toList();
    selectedEntries.sort((a, b) {
      final aMinutes = a.start == null
          ? -1
          : a.start!.hour * 60 + a.start!.minute;
      final bMinutes = b.start == null
          ? -1
          : b.start!.hour * 60 + b.start!.minute;
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
    final feed = [...entries];
    feed.sort((a, b) {
      final aUpdated = a.updatedAt ?? a.date;
      final bUpdated = b.updatedAt ?? b.date;
      final updated = bUpdated.compareTo(aUpdated);
      if (updated != 0) return updated;

      final aMinutes = a.start == null
          ? -1
          : a.start!.hour * 60 + a.start!.minute;
      final bMinutes = b.start == null
          ? -1
          : b.start!.hour * 60 + b.start!.minute;
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
    if (entry.updatedBy != null) return 'Modificato dall’altra persona';
    return '';
  }

  SharedEntry _withLocalMetadata(SharedEntry entry, DateTime revision) =>
      entry.copyWith(
        editorName: widget.store.preferences.displayName.trim().isEmpty
            ? 'Utente'
            : widget.store.preferences.displayName.trim(),
        updatedBy: CloudSyncService.instance.userId,
        updatedAt: revision,
      );

  Future<void> _persistSharedEntry(SharedEntry result) async {
    final revision = DateTime.now().toUtc();
    final updated = _withLocalMetadata(result, revision);
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
      _message('Salvato offline: verrà sincronizzato appena torni online.');
    }
  }

  Future<void> _edit([
    SharedEntry? existing,
    SharedEntryType? initialType,
  ]) async {
    if (widget.store.activeAccountId == null) {
      _message(
        'Accedi al cloud almeno una volta per usare lo spazio condiviso.',
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

    final compactTitle = value.split(RegExp(r'\s+')).take(7).join(' ').trim();

    await _persistSharedEntry(
      SharedEntry(
        id: existing?.id ?? const Uuid().v4(),
        type: SharedEntryType.note,
        title: compactTitle.isEmpty ? 'Nota' : compactTitle,
        note: value,
        date: existing?.date ?? selected,
        createdAt: existing?.createdAt ?? existing?.updatedAt ?? DateTime.now(),
        memoryPinned: existing?.memoryPinned ?? false,
      ),
    );
  }

  Future<void> _editSharedPhotoCaption(SharedEntry entry) async {
    final value = await showDiaryCaptionEditor(
      context,
      initialText: entry.note,
    );
    if (value == null) return;
    await _persistSharedEntry(entry.copyWith(note: value));
  }

  Future<void> _addSharedPhoto([SharedEntry? existing]) async {
    if (sharedPhotoBusy) return;
    if (widget.store.activeAccountId == null) {
      _message('Accedi al cloud almeno una volta per condividere una foto.');
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
        caption = await showDiaryCaptionEditor(context, adding: true);
        if (caption == null) return;
      }

      final thumbnailBytes = await _diaryThumbnailBytes(fullBytes);
      final mediaAssetId = await MediaAssetStore.instance.put(fullBytes);
      final thumbnailAssetId = await MediaAssetStore.instance.put(
        thumbnailBytes,
      );

      final entryId = existing?.id ?? const Uuid().v4();
      final localPreview = SharedEntry(
        id: entryId,
        type: SharedEntryType.photo,
        title: existing?.title.trim().isNotEmpty == true
            ? existing!.title
            : 'Foto',
        note: caption ?? '',
        date: existing?.date ?? selected,
        createdAt: existing?.createdAt ?? existing?.updatedAt ?? DateTime.now(),
        // While a replacement is pending, do not display the previous
        // remote full-resolution image over the new local preview.
        mediaPath: '',
        mediaThumbnailAssetId: thumbnailAssetId,
        memoryPinned: existing?.memoryPinned ?? false,
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
          oldMediaPath: existing?.mediaPath ?? '',
          createdAt: localPreview.createdAt ?? revision,
        ),
      );

      if (CloudSyncService.instance.signedIn) {
        await widget.store.flushSharedMediaUploads(spaceId: widget.space.id);
        await _refresh(silent: true);
      } else {
        _message(
          'Foto salvata sul dispositivo: verrà caricata automaticamente.',
        );
      }
    } catch (_) {
      _message(
        'La foto è rimasta sul dispositivo. Il caricamento verrà ritentato.',
      );
    } finally {
      if (mounted) setState(() => sharedPhotoBusy = false);
    }
  }

  Future<void> _addSharedSketch([SharedEntry? existing]) async {
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
        createdAt: existing?.createdAt ?? existing?.updatedAt ?? DateTime.now(),
        sketchPages: pages,
        memoryPinned: existing?.memoryPinned ?? false,
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
              const ListTile(
                title: Text(
                  'Diario condiviso · Noi ♡',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 19),
                ),
                subtitle: Text(
                  'Stessi strumenti del diario privato, ma visibili a entrambi.',
                ),
              ),
              ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.sticky_note_2_outlined),
                ),
                title: const Text('Nota'),
                subtitle: const Text('Un pensiero o un ricordo condiviso'),
                onTap: () => Navigator.pop(sheetContext, 'note'),
              ),
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.draw_outlined)),
                title: const Text('Sketch'),
                subtitle: const Text(
                  'Lo stesso Sketchbook completo del diario privato',
                ),
                onTap: () => Navigator.pop(sheetContext, 'sketch'),
              ),
              ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.add_photo_alternate_outlined),
                ),
                title: const Text('Foto'),
                subtitle: const Text('Fotocamera o galleria + didascalia'),
                onTap: () => Navigator.pop(sheetContext, 'photo'),
              ),
              const Divider(height: 24),
              const ListTile(
                dense: true,
                title: Text(
                  'Agenda condivisa',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.event_outlined)),
                title: const Text('Appuntamento'),
                onTap: () => Navigator.pop(sheetContext, 'appointment'),
              ),
              ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.check_circle_outline),
                ),
                title: const Text('Da fare'),
                onTap: () => Navigator.pop(sheetContext, 'task'),
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
    }
  }

  Widget _sharedDiaryCard(BuildContext context) {
    final blocks =
        entries
            .where(
              (entry) =>
                  AgendaStore.sameDay(entry.date, selected) &&
                  (entry.type == SharedEntryType.note ||
                      entry.type == SharedEntryType.photo ||
                      entry.type == SharedEntryType.sketch),
            )
            .toList()
          ..sort(
            (a, b) => (b.createdAt ?? b.updatedAt ?? b.date).compareTo(
              a.createdAt ?? a.updatedAt ?? a.date,
            ),
          );

    return DiaryComposerSection(
      title: 'Il nostro diario',
      subtitle:
          'Stessi strumenti, stesse card e stesse azioni del diario privato. '
          'Qui i contenuti vengono sincronizzati in Noi ♡ e sono visibili a entrambi.',
      memoriesLabel: 'Ricordi',
      emptyText:
          'Qui potete costruire la giornata come una pagina di diario condivisa, '
          'un ricordo alla volta.',
      onMemories: _openSharedMemories,
      onAddNote: () => _addSharedNote(),
      onAddSketch: () => _addSharedSketch(),
      onAddPhoto: () => _addSharedPhoto(),
      photoBusy: sharedPhotoBusy,
      children: blocks
          .map((entry) => _sharedEntryCard(context, entry, showDate: false))
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
    final isDiaryContent =
        entry.type == SharedEntryType.note ||
        entry.type == SharedEntryType.photo ||
        entry.type == SharedEntryType.sketch;
    final confirmed = isDiaryContent
        ? await confirmDiaryContentDelete(context)
        : await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Eliminare dallo spazio condiviso?'),
                  content: Text(entry.title),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('Annulla'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: const Text('Elimina'),
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
      mediaPath: entry.type == SharedEntryType.photo ? entry.mediaPath : '',
    );
    await _saveCache();
    if (CloudSyncService.instance.signedIn) {
      await _flushPending();
      await _refresh(silent: true);
    } else {
      _message('Eliminazione salvata offline.');
    }
  }

  String _inviteRemainingLabel(SpaceInvite invite) {
    final remaining = invite.remaining();
    if (remaining <= Duration.zero) return 'Scaduto';
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    if (hours > 0) return 'Valido ancora ${hours}h ${minutes}m';
    return 'Valido ancora ${minutes}m';
  }

  Future<void> _invite() async {
    try {
      var invite = await CloudSyncService.instance.getOrCreateSpaceInvite(
        widget.space.id,
      );
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          var regenerating = false;
          return StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              title: const Text('Codice per collegarsi'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Questo codice resta identico per 24 ore anche se chiudi '
                    'l’app o torni alla Home. Può essere usato da più persone '
                    'finché non scade o lo rigeneri.',
                  ),
                  const SizedBox(height: 18),
                  SelectableText(
                    invite.code,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _inviteRemainingLabel(invite),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    'Scade: ${DateFormat('d MMM, HH:mm', 'it_IT').format(invite.expiresAt.toLocal())}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              actions: [
                TextButton.icon(
                  onPressed: regenerating
                      ? null
                      : () async {
                          await Clipboard.setData(
                            ClipboardData(text: invite.code),
                          );
                          if (!dialogContext.mounted) return;
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            const SnackBar(content: Text('Codice copiato.')),
                          );
                        },
                  icon: const Icon(Icons.copy_outlined),
                  label: const Text('Copia'),
                ),
                TextButton(
                  onPressed: regenerating
                      ? null
                      : () async {
                          setDialogState(() => regenerating = true);
                          try {
                            final next = await CloudSyncService.instance
                                .getOrCreateSpaceInvite(
                                  widget.space.id,
                                  forceNew: true,
                                );
                            if (!dialogContext.mounted) return;
                            setDialogState(() {
                              invite = next;
                              regenerating = false;
                            });
                          } catch (_) {
                            if (!dialogContext.mounted) return;
                            setDialogState(() => regenerating = false);
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Non è stato possibile rigenerare il codice.',
                                ),
                              ),
                            );
                          }
                        },
                  child: Text(regenerating ? 'Rigenerazione…' : 'Nuovo codice'),
                ),
                FilledButton(
                  onPressed: regenerating
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Chiudi'),
                ),
              ],
            ),
          );
        },
      );
    } catch (_) {
      _message('Non è stato possibile recuperare il codice invito.');
    }
  }

  Future<void> _leaveOrDelete() async {
    final owner = widget.space.isOwner;
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(owner ? 'Eliminare lo spazio?' : 'Lasciare lo spazio?'),
            content: Text(
              owner
                  ? 'Lo spazio e tutti i contenuti condivisi verranno eliminati per tutti.'
                  : 'Non vedrai più questo spazio, ma i tuoi dati personali non verranno toccati.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Annulla'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(owner ? 'Elimina' : 'Lascia'),
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
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
            onPressed: interactionsLoading ? null : () => _toggleHeart(entry),
            icon: Icon(
              likedByMe ? Icons.favorite : Icons.favorite_border,
              color: likedByMe ? Theme.of(context).colorScheme.error : null,
              size: 20,
            ),
            label: Text(hearts.isEmpty ? 'Mi piace' : '${hearts.length}'),
          ),
          TextButton.icon(
            onPressed: () => _openComments(entry),
            icon: const Icon(Icons.chat_bubble_outline, size: 19),
            label: Text(comments.isEmpty ? 'Commenta' : '${comments.length}'),
          ),
          const Spacer(),
          if (seen != null)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Row(
                children: [
                  const Icon(Icons.done_all, size: 17),
                  const SizedBox(width: 4),
                  Text(seen, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
        ],
      ),
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
      if (showDate) _cap(DateFormat('EEE d MMM', 'it_IT').format(entry.date)),
      if (editor.isNotEmpty) editor,
      if (entry.updatedAt != null)
        'Aggiornato ${DateFormat('HH:mm', 'it_IT').format(entry.updatedAt!.toLocal())}',
      if (pending) 'In attesa di sincronizzazione',
    ];

    final VoidCallback openEntry = switch (entry.type) {
      SharedEntryType.note => () => _addSharedNote(entry),
      SharedEntryType.photo => () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              SharedPhotoViewerScreen(space: widget.space, entry: entry),
        ),
      ),
      SharedEntryType.sketch => () => _addSharedSketch(entry),
      _ => () {},
    };

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
        entry.note.trim().isEmpty ? 'Foto del giorno' : entry.note.trim(),
      SharedEntryType.sketch =>
        entry.sketchPages.length <= 1
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
      onEdit: kind == DiaryContentKind.photo ? null : openEntry,
      onEditCaption: kind == DiaryContentKind.photo
          ? () => _editSharedPhotoCaption(entry)
          : null,
      onReplacePhoto: kind == DiaryContentKind.photo
          ? () => _addSharedPhoto(entry)
          : null,
      onDelete: () => _delete(entry),
      statusIcon: pending
          ? const Icon(Icons.schedule_outlined, size: 20)
          : null,
      footer: _sharedInteractionFooter(
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
      if (showDate) _cap(DateFormat('EEE d MMM', 'it_IT').format(entry.date)),
      if (entry.start != null) formatTime(entry.start!),
      if (entry.note.isNotEmpty) entry.note,
      if (editor.isNotEmpty) editor,
      if (entry.memoryPinned) 'Nei ricordi',
      if (entry.updatedAt != null)
        'Aggiornato ${DateFormat('HH:mm', 'it_IT').format(entry.updatedAt!.toLocal())}',
      if (pending) 'In attesa di sincronizzazione',
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
                    const PopupMenuItem(value: 'edit', child: Text('Modifica')),
                    PopupMenuItem(
                      value: 'memory',
                      child: Text(
                        entry.memoryPinned
                            ? 'Togli dai ricordi'
                            : 'Aggiungi ai ricordi',
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Elimina'),
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
    final pendingTotal = pendingEntries + pendingInteractions + pendingMedia;
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
      title = 'Offline';
      subtitle = 'Puoi consultare e modificare la copia locale dello spazio.';
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
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          if (pendingTotal > 0 && cloud.signedIn)
            IconButton(
              tooltip: 'Riprova ora',
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
              tooltip: 'I nostri ricordi',
              onPressed: _openSharedMemories,
              icon: const Icon(Icons.photo_library_outlined),
            ),
            if (widget.space.isOwner)
              IconButton(
                tooltip: 'Invita',
                onPressed: _invite,
                icon: const Icon(Icons.person_add_alt_1_outlined),
              ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'refresh') _refresh();
                if (value == 'leave') _leaveOrDelete();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'refresh', child: Text('Aggiorna')),
                PopupMenuItem(
                  value: 'leave',
                  child: Text(
                    widget.space.isOwner ? 'Elimina spazio' : 'Lascia spazio',
                  ),
                ),
              ],
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _createSharedContent,
          icon: const Icon(Icons.add),
          label: const Text('Condividi'),
        ),
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 100),
            children: [
              Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer
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
                        'Il resto dell’agenda rimane privato.',
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
                    child: Icon(Icons.photo_library_outlined),
                  ),
                  title: const Text(
                    'I nostri ricordi',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(
                    '${entries.where((entry) => entry.appearsInSharedMemories).length} ricordi · '
                    'foto, sketch, note e momenti scelti da voi',
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
                    label: Text('Feed'),
                  ),
                  ButtonSegment<bool>(
                    value: false,
                    icon: Icon(Icons.calendar_month_outlined),
                    label: Text('Calendario'),
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
                  const SimpleCard(child: Text('Ancora niente in Noi ♡.'))
                else
                  ..._feedEntries.map(
                    (entry) => _sharedEntryCard(context, entry, showDate: true),
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
                    child: Text('Niente di condiviso per questo giorno.'),
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
  const _CachedBase64Image({required this.data, required this.fit});

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
      final cacheId = MediaAssetStore.instance.namedAssetId('remote', path);
      final cached = await MediaAssetStore.instance.read(cacheId);
      if (cached != null) return cached;

      if (CloudSyncService.instance.signedIn) {
        try {
          final downloaded = await CloudSyncService.instance
              .downloadSharedMedia(path);
          await MediaAssetStore.instance.putNamed(cacheId, downloaded);
          return downloaded;
        } catch (_) {}
      }
    }

    if (widget.entry.mediaThumbnailAssetId.isNotEmpty) {
      final thumbnail = await MediaAssetStore.instance.read(
        widget.entry.mediaThumbnailAssetId,
      );
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
      DateFormat('EEEE d MMMM yyyy', 'it_IT').format(widget.entry.date),
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
  var end =
      existing?.end ?? (start == null ? null : _timePlusMinutes(start, 60));

  final result = await showDialog<SharedEntry>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setLocal) => AlertDialog(
        title: Text(
          existing == null ? 'Condividi qualcosa' : 'Modifica elemento',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  avatar: Icon(Icons.favorite_outline, size: 18),
                  label: Text('Visibilità: Noi ♡'),
                ),
              ),
              const SizedBox(height: 10),
              SegmentedButton<SharedEntryType>(
                segments:
                    const [
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
                decoration: const InputDecoration(labelText: 'Titolo'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: note,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Nota'),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined),
                title: Text(DateFormat('d MMMM yyyy', 'it_IT').format(date)),
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
            child: const Text('Annulla'),
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
            child: const Text('Salva'),
          ),
        ],
      ),
    ),
  );

  title.dispose();
  note.dispose();
  return result;
}
