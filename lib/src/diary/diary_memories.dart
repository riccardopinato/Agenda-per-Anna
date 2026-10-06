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

  List<DiaryBlockReference> _allRecords() =>
      widget.store.memoryReferences(
        includeArchived: true,
        personId: widget.personId,
      );

  bool _matchesSearch(DiaryBlockReference record, String query) {
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
      ...block.places.map((place) => place.name),
      DateFormat('d MMMM yyyy', AnnaStrings.intlLocale(context)).format(record.date),
      DateFormat('MMMM yyyy', AnnaStrings.intlLocale(context)).format(record.date),
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

  List<DiaryBlockReference> _records() {
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

  Map<String, List<DiaryBlockReference>> _groupByDay(
    List<DiaryBlockReference> records,
  ) {
    final result = <String, List<DiaryBlockReference>>{};
    for (final record in records) {
      final key = AgendaStore.dateKey(record.date);
      result.putIfAbsent(key, () => []).add(record);
    }
    return result;
  }

  Map<String, List<DiaryBlockReference>> _groupByMonth(
    List<DiaryBlockReference> records,
  ) {
    final result = <String, List<DiaryBlockReference>>{};
    for (final record in records) {
      final key =
          '${record.date.year}-${record.date.month.toString().padLeft(2, '0')}';
      result.putIfAbsent(key, () => []).add(record);
    }
    return result;
  }

  Map<int, List<DiaryBlockReference>> _groupByYear(
    List<DiaryBlockReference> records,
  ) {
    final result = <int, List<DiaryBlockReference>>{};
    for (final record in records) {
      result.putIfAbsent(record.date.year, () => []).add(record);
    }
    return result;
  }

  DiaryBlockReference _coverRecord(List<DiaryBlockReference> records) {
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
    List<DiaryBlockReference> records,
    DiaryBlockType type,
  ) =>
      records.where((record) => record.block.type == type).length;

  int _distinctDays(List<DiaryBlockReference> records) =>
      records.map((record) => AgendaStore.dateKey(record.date)).toSet().length;

  Future<void> _openRecord(DiaryBlockReference record) async {
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

  Future<void> _openPhoto(DiaryBlockReference record) async {
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
    DiaryBlockReference record, {
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
                      ? AnnaStrings.of(context).v100VoiceNote
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
    DiaryBlockReference record,
  ) {
    final block = record.block;
    final date = DateFormat('d MMMM yyyy', AnnaStrings.intlLocale(context)).format(record.date);

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
                        tooltip: AnnaStrings.of(context).v100OpenDay,
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
                          '$date · ${AnnaStrings.of(context).v100Pages(block.pages.length)}',
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
                      block.text.trim().isEmpty ? AnnaStrings.of(context).v100VoiceNote : block.text,
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
    List<DiaryBlockReference> records,
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
                          DateFormat('d MMM', AnnaStrings.intlLocale(context)).format(date),
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
                    _cap(DateFormat('EEEE d MMMM', AnnaStrings.intlLocale(context)).format(date)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (photoCount > 0) AnnaStrings.of(context).v100Photos(photoCount),
                      if (sketchCount > 0) AnnaStrings.of(context).v100Sketches(sketchCount),
                      if (noteCount > 0) AnnaStrings.of(context).v100Notes(noteCount),
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
    required List<DiaryBlockReference> records,
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
                          if (photos > 0) AnnaStrings.of(context).v100Photos(photos),
                          if (sketches > 0) AnnaStrings.of(context).v100Sketches(sketches),
                          if (notes > 0) AnnaStrings.of(context).v100Notes(notes),
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

  Widget _recallSectionHeader(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 21),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _recallMemoryRow(
    BuildContext context,
    DiaryBlockReference record,
  ) {
    final block = record.block;
    final title = widget.store.diaryBlockDisplayTitle(block);
    final date = DateFormat('d MMMM yyyy', AnnaStrings.intlLocale(context)).format(record.date);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openRecord(record),
        child: SizedBox(
          height: 104,
          child: Row(
            children: [
              SizedBox(
                width: 104,
                child: _coverPreview(context, record),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(13, 11, 10, 11),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const Spacer(),
                      Text(
                        date,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (block.personIds.isNotEmpty ||
                          block.places.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          [
                            if (block.personIds.isNotEmpty)
                              AnnaStrings.of(context).v100PeopleCount(block.personIds.length),
                            if (block.places.isNotEmpty)
                              AnnaStrings.of(context).v100PlacesCount(block.places.length),
                          ].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _recallFacetSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<MemoryRecallFacet> facets,
  }) {
    if (facets.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _recallSectionHeader(
          context,
          title: title,
          subtitle: AnnaStrings.of(context).v100DerivedConnections,
          icon: icon,
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: facets.map((facet) {
            return ActionChip(
              avatar: Icon(
                facet.kind == MemoryRecallFacetKind.person
                    ? Icons.person_outline
                    : Icons.place_outlined,
                size: 18,
              ),
              label: Text('${facet.label} · ${facet.count}'),
              onPressed: () {
                if (facet.kind == MemoryRecallFacetKind.person) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DiaryMemoriesScreen(
                        store: widget.store,
                        personId: facet.id,
                        personName: facet.label,
                      ),
                    ),
                  );
                  return;
                }

                searchController.text = facet.label;
                setState(() {
                  filter = null;
                  view = _DiaryMemoriesView.memories;
                });
              },
            );
          }).toList(growable: false),
        ),
      ],
    );
  }

  Widget _rediscoverView(
    BuildContext context,
    List<DiaryBlockReference> records,
  ) {
    final now = DateTime.now();
    final snapshot = widget.store.memoryRecallSnapshot(
      now,
      personId: widget.personId,
      references: records,
    );
    final linkedPeople = snapshot.people
        .where((facet) => facet.id != widget.personId)
        .take(8)
        .toList(growable: false);
    final linkedPlaces = snapshot.places.take(8).toList(growable: false);
    final alreadyShown = <String>{
      ...snapshot.onThisDay.take(4).map((entry) => entry.block.id),
      ...snapshot.sameMonthPastYears.take(4).map((entry) => entry.block.id),
    };
    final yearHighlights = snapshot.yearHighlights
        .where((entry) => !alreadyShown.contains(entry.block.id))
        .take(6)
        .toList(growable: false);
    final monthName = _cap(DateFormat('MMMM', AnnaStrings.intlLocale(context)).format(now));

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
      children: [
        Text(
          AnnaStrings.of(context).v100RediscoverTitle,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          snapshot.isEmpty
              ? AnnaStrings.of(context).v100RediscoverEmpty
              : AnnaStrings.of(context).v100RediscoverYears(snapshot.historicalYears),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (snapshot.onThisDay.isNotEmpty) ...[
          _recallSectionHeader(
            context,
            title: AnnaStrings.of(context).v100OnThisDayPast,
            subtitle: AnnaStrings.of(context).v100SameDatePast(snapshot.onThisDay.length),
            icon: Icons.history_toggle_off,
          ),
          ...snapshot.onThisDay.take(4).map(
                (record) => _recallMemoryRow(context, record),
              ),
        ],
        if (snapshot.sameMonthPastYears.isNotEmpty) ...[
          _recallSectionHeader(
            context,
            title: AnnaStrings.of(context).v100MonthAcrossYears(monthName),
            subtitle: AnnaStrings.of(context).v100OtherSameMonth,
            icon: Icons.calendar_month_outlined,
          ),
          ...snapshot.sameMonthPastYears.take(4).map(
                (record) => _recallMemoryRow(context, record),
              ),
        ],
        if (yearHighlights.isNotEmpty) ...[
          _recallSectionHeader(
            context,
            title: AnnaStrings.of(context).v100JumpAcrossYears,
            subtitle:
                AnnaStrings.of(context).v100RepresentativeMoment,
            icon: Icons.auto_awesome_outlined,
          ),
          ...yearHighlights.map(
            (record) => _recallMemoryRow(context, record),
          ),
        ],
        if (widget.personId == null)
          _recallFacetSection(
            context,
            title: AnnaStrings.of(context).v100RecurringPeople,
            icon: Icons.people_outline,
            facets: linkedPeople,
          ),
        _recallFacetSection(
          context,
          title: widget.personId == null
              ? AnnaStrings.of(context).v100RecurringPlaces
              : AnnaStrings.of(context).v100PlacesTogether,
          icon: Icons.place_outlined,
          facets: linkedPlaces,
        ),
      ],
    );
  }

  Widget _memoriesView(
    BuildContext context,
    List<DiaryBlockReference> records,
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
    List<DiaryBlockReference> records,
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
    List<DiaryBlockReference> records,
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
          title: _cap(DateFormat('MMMM yyyy', AnnaStrings.intlLocale(context)).format(date)),
          subtitle: AnnaStrings.of(context).v100DaysContents(_distinctDays(bucket), bucket.length),
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
    List<DiaryBlockReference> records,
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
          subtitle: AnnaStrings.of(context).v100MonthsDays(months, _distinctDays(bucket)),
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
                ? AnnaStrings.of(context).v100MemoryNoMatch
                : AnnaStrings.of(context).v100NoMemoriesForPerson(widget.personName!),
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
              ? AnnaStrings.of(context).v100MyMemories
              : AnnaStrings.of(context).v100MemoriesWithPerson(widget.personName!),
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
                  hintText: AnnaStrings.of(context).v100MemorySearchHint,
                  leading: const Icon(Icons.search),
                  trailing: searchController.text.isEmpty
                      ? null
                      : [
                          IconButton(
                            tooltip: AnnaStrings.of(context).v100ClearSearch,
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
                      label: Text(AnnaStrings.of(context).memories),
                      onSelected: (_) =>
                          setState(() => view = _DiaryMemoriesView.memories),
                    ),
                    const SizedBox(width: 7),
                    ChoiceChip(
                      selected: view == _DiaryMemoriesView.rediscover,
                      avatar: const Icon(Icons.history_toggle_off),
                      label: Text(AnnaStrings.of(context).v100Rediscover),
                      onSelected: (_) =>
                          setState(() => view = _DiaryMemoriesView.rediscover),
                    ),
                    const SizedBox(width: 7),
                    ChoiceChip(
                      selected: view == _DiaryMemoriesView.days,
                      avatar: const Icon(Icons.today_outlined),
                      label: Text(AnnaStrings.of(context).v100Days),
                      onSelected: (_) =>
                          setState(() => view = _DiaryMemoriesView.days),
                    ),
                    const SizedBox(width: 7),
                    ChoiceChip(
                      selected: view == _DiaryMemoriesView.months,
                      avatar: const Icon(Icons.calendar_month_outlined),
                      label: Text(AnnaStrings.of(context).v100Months),
                      onSelected: (_) =>
                          setState(() => view = _DiaryMemoriesView.months),
                    ),
                    const SizedBox(width: 7),
                    ChoiceChip(
                      selected: view == _DiaryMemoriesView.years,
                      avatar: const Icon(Icons.insights_outlined),
                      label: Text(AnnaStrings.of(context).v100Years),
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
                        label: Text(AnnaStrings.of(context).all),
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
                              DiaryBlockType.note => AnnaStrings.of(context).v100MemoryNotesFilter,
                              DiaryBlockType.sketch => AnnaStrings.of(context).v100Sketch,
                              DiaryBlockType.photo => AnnaStrings.of(context).v100Photo,
                              DiaryBlockType.voice => AnnaStrings.of(context).v100MemoryVoiceFilter,
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
                          ? AnnaStrings.of(context).v100NoResults
                          : AnnaStrings.of(context).v100MemorySummary(current.length, _distinctDays(current)),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Spacer(),
                    if (searchController.text.isNotEmpty)
                      const Icon(Icons.manage_search, size: 18),
                  ],
                ),
              ),
              Expanded(
                child: switch (view) {
                  _DiaryMemoriesView.rediscover =>
                    _rediscoverView(context, current),
                  _DiaryMemoriesView.memories => current.isEmpty
                      ? _emptyState()
                      : _memoriesView(context, current),
                  _DiaryMemoriesView.days => current.isEmpty
                      ? _emptyState()
                      : _daysView(context, current),
                  _DiaryMemoriesView.months => current.isEmpty
                      ? _emptyState()
                      : _monthsView(context, current),
                  _DiaryMemoriesView.years => current.isEmpty
                      ? _emptyState()
                      : _yearsView(context, current),
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
