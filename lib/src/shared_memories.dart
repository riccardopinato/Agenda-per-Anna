part of '../main.dart';

enum _SharedMemoriesView {
  memories,
  days,
  months,
  years,
  timeline,
}

enum _SharedMemoriesFilter {
  all,
  photo,
  sketch,
  note,
  events,
}

class SharedMemoriesScreen extends StatefulWidget {
  final AgendaStore store;
  final SharedSpace space;
  final List<SharedEntry> Function() entriesProvider;
  final Map<String, List<SharedEntryComment>> Function() commentsProvider;
  final Map<String, Set<String>> Function() heartsProvider;
  final Map<String, DateTime> Function() readsProvider;
  final Future<void> Function() onRefresh;
  final Future<void> Function(SharedEntry entry) onToggleMemory;

  const SharedMemoriesScreen({
    super.key,
    required this.store,
    required this.space,
    required this.entriesProvider,
    required this.commentsProvider,
    required this.heartsProvider,
    required this.readsProvider,
    required this.onRefresh,
    required this.onToggleMemory,
  });

  @override
  State<SharedMemoriesScreen> createState() =>
      _SharedMemoriesScreenState();
}

class _SharedMemoriesScreenState extends State<SharedMemoriesScreen> {
  final TextEditingController searchController = TextEditingController();

  _SharedMemoriesView view = _SharedMemoriesView.memories;
  _SharedMemoriesFilter filter = _SharedMemoriesFilter.all;
  List<SharedEntry> entries = const [];
  Map<String, List<SharedEntryComment>> commentsByEntry = const {};
  Map<String, Set<String>> heartsByEntry = const {};
  Map<String, DateTime> memberReads = const {};
  bool refreshing = false;

  @override
  void initState() {
    super.initState();
    _syncSnapshot();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _syncSnapshot() {
    entries = List<SharedEntry>.from(widget.entriesProvider());
    commentsByEntry = {
      for (final entry in widget.commentsProvider().entries)
        entry.key: List<SharedEntryComment>.from(entry.value),
    };
    heartsByEntry = {
      for (final entry in widget.heartsProvider().entries)
        entry.key: Set<String>.from(entry.value),
    };
    memberReads = Map<String, DateTime>.from(widget.readsProvider());
  }

  Future<void> _refresh() async {
    if (refreshing) return;
    setState(() => refreshing = true);
    try {
      await widget.onRefresh();
      if (!mounted) return;
      setState(_syncSnapshot);
    } finally {
      if (mounted) setState(() => refreshing = false);
    }
  }

  Future<void> _toggleMemory(SharedEntry entry) async {
    await widget.onToggleMemory(entry);
    if (!mounted) return;
    setState(_syncSnapshot);
  }

  List<SharedEntry> get _memoryEntries {
    final query = searchController.text.trim().toLowerCase();
    final result = entries
        .where((entry) => entry.appearsInSharedMemories)
        .where(_matchesFilter)
        .where((entry) => _matchesSearch(entry, query))
        .toList();

    result.sort((a, b) {
      final date = b.date.compareTo(a.date);
      if (date != 0) return date;
      final updated = (b.updatedAt ?? b.date)
          .compareTo(a.updatedAt ?? a.date);
      if (updated != 0) return updated;
      return b.id.compareTo(a.id);
    });
    return result;
  }

  bool _matchesFilter(SharedEntry entry) => switch (filter) {
        _SharedMemoriesFilter.all => true,
        _SharedMemoriesFilter.photo => entry.type == SharedEntryType.photo,
        _SharedMemoriesFilter.sketch => entry.type == SharedEntryType.sketch,
        _SharedMemoriesFilter.note => entry.type == SharedEntryType.note,
        _SharedMemoriesFilter.events =>
          entry.type == SharedEntryType.appointment ||
              entry.type == SharedEntryType.task,
      };

  bool _matchesSearch(SharedEntry entry, String query) {
    if (query.isEmpty) return true;

    final date = DateFormat(
      'EEEE d MMMM yyyy',
      'it_IT',
    ).format(entry.date);
    final month = DateFormat('MMMM yyyy', 'it_IT').format(entry.date);
    final comments = commentsByEntry[entry.id] ?? const [];
    final haystack = <String>[
      entry.title,
      entry.note,
      entry.editorName,
      entry.type.label,
      date,
      month,
      entry.date.year.toString(),
      switch (entry.type) {
        SharedEntryType.photo => 'foto immagine ricordo',
        SharedEntryType.sketch => 'sketch disegno ricordo',
        SharedEntryType.note => 'nota pensiero messaggio ricordo',
        SharedEntryType.appointment => 'appuntamento evento momento',
        SharedEntryType.task => 'attività da fare momento',
      },
      for (final comment in comments) comment.body,
      for (final comment in comments) comment.authorName,
    ].join(' ').toLowerCase();

    return haystack.contains(query);
  }

  String _authorLabel(SharedEntry entry) {
    final name = entry.editorName.trim();
    if (name.isNotEmpty) return name;
    final uid =
        widget.store.activeAccountId ?? CloudSyncService.instance.userId;
    if (uid != null && entry.updatedBy == uid) return 'Tu';
    return 'Noi ♡';
  }

  String? _seenLabel(SharedEntry entry) {
    final uid =
        widget.store.activeAccountId ?? CloudSyncService.instance.userId;
    if (uid == null || entry.updatedBy != uid || entry.updatedAt == null) {
      return null;
    }

    final count = memberReads.entries
        .where(
          (read) =>
              read.key != uid &&
              !read.value.isBefore(entry.updatedAt!.toUtc()),
        )
        .length;
    if (count == 0) return null;
    return count == 1 ? 'Visto' : 'Visto da $count';
  }

  Future<void> _openEntry(SharedEntry entry) async {
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

    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => SharedMemoryDetailScreen(
          space: widget.space,
          entry: entry,
          hearts: heartsByEntry[entry.id]?.length ?? 0,
          comments: commentsByEntry[entry.id]?.length ?? 0,
          author: _authorLabel(entry),
          seenLabel: _seenLabel(entry),
        ),
      ),
    );
  }

  Map<DateTime, List<SharedEntry>> _groupByDay(
    List<SharedEntry> source,
  ) {
    final result = <DateTime, List<SharedEntry>>{};
    for (final entry in source) {
      final key = DateTime(
        entry.date.year,
        entry.date.month,
        entry.date.day,
      );
      result.putIfAbsent(key, () => <SharedEntry>[]).add(entry);
    }
    return result;
  }

  Map<int, List<SharedEntry>> _groupByMonth(
    List<SharedEntry> source,
  ) {
    final result = <int, List<SharedEntry>>{};
    for (final entry in source) {
      final key = entry.date.year * 100 + entry.date.month;
      result.putIfAbsent(key, () => <SharedEntry>[]).add(entry);
    }
    return result;
  }

  Map<int, List<SharedEntry>> _groupByYear(
    List<SharedEntry> source,
  ) {
    final result = <int, List<SharedEntry>>{};
    for (final entry in source) {
      result.putIfAbsent(entry.date.year, () => <SharedEntry>[]).add(entry);
    }
    return result;
  }

  SharedEntry _coverEntry(List<SharedEntry> source) {
    for (final type in const [
      SharedEntryType.photo,
      SharedEntryType.sketch,
      SharedEntryType.note,
      SharedEntryType.appointment,
      SharedEntryType.task,
    ]) {
      for (final entry in source) {
        if (entry.type == type) return entry;
      }
    }
    return source.first;
  }

  String _periodStats(List<SharedEntry> source) {
    final photos =
        source.where((entry) => entry.type == SharedEntryType.photo).length;
    final sketches =
        source.where((entry) => entry.type == SharedEntryType.sketch).length;
    final notes =
        source.where((entry) => entry.type == SharedEntryType.note).length;
    final moments = source
        .where(
          (entry) =>
              entry.type == SharedEntryType.appointment ||
              entry.type == SharedEntryType.task,
        )
        .length;

    return [
      '${source.length} ricordi',
      if (photos > 0) '$photos foto',
      if (sketches > 0) '$sketches sketch',
      if (notes > 0) '$notes note',
      if (moments > 0) '$moments momenti',
    ].join(' · ');
  }

  void _openCollection({
    required String title,
    required List<SharedEntry> source,
  }) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => SharedMemoryCollectionScreen(
          title: title,
          space: widget.space,
          entries: source,
          commentsByEntry: commentsByEntry,
          heartsByEntry: heartsByEntry,
          memberReads: memberReads,
          currentUserId:
              widget.store.activeAccountId ?? CloudSyncService.instance.userId,
        ),
      ),
    );
  }

  Widget _viewSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          _viewChip(
            _SharedMemoriesView.memories,
            Icons.grid_view_rounded,
            'Ricordi',
          ),
          _viewChip(
            _SharedMemoriesView.days,
            Icons.today_outlined,
            'Giorni',
          ),
          _viewChip(
            _SharedMemoriesView.months,
            Icons.calendar_view_month_outlined,
            'Mesi',
          ),
          _viewChip(
            _SharedMemoriesView.years,
            Icons.calendar_today_outlined,
            'Anni',
          ),
          _viewChip(
            _SharedMemoriesView.timeline,
            Icons.view_timeline_outlined,
            'Timeline',
          ),
        ],
      ),
    );
  }

  Widget _viewChip(
    _SharedMemoriesView value,
    IconData icon,
    String label,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: view == value,
        avatar: Icon(icon, size: 18),
        label: Text(label),
        onSelected: (_) => setState(() => view = value),
      ),
    );
  }

  Widget _filterSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          _filterChip(_SharedMemoriesFilter.all, 'Tutti'),
          _filterChip(_SharedMemoriesFilter.photo, 'Foto'),
          _filterChip(_SharedMemoriesFilter.sketch, 'Sketch'),
          _filterChip(_SharedMemoriesFilter.note, 'Note'),
          _filterChip(_SharedMemoriesFilter.events, 'Momenti'),
        ],
      ),
    );
  }

  Widget _filterChip(_SharedMemoriesFilter value, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: filter == value,
        label: Text(label),
        onSelected: (_) => setState(() => filter = value),
      ),
    );
  }

  Widget _emptyState() {
    final hasQuery = searchController.text.trim().isNotEmpty ||
        filter != _SharedMemoriesFilter.all;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasQuery
                  ? Icons.search_off_outlined
                  : Icons.favorite_border_rounded,
              size: 58,
            ),
            const SizedBox(height: 12),
            Text(
              hasQuery
                  ? 'Nessun ricordo corrisponde alla ricerca.'
                  : 'I vostri ricordi compariranno qui.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasQuery
                  ? 'Prova a cambiare parole o filtri.'
                  : 'Foto, sketch e note entrano automaticamente. '
                      'Appuntamenti e attività possono essere aggiunti ai '
                      'ricordi dal menu dell’elemento.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemories(List<SharedEntry> source) {
    if (source.isEmpty) return _emptyState();
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 120),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.76,
      ),
      itemCount: source.length,
      itemBuilder: (context, index) {
        final entry = source[index];
        return SharedMemoryTile(
          entry: entry,
          author: _authorLabel(entry),
          hearts: heartsByEntry[entry.id]?.length ?? 0,
          comments: commentsByEntry[entry.id]?.length ?? 0,
          seenLabel: _seenLabel(entry),
          onTap: () => _openEntry(entry),
          onToggleMemory:
              entry.type == SharedEntryType.appointment ||
                      entry.type == SharedEntryType.task
                  ? () => _toggleMemory(entry)
                  : null,
        );
      },
    );
  }

  Widget _buildDays(List<SharedEntry> source) {
    if (source.isEmpty) return _emptyState();
    final groups = _groupByDay(source);
    final keys = groups.keys.toList()..sort((a, b) => b.compareTo(a));

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 120),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.86,
      ),
      itemCount: keys.length,
      itemBuilder: (context, index) {
        final day = keys[index];
        final items = groups[day]!;
        return SharedMemoryPeriodCard(
          cover: _coverEntry(items),
          title: _cap(
            DateFormat('EEE d MMM', 'it_IT').format(day),
          ),
          subtitle: _periodStats(items),
          onTap: () => _openCollection(
            title: _cap(
              DateFormat('EEEE d MMMM yyyy', 'it_IT').format(day),
            ),
            source: items,
          ),
        );
      },
    );
  }

  Widget _buildMonths(List<SharedEntry> source) {
    if (source.isEmpty) return _emptyState();
    final groups = _groupByMonth(source);
    final keys = groups.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 120),
      itemCount: keys.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final key = keys[index];
        final year = key ~/ 100;
        final month = key % 100;
        final items = groups[key]!;
        return SharedMemoryPeriodCard(
          cover: _coverEntry(items),
          title: _cap(
            DateFormat('MMMM yyyy', 'it_IT').format(
              DateTime(year, month),
            ),
          ),
          subtitle: _periodStats(items),
          horizontal: true,
          onTap: () => _openCollection(
            title: _cap(
              DateFormat('MMMM yyyy', 'it_IT').format(
                DateTime(year, month),
              ),
            ),
            source: items,
          ),
        );
      },
    );
  }

  Widget _buildYears(List<SharedEntry> source) {
    if (source.isEmpty) return _emptyState();
    final groups = _groupByYear(source);
    final keys = groups.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 120),
      itemCount: keys.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final year = keys[index];
        final items = groups[year]!;
        final distinctDays = items
            .map(
              (entry) => DateTime(
                entry.date.year,
                entry.date.month,
                entry.date.day,
              ),
            )
            .toSet()
            .length;
        return SharedMemoryPeriodCard(
          cover: _coverEntry(items),
          title: year.toString(),
          subtitle: '${_periodStats(items)} · $distinctDays giorni',
          horizontal: true,
          onTap: () => _openCollection(
            title: 'Ricordi $year',
            source: items,
          ),
        );
      },
    );
  }

  Widget _buildTimeline(List<SharedEntry> source) {
    if (source.isEmpty) return _emptyState();

    final children = <Widget>[];
    DateTime? previousDay;
    for (final entry in source) {
      final day = DateTime(
        entry.date.year,
        entry.date.month,
        entry.date.day,
      );
      if (previousDay != day) {
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 16, 2, 8),
            child: Text(
              _cap(
                DateFormat(
                  'EEEE d MMMM yyyy',
                  'it_IT',
                ).format(day),
              ),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 17,
              ),
            ),
          ),
        );
        previousDay = day;
      }
      children.add(
        SharedMemoryTimelineTile(
          entry: entry,
          author: _authorLabel(entry),
          hearts: heartsByEntry[entry.id]?.length ?? 0,
          comments: commentsByEntry[entry.id]?.length ?? 0,
          seenLabel: _seenLabel(entry),
          onTap: () => _openEntry(entry),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 120),
      children: children,
    );
  }

  @override
  Widget build(BuildContext context) {
    final source = _memoryEntries;
    final totalDays = source
        .map(
          (entry) => DateTime(
            entry.date.year,
            entry.date.month,
            entry.date.day,
          ),
        )
        .toSet()
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'I nostri ricordi',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'Aggiorna',
            onPressed: refreshing ? null : _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
            child: TextField(
              controller: searchController,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Cerca nei nostri ricordi...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Cancella ricerca',
                        onPressed: () {
                          searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close),
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
          _viewSelector(),
          const SizedBox(height: 8),
          _filterSelector(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${source.length} ricordi · $totalDays giorni',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                if (refreshing)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          Expanded(
            child: switch (view) {
              _SharedMemoriesView.memories => _buildMemories(source),
              _SharedMemoriesView.days => _buildDays(source),
              _SharedMemoriesView.months => _buildMonths(source),
              _SharedMemoriesView.years => _buildYears(source),
              _SharedMemoriesView.timeline => _buildTimeline(source),
            },
          ),
        ],
      ),
    );
  }
}

class SharedMemoryTile extends StatelessWidget {
  final SharedEntry entry;
  final String author;
  final int hearts;
  final int comments;
  final String? seenLabel;
  final VoidCallback onTap;
  final VoidCallback? onToggleMemory;

  const SharedMemoryTile({
    super.key,
    required this.entry,
    required this.author,
    required this.hearts,
    required this.comments,
    required this.seenLabel,
    required this.onTap,
    this.onToggleMemory,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  SharedMemoryCover(entry: entry),
                  if (entry.memoryPinned)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              .withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            Icons.favorite,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 4),
              child: Text(
                entry.title.trim().isEmpty ? entry.type.label : entry.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                '${DateFormat('d MMM yyyy', 'it_IT').format(entry.date)} · $author',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 4, 7),
              child: Row(
                children: [
                  if (hearts > 0) ...[
                    const Icon(Icons.favorite, size: 15),
                    const SizedBox(width: 3),
                    Text('$hearts'),
                    const SizedBox(width: 8),
                  ],
                  if (comments > 0) ...[
                    const Icon(Icons.chat_bubble_outline, size: 14),
                    const SizedBox(width: 3),
                    Text('$comments'),
                  ],
                  const Spacer(),
                  if (seenLabel != null)
                    Text(
                      seenLabel!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  if (onToggleMemory != null)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: entry.memoryPinned
                          ? 'Togli dai ricordi'
                          : 'Aggiungi ai ricordi',
                      onPressed: onToggleMemory,
                      icon: Icon(
                        entry.memoryPinned
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 19,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SharedMemoryCover extends StatelessWidget {
  final SharedEntry entry;

  const SharedMemoryCover({
    super.key,
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    if (entry.type == SharedEntryType.photo &&
        entry.mediaThumbnailBase64.isNotEmpty) {
      return _CachedBase64Image(
        data: entry.mediaThumbnailBase64,
        fit: BoxFit.cover,
        cacheWidth: 720,
      );
    }

    if (entry.type == SharedEntryType.sketch &&
        entry.sketchPages.isNotEmpty) {
      return DiarySketchPagePreview(page: entry.sketchPages.first);
    }

    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(entry.type.icon, size: 42),
            const SizedBox(height: 10),
            Text(
              entry.note.trim().isNotEmpty
                  ? entry.note.trim()
                  : entry.title.trim().isNotEmpty
                      ? entry.title.trim()
                      : entry.type.label,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SharedMemoryPeriodCard extends StatelessWidget {
  final SharedEntry cover;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool horizontal;

  const SharedMemoryPeriodCard({
    super.key,
    required this.cover,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.horizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    if (horizontal) {
      return Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 132,
            child: Row(
              children: [
                SizedBox(
                  width: 132,
                  child: SharedMemoryCover(entry: cover),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          subtitle,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: SharedMemoryCover(entry: cover)),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 2),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SharedMemoryTimelineTile extends StatelessWidget {
  final SharedEntry entry;
  final String author;
  final int hearts;
  final int comments;
  final String? seenLabel;
  final VoidCallback onTap;

  const SharedMemoryTimelineTile({
    super.key,
    required this.entry,
    required this.author,
    required this.hearts,
    required this.comments,
    required this.seenLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasPreview = entry.type == SharedEntryType.photo ||
        entry.type == SharedEntryType.sketch;

    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            SizedBox(
              width: hasPreview ? 92 : 68,
              height: 92,
              child: SharedMemoryCover(entry: entry),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title.trim().isEmpty
                          ? entry.type.label
                          : entry.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    if (entry.note.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        entry.note.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 5),
                    Text(
                      [
                        author,
                        if (hearts > 0) '❤️ $hearts',
                        if (comments > 0) '💬 $comments',
                        if (seenLabel != null) seenLabel!,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SharedMemoryCollectionScreen extends StatelessWidget {
  final String title;
  final SharedSpace space;
  final List<SharedEntry> entries;
  final Map<String, List<SharedEntryComment>> commentsByEntry;
  final Map<String, Set<String>> heartsByEntry;
  final Map<String, DateTime> memberReads;
  final String? currentUserId;

  const SharedMemoryCollectionScreen({
    super.key,
    required this.title,
    required this.space,
    required this.entries,
    required this.commentsByEntry,
    required this.heartsByEntry,
    required this.memberReads,
    required this.currentUserId,
  });

  String _author(SharedEntry entry) {
    if (entry.editorName.trim().isNotEmpty) return entry.editorName.trim();
    if (currentUserId != null && entry.updatedBy == currentUserId) {
      return 'Tu';
    }
    return 'Noi ♡';
  }

  String? _seen(SharedEntry entry) {
    if (currentUserId == null ||
        entry.updatedBy != currentUserId ||
        entry.updatedAt == null) {
      return null;
    }
    final count = memberReads.entries
        .where(
          (read) =>
              read.key != currentUserId &&
              !read.value.isBefore(entry.updatedAt!.toUtc()),
        )
        .length;
    if (count == 0) return null;
    return count == 1 ? 'Visto' : 'Visto da $count';
  }

  Future<void> _open(BuildContext context, SharedEntry entry) async {
    if (entry.type == SharedEntryType.photo) {
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => SharedPhotoViewerScreen(
            space: space,
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
            space: space,
            entry: entry,
          ),
        ),
      );
      return;
    }

    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => SharedMemoryDetailScreen(
          space: space,
          entry: entry,
          hearts: heartsByEntry[entry.id]?.length ?? 0,
          comments: commentsByEntry[entry.id]?.length ?? 0,
          author: _author(entry),
          seenLabel: _seen(entry),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final source = [...entries]
      ..sort((a, b) {
        final date = b.date.compareTo(a.date);
        if (date != 0) return date;
        return (b.updatedAt ?? b.date).compareTo(a.updatedAt ?? a.date);
      });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 100),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.76,
        ),
        itemCount: source.length,
        itemBuilder: (context, index) {
          final entry = source[index];
          return SharedMemoryTile(
            entry: entry,
            author: _author(entry),
            hearts: heartsByEntry[entry.id]?.length ?? 0,
            comments: commentsByEntry[entry.id]?.length ?? 0,
            seenLabel: _seen(entry),
            onTap: () => _open(context, entry),
          );
        },
      ),
    );
  }
}

class SharedSketchViewerScreen extends StatefulWidget {
  final SharedSpace space;
  final SharedEntry entry;

  const SharedSketchViewerScreen({
    super.key,
    required this.space,
    required this.entry,
  });

  @override
  State<SharedSketchViewerScreen> createState() =>
      _SharedSketchViewerScreenState();
}

class _SharedSketchViewerScreenState extends State<SharedSketchViewerScreen> {
  late final PageController pageController = PageController();
  int pageIndex = 0;

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = widget.entry.sketchPages;
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        foregroundColor: Colors.white,
        title: Text(
          widget.entry.title.trim().isEmpty
              ? 'Sketch'
              : widget.entry.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: pages.isEmpty
            ? const Center(
                child: Text(
                  'Sketch non disponibile.',
                  style: TextStyle(color: Colors.white70),
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: pageController,
                      itemCount: pages.length,
                      onPageChanged: (value) =>
                          setState(() => pageIndex = value),
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: InteractiveViewer(
                            minScale: 0.75,
                            maxScale: 6,
                            child: Center(
                              child: AspectRatio(
                                aspectRatio: 3 / 4,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: DiarySketchPagePreview(
                                    page: pages[index],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.white12),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.entry.note.trim().isNotEmpty) ...[
                          Text(
                            widget.entry.note,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _cap(
                                  DateFormat(
                                    'EEEE d MMMM yyyy',
                                    'it_IT',
                                  ).format(widget.entry.date),
                                ),
                                style: const TextStyle(
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                            Text(
                              'Pagina ${pageIndex + 1}/${pages.length}',
                              style: const TextStyle(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class SharedMemoryDetailScreen extends StatelessWidget {
  final SharedSpace space;
  final SharedEntry entry;
  final int hearts;
  final int comments;
  final String author;
  final String? seenLabel;

  const SharedMemoryDetailScreen({
    super.key,
    required this.space,
    required this.entry,
    required this.hearts,
    required this.comments,
    required this.author,
    required this.seenLabel,
  });

  String _timeLabel() {
    if (entry.start == null) return '';
    final start =
        '${entry.start!.hour.toString().padLeft(2, '0')}:${entry.start!.minute.toString().padLeft(2, '0')}';
    if (entry.end == null) return start;
    final end =
        '${entry.end!.hour.toString().padLeft(2, '0')}:${entry.end!.minute.toString().padLeft(2, '0')}';
    return '$start–$end';
  }

  @override
  Widget build(BuildContext context) {
    final time = _timeLabel();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          entry.type.label,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          SimpleCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(child: Icon(entry.type.icon)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.title.trim().isEmpty
                            ? entry.type.label
                            : entry.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                        ),
                      ),
                    ),
                  ],
                ),
                if (entry.note.trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    entry.note.trim(),
                    style: const TextStyle(fontSize: 16, height: 1.35),
                  ),
                ],
                const SizedBox(height: 18),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: Text(
                    _cap(
                      DateFormat(
                        'EEEE d MMMM yyyy',
                        'it_IT',
                      ).format(entry.date),
                    ),
                  ),
                  subtitle: time.isEmpty ? null : Text(time),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person_outline),
                  title: Text(author),
                  subtitle: Text(space.name),
                ),
                if (hearts > 0 || comments > 0 || seenLabel != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.favorite_outline),
                    title: Text(
                      [
                        if (hearts > 0) '❤️ $hearts',
                        if (comments > 0) '💬 $comments',
                        if (seenLabel != null) seenLabel!,
                      ].join(' · '),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
