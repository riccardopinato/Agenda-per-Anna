part of '../../main.dart';

class DiaryMemoriesScreen extends StatefulWidget {
  final AgendaStore store;
  final String? personId;
  final String? personName;

  const DiaryMemoriesScreen({
    super.key,
    required this.store,
    this.personId,
    this.personName,
  });

  @override
  State<DiaryMemoriesScreen> createState() => _DiaryMemoriesScreenState();
}

class _DiaryMemoriesScreenState extends State<DiaryMemoriesScreen> {
  final TextEditingController searchController = TextEditingController();
  DiaryBlockType? filter;
  _DiaryMemoriesView view = _DiaryMemoriesView.memories;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<_DiaryMemoryRecord> _allRecords() {
    final result = <_DiaryMemoryRecord>[];
    for (final entry in widget.store.journals.entries) {
      final date = DateTime.tryParse(entry.key);
      if (date == null) continue;
      for (final block in entry.value.blocks) {
        result.add(_DiaryMemoryRecord(date: date, block: block));
      }
    }
    result.sort((a, b) {
      final dateOrder = b.date.compareTo(a.date);
      if (dateOrder != 0) return dateOrder;
      return b.block.createdAt.compareTo(a.block.createdAt);
    });
    return result;
  }

  bool _matchesSearch(_DiaryMemoryRecord record, String query) {
    if (query.isEmpty) return true;
    final block = record.block;
    final sketchText = block.pages
        .expand((page) => page.textElements)
        .map((element) => element.text)
        .join(' ');
    final peopleText = widget.store
        .peopleForIds(block.personIds)
        .map((person) => '${person.name} ${person.relationship}')
        .join(' ');
    final searchable = [
      block.text,
      sketchText,
      peopleText,
      DateFormat('d MMMM yyyy', 'it_IT').format(record.date),
      DateFormat('MMMM yyyy', 'it_IT').format(record.date),
      '${record.date.year}',
      switch (block.type) {
        DiaryBlockType.note => 'nota note',
        DiaryBlockType.sketch => 'sketch disegno',
        DiaryBlockType.photo => 'foto immagine',
        DiaryBlockType.voice => 'voce audio registrazione',
      },
    ].join(' ').toLowerCase();
    return searchable.contains(query);
  }

  List<_DiaryMemoryRecord> _records() {
    final query = searchController.text.trim().toLowerCase();
    return _allRecords().where((record) {
      if (widget.personId != null &&
          !record.block.personIds.contains(widget.personId)) {
        return false;
      }
      if (filter != null && record.block.type != filter) return false;
      return _matchesSearch(record, query);
    }).toList();
  }

  Map<String, List<_DiaryMemoryRecord>> _groupByDay(
    List<_DiaryMemoryRecord> records,
  ) {
    final result = <String, List<_DiaryMemoryRecord>>{};
    for (final record in records) {
      final key = AgendaStore.dateKey(record.date);
      result.putIfAbsent(key, () => []).add(record);
    }
    return result;
  }

  Map<String, List<_DiaryMemoryRecord>> _groupByMonth(
    List<_DiaryMemoryRecord> records,
  ) {
    final result = <String, List<_DiaryMemoryRecord>>{};
    for (final record in records) {
      final key =
          '${record.date.year}-${record.date.month.toString().padLeft(2, '0')}';
      result.putIfAbsent(key, () => []).add(record);
    }
    return result;
  }

  Map<int, List<_DiaryMemoryRecord>> _groupByYear(
    List<_DiaryMemoryRecord> records,
  ) {
    final result = <int, List<_DiaryMemoryRecord>>{};
    for (final record in records) {
      result.putIfAbsent(record.date.year, () => []).add(record);
    }
    return result;
  }

  _DiaryMemoryRecord _coverRecord(List<_DiaryMemoryRecord> records) {
    for (final record in records) {
      if (record.block.type == DiaryBlockType.photo &&
          record.block.hasPhotoMedia) {
        return record;
      }
    }
    for (final record in records) {
      if (record.block.type == DiaryBlockType.sketch) return record;
    }
    return records.first;
  }

  int _countType(
    List<_DiaryMemoryRecord> records,
    DiaryBlockType type,
  ) =>
      records.where((record) => record.block.type == type).length;

  int _distinctDays(List<_DiaryMemoryRecord> records) =>
      records.map((record) => AgendaStore.dateKey(record.date)).toSet().length;

  Future<void> _openRecord(_DiaryMemoryRecord record) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlannerScreen(
          store: widget.store,
          initialDate: record.date,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openPhoto(_DiaryMemoryRecord record) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DiaryPhotoViewerScreen(
          store: widget.store,
          date: record.date,
          block: record.block,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Widget _coverPreview(
    BuildContext context,
    _DiaryMemoryRecord record, {
    BoxFit fit = BoxFit.cover,
  }) {
    final block = record.block;
    switch (block.type) {
      case DiaryBlockType.photo:
        if (!block.hasPhotoMedia) {
          return const ColoredBox(
            color: Color(0xFFF2EEF5),
            child: Center(child: Icon(Icons.photo_outlined, size: 42)),
          );
        }
        return DiaryMediaImage(
          assetId: block.mediaThumbnailAssetId.isNotEmpty
              ? block.mediaThumbnailAssetId
              : block.mediaAssetId,
          fallbackBase64: block.imageBase64,
          fit: fit,
          cacheWidth: 720,
          empty: const ColoredBox(
            color: Color(0xFFF2EEF5),
            child: Center(child: Icon(Icons.broken_image_outlined)),
          ),
        );
      case DiaryBlockType.sketch:
        final page = block.pages.isEmpty
            ? DiarySketchPage(id: block.id)
            : block.pages.first;
        return DiarySketchPagePreview(page: page);
      case DiaryBlockType.voice:
        return ColoredBox(
          color: Theme.of(context).colorScheme.secondaryContainer,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.mic_none_outlined, size: 48),
                const SizedBox(height: 8),
                Text(
                  block.audioDurationMs <= 0
                      ? 'Nota vocale'
                      : _formatVoiceDuration(block.audioDurationMs),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        );
      case DiaryBlockType.note:
        return ColoredBox(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(
                block.text,
                maxLines: 8,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ),
          ),
        );
    }
  }

  Widget _memoryTile(
    BuildContext context,
    _DiaryMemoryRecord record,
  ) {
    final block = record.block;
    final date = DateFormat('d MMMM yyyy', 'it_IT').format(record.date);

    switch (block.type) {
      case DiaryBlockType.photo:
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _openPhoto(record),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _coverPreview(context, record)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          block.text.trim().isEmpty ? date : block.text,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Apri giornata',
                        onPressed: () => _openRecord(record),
                        icon: const Icon(Icons.calendar_today_outlined, size: 19),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      case DiaryBlockType.sketch:
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _openRecord(record),
            child: Column(
              children: [
                Expanded(child: _coverPreview(context, record)),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      const Icon(Icons.draw_outlined, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '$date · ${block.pages.length} pag.',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      case DiaryBlockType.voice:
        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _openRecord(record),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.mic_none_outlined),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Text(
                      block.text.trim().isEmpty ? 'Nota vocale' : block.text,
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    block.audioDurationMs <= 0
                        ? date
                        : '${_formatVoiceDuration(block.audioDurationMs)} · $date',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        );
      case DiaryBlockType.note:
        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _openRecord(record),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.sticky_note_2_outlined),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Text(
                      block.text,
                      maxLines: 8,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    date,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        );
    }
  }

  Widget _dayCoverCard(
    BuildContext context,
    List<_DiaryMemoryRecord> records,
  ) {
    final cover = _coverRecord(records);
    final date = cover.date;
    final journal = widget.store.journal(date);
    final noteCount = _countType(records, DiaryBlockType.note);
    final sketchCount = _countType(records, DiaryBlockType.sketch);
    final photoCount = _countType(records, DiaryBlockType.photo);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openRecord(cover),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _coverPreview(context, cover),
                  Positioned(
                    left: 10,
                    top: 10,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.58),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        child: Text(
                          DateFormat('d MMM', 'it_IT').format(date),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (journal.mood != null)
                    Positioned(
                      right: 10,
                      top: 8,
                      child: Text(
                        journal.mood!.emoji,
                        style: const TextStyle(fontSize: 25),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 10, 11, 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _cap(DateFormat('EEEE d MMMM', 'it_IT').format(date)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (photoCount > 0) '$photoCount foto',
                      if (sketchCount > 0) '$sketchCount sketch',
                      if (noteCount > 0) '$noteCount note',
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _periodCard(
    BuildContext context, {
    required List<_DiaryMemoryRecord> records,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    final cover = _coverRecord(records);
    final photos = _countType(records, DiaryBlockType.photo);
    final sketches = _countType(records, DiaryBlockType.sketch);
    final notes = _countType(records, DiaryBlockType.note);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 172,
          child: Row(
            children: [
              SizedBox(
                width: 142,
                child: _coverPreview(context, cover),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(icon, size: 19),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const Spacer(),
                      Text(
                        [
                          if (photos > 0) '$photos foto',
                          if (sketches > 0) '$sketches sketch',
                          if (notes > 0) '$notes note',
                        ].join(' · '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _memoriesView(
    BuildContext context,
    List<_DiaryMemoryRecord> records,
  ) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.82,
      ),
      itemCount: records.length,
      itemBuilder: (context, index) => _memoryTile(context, records[index]),
    );
  }

  Widget _daysView(
    BuildContext context,
    List<_DiaryMemoryRecord> records,
  ) {
    final groups = _groupByDay(records).values.toList();
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.78,
      ),
      itemCount: groups.length,
      itemBuilder: (context, index) => _dayCoverCard(
        context,
        groups[index],
      ),
    );
  }

  Widget _monthsView(
    BuildContext context,
    List<_DiaryMemoryRecord> records,
  ) {
    final groups = _groupByMonth(records);
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      children: groups.entries.map((entry) {
        final bucket = entry.value;
        final date = bucket.first.date;
        return _periodCard(
          context,
          records: bucket,
          title: _cap(DateFormat('MMMM yyyy', 'it_IT').format(date)),
          subtitle:
              '${_distinctDays(bucket)} giornate con ricordi · ${bucket.length} contenuti',
          icon: Icons.calendar_month_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MonthScreen(
                store: widget.store,
                initialMonth: DateTime(date.year, date.month),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _yearsView(
    BuildContext context,
    List<_DiaryMemoryRecord> records,
  ) {
    final groups = _groupByYear(records);
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      children: groups.entries.map((entry) {
        final year = entry.key;
        final bucket = entry.value;
        final months =
            bucket.map((record) => record.date.month).toSet().length;
        return _periodCard(
          context,
          records: bucket,
          title: '$year',
          subtitle:
              '$months mesi · ${_distinctDays(bucket)} giornate con ricordi',
          icon: Icons.insights_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => YearScreen(
                store: widget.store,
                initialYear: year,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _emptyState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Text(
            widget.personName == null
                ? 'Nessun ricordo corrisponde a questa ricerca. Aggiungi una nota, una foto o uno sketch in una giornata.'
                : 'Nessun ricordo collegato a ${widget.personName}. Apri un ricordo e usa “Collega persone”.',
            textAlign: TextAlign.center,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.personName == null
              ? 'I miei ricordi'
              : 'Ricordi con ${widget.personName}',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          widget.store.journalRevision,
          widget.store.planningRevision,
        ]),
        builder: (context, _) {
          final current = _records();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 2, 12, 4),
                child: SearchBar(
                  controller: searchController,
                  hintText: 'Cerca nei ricordi...',
                  leading: const Icon(Icons.search),
                  trailing: searchController.text.isEmpty
                      ? null
                      : [
                          IconButton(
                            tooltip: 'Cancella ricerca',
                            onPressed: () {
                              searchController.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.close),
                          ),
                        ],
                  onChanged: (_) => setState(() {}),
                ),
              ),
              SizedBox(
                height: 52,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  scrollDirection: Axis.horizontal,
                  children: [
                    ChoiceChip(
                      selected: view == _DiaryMemoriesView.memories,
                      avatar: const Icon(Icons.auto_awesome_outlined),
                      label: const Text('Ricordi'),
                      onSelected: (_) =>
                          setState(() => view = _DiaryMemoriesView.memories),
                    ),
                    const SizedBox(width: 7),
                    ChoiceChip(
                      selected: view == _DiaryMemoriesView.days,
                      avatar: const Icon(Icons.today_outlined),
                      label: const Text('Giornate'),
                      onSelected: (_) =>
                          setState(() => view = _DiaryMemoriesView.days),
                    ),
                    const SizedBox(width: 7),
                    ChoiceChip(
                      selected: view == _DiaryMemoriesView.months,
                      avatar: const Icon(Icons.calendar_month_outlined),
                      label: const Text('Mesi'),
                      onSelected: (_) =>
                          setState(() => view = _DiaryMemoriesView.months),
                    ),
                    const SizedBox(width: 7),
                    ChoiceChip(
                      selected: view == _DiaryMemoriesView.years,
                      avatar: const Icon(Icons.insights_outlined),
                      label: const Text('Anni'),
                      onSelected: (_) =>
                          setState(() => view = _DiaryMemoriesView.years),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 50,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  scrollDirection: Axis.horizontal,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 7),
                      child: FilterChip(
                        selected: filter == null,
                        label: const Text('Tutti'),
                        avatar: const Icon(Icons.layers_outlined),
                        onSelected: (_) => setState(() => filter = null),
                      ),
                    ),
                    ...DiaryBlockType.values.map(
                      (type) => Padding(
                        padding: const EdgeInsets.only(right: 7),
                        child: FilterChip(
                          selected: filter == type,
                          avatar: Icon(
                            switch (type) {
                              DiaryBlockType.note =>
                                Icons.sticky_note_2_outlined,
                              DiaryBlockType.sketch => Icons.draw_outlined,
                              DiaryBlockType.photo => Icons.photo_outlined,
                              DiaryBlockType.voice => Icons.mic_none_outlined,
                            },
                          ),
                          label: Text(
                            switch (type) {
                              DiaryBlockType.note => 'Note',
                              DiaryBlockType.sketch => 'Sketch',
                              DiaryBlockType.photo => 'Foto',
                              DiaryBlockType.voice => 'Voce',
                            },
                          ),
                          onSelected: (_) => setState(() => filter = type),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 7),
                child: Row(
                  children: [
                    Text(
                      current.isEmpty
                          ? 'Nessun risultato'
                          : '${current.length} ricordi · ${_distinctDays(current)} giornate',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Spacer(),
                    if (searchController.text.isNotEmpty)
                      const Icon(Icons.manage_search, size: 18),
                  ],
                ),
              ),
              Expanded(
                child: current.isEmpty
                    ? _emptyState()
                    : switch (view) {
                        _DiaryMemoriesView.memories =>
                          _memoriesView(context, current),
                        _DiaryMemoriesView.days =>
                          _daysView(context, current),
                        _DiaryMemoriesView.months =>
                          _monthsView(context, current),
                        _DiaryMemoriesView.years =>
                          _yearsView(context, current),
                      },
              ),
            ],
          );
        },
      ),
    );
  }
}
