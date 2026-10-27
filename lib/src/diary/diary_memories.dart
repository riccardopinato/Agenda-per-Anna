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
  bool searchExpanded = false;
  _DiaryMemoriesView view = _DiaryMemoriesView.forYou;

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
        DiaryBlockType.note => 'note nota notas journal diario diário',
        DiaryBlockType.sketch => 'sketch drawing dibujo dessin disegno desenho',
        DiaryBlockType.photo => 'photo foto image imagen immagine photographie imagem',
        DiaryBlockType.voice => 'voice voz voix audio recording registrazione grabación gravação',
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
    final title = widget.store.diaryBlockDisplayTitle(
      block,
      strings: AnnaStrings.of(context),
    );
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
                  searchExpanded = true;
                  view = _DiaryMemoriesView.timeline;
                });
              },
            );
          }).toList(growable: false),
        ),
      ],
    );
  }

  Widget _forYouHero(
    BuildContext context,
    DiaryBlockReference record,
  ) {
    final strings = AnnaStrings.of(context);
    final title = widget.store.diaryBlockDisplayTitle(
      record.block,
      strings: strings,
    );
    final date = DateFormat(
      'd MMMM yyyy',
      AnnaStrings.intlLocale(context),
    ).format(record.date);

    return Semantics(
      identifier: 'memories-for-you-hero',
      button: true,
      label: '$title · $date',
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.only(top: AnnaDesignTokens.spaceMd),
        child: InkWell(
          onTap: () => _openRecord(record),
          child: SizedBox(
            height: 286,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _coverPreview(context, record),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.72),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                Positioned(
                  left: AnnaDesignTokens.spaceMd,
                  right: AnnaDesignTokens.spaceMd,
                  bottom: AnnaDesignTokens.spaceMd,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.46),
                          borderRadius: BorderRadius.circular(
                            AnnaDesignTokens.radiusLg,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AnnaDesignTokens.spaceSm,
                            vertical: AnnaDesignTokens.space2xs,
                          ),
                          child: Text(
                            strings.d3('memoriesFeatured'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AnnaDesignTokens.spaceSm),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          height: 1.1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AnnaDesignTokens.spaceXs),
                      Text(
                        date,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Future<void> _showMemoryMap() async {
    final strings = AnnaStrings.of(context);
    final snapshot = widget.store.memoryMapSnapshot(
      personId: widget.personId,
      references: _records(),
    );
    final located = snapshot.locatedPlaces.take(24).toList(growable: false);
    final unlocated = snapshot.unlocatedPlaces.take(12).toList(growable: false);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Semantics(
          identifier: 'memory-map-surface',
          child: FractionallySizedBox(
            heightFactor: 0.86,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AnnaDesignTokens.spaceMd,
                0,
                AnnaDesignTokens.spaceMd,
                AnnaDesignTokens.spaceLg,
              ),
              children: [
                Text(
                  strings.d3('memoryMapTitle'),
                  style: Theme.of(sheetContext)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: AnnaDesignTokens.space2xs),
                Text(strings.d3('memoryMapIntro')),
                const SizedBox(height: AnnaDesignTokens.spaceMd),
                Text(
                  strings.d3Format(
                    'memoryMapSummary',
                    {
                      'located': snapshot.locatedPlaces.length,
                      'total': snapshot.places.length,
                    },
                  ),
                  style: Theme.of(sheetContext)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: AnnaDesignTokens.spaceSm),
                if (snapshot.isEmpty)
                  SimpleCard(
                    child: Text(strings.d3('memoryMapNoPlaces')),
                  )
                else if (located.isNotEmpty)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      const mapHeight = 250.0;
                      final mapWidth = constraints.maxWidth;
                      return Semantics(
                        identifier: 'memory-map-canvas',
                        child: SizedBox(
                          height: mapHeight,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                      AnnaDesignTokens.radiusLg,
                                    ),
                                    gradient: LinearGradient(
                                      colors: [
                                        Theme.of(context)
                                            .colorScheme
                                            .primaryContainer,
                                        Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: CustomPaint(
                                    painter: _MemoryMapGridPainter(
                                      lineColor: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.10),
                                    ),
                                  ),
                                ),
                              ),
                              ...located.map((place) {
                                final x =
                                    (((place.longitude ?? 0) + 180) / 360)
                                        .clamp(0.0, 1.0)
                                        .toDouble();
                                final y =
                                    ((90 - (place.latitude ?? 0)) / 180)
                                        .clamp(0.0, 1.0)
                                        .toDouble();
                                return Positioned(
                                  left: 6 + x * (mapWidth - 44),
                                  top: 6 + y * (mapHeight - 44),
                                  child: Tooltip(
                                    message:
                                        '${place.label} · ${place.count}',
                                    child: Semantics(
                                      button: true,
                                      label:
                                          '${place.label}, ${place.count}',
                                      child: IconButton.filled(
                                        iconSize: 18,
                                        onPressed: () {
                                          Navigator.pop(sheetContext);
                                          searchController.text = place.label;
                                          setState(() {
                                            filter = null;
                                            searchExpanded = true;
                                            view =
                                                _DiaryMemoriesView.timeline;
                                          });
                                        },
                                        icon: Text(
                                          '${place.count}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                if (unlocated.isNotEmpty) ...[
                  const SizedBox(height: AnnaDesignTokens.spaceLg),
                  Text(
                    strings.d3('memoryMapNoCoordinates'),
                    style: Theme.of(sheetContext)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: AnnaDesignTokens.spaceXs),
                  Wrap(
                    spacing: AnnaDesignTokens.spaceXs,
                    runSpacing: AnnaDesignTokens.spaceXs,
                    children: unlocated
                        .map(
                          (place) => ActionChip(
                            avatar:
                                const Icon(Icons.place_outlined, size: 18),
                            label:
                                Text('${place.label} · ${place.count}'),
                            onPressed: () {
                              Navigator.pop(sheetContext);
                              searchController.text = place.label;
                              setState(() {
                                filter = null;
                                searchExpanded = true;
                                view = _DiaryMemoriesView.timeline;
                              });
                            },
                          ),
                        )
                        .toList(growable: false),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showThenNow() async {
    final strings = AnnaStrings.of(context);
    final pairs = widget.store
        .memoryMapSnapshot(
          personId: widget.personId,
          references: _records(),
        )
        .thenNow
        .take(20)
        .toList(growable: false);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Semantics(
          identifier: 'memories-then-now-surface',
          child: FractionallySizedBox(
            heightFactor: 0.86,
            child: pairs.isEmpty
                ? Center(
                    child: Padding(
                      padding:
                          const EdgeInsets.all(AnnaDesignTokens.spaceLg),
                      child: Text(
                        strings.d3('thenNowEmpty'),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AnnaDesignTokens.spaceMd,
                      0,
                      AnnaDesignTokens.spaceMd,
                      AnnaDesignTokens.spaceLg,
                    ),
                    children: [
                      Text(
                        strings.d3('thenNowTitle'),
                        style: Theme.of(sheetContext)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(
                        height: AnnaDesignTokens.space2xs,
                      ),
                      Text(strings.d3('thenNowIntro')),
                      const SizedBox(height: AnnaDesignTokens.spaceMd),
                      ...pairs.map(
                        (pair) => Card(
                          margin: const EdgeInsets.only(
                            bottom: AnnaDesignTokens.spaceMd,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(
                              AnnaDesignTokens.spaceMd,
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.place_outlined),
                                    const SizedBox(
                                      width: AnnaDesignTokens.spaceXs,
                                    ),
                                    Expanded(
                                      child: Text(
                                        pair.place.label,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    if (pair.yearsApart > 0)
                                      Text(
                                        strings.d3Format(
                                          'thenNowYears',
                                          {
                                            'years': pair.yearsApart,
                                          },
                                        ),
                                        style: Theme.of(sheetContext)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                  ],
                                ),
                                const SizedBox(
                                  height: AnnaDesignTokens.spaceXs,
                                ),
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(
                                    Icons.history_outlined,
                                  ),
                                  title:
                                      Text(strings.d3('thenNowThen')),
                                  subtitle: Text(
                                    "${DateFormat('d MMM yyyy', AnnaStrings.intlLocale(sheetContext)).format(pair.thenMemory.date)} · ${widget.store.diaryBlockDisplayTitle(pair.thenMemory.block, strings: strings)}",
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing:
                                      const Icon(Icons.chevron_right),
                                  onTap: () {
                                    Navigator.pop(sheetContext);
                                    unawaited(
                                      _openRecord(pair.thenMemory),
                                    );
                                  },
                                ),
                                const Divider(height: 1),
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading:
                                      const Icon(Icons.today_outlined),
                                  title: Text(strings.d3('thenNowNow')),
                                  subtitle: Text(
                                    "${DateFormat('d MMM yyyy', AnnaStrings.intlLocale(sheetContext)).format(pair.nowMemory.date)} · ${widget.store.diaryBlockDisplayTitle(pair.nowMemory.block, strings: strings)}",
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing:
                                      const Icon(Icons.chevron_right),
                                  onTap: () {
                                    Navigator.pop(sheetContext);
                                    unawaited(
                                      _openRecord(pair.nowMemory),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _forYouView(
    BuildContext context,
    List<DiaryBlockReference> records,
  ) {
    final strings = AnnaStrings.of(context);
    final now = DateTime.now();
    final snapshot = widget.store.memoryRecallSnapshot(
      now,
      personId: widget.personId,
      references: records,
    );
    final hero = snapshot.forYou.isEmpty ? null : snapshot.forYou.first;
    final linkedPeople = snapshot.people
        .where((facet) => facet.id != widget.personId)
        .take(8)
        .toList(growable: false);
    final linkedPlaces = snapshot.places.take(8).toList(growable: false);
    final shownIds = <String>{
      if (hero != null) hero.block.id,
    };
    final onThisDay = snapshot.onThisDay
        .where((entry) => shownIds.add(entry.block.id))
        .take(3)
        .toList(growable: false);
    final sameMonth = snapshot.sameMonthPastYears
        .where((entry) => shownIds.add(entry.block.id))
        .take(3)
        .toList(growable: false);
    final yearHighlights = snapshot.yearHighlights
        .where((entry) => shownIds.add(entry.block.id))
        .take(5)
        .toList(growable: false);
    final monthName = _cap(
      DateFormat('MMMM', AnnaStrings.intlLocale(context)).format(now),
    );

    return Semantics(
      identifier: 'memories-for-you-surface',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AnnaDesignTokens.spaceMd,
          AnnaDesignTokens.spaceXs,
          AnnaDesignTokens.spaceMd,
          AnnaDesignTokens.spaceXl,
        ),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AnnaDesignTokens.readingContentWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    strings.d3('memoriesForYou'),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: AnnaDesignTokens.space2xs),
                  Text(
                    strings.d3('memoriesForYouIntro'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AnnaDesignTokens.spaceMd),
                  Card(
                    child: Column(
                      children: [
                        Semantics(
                          identifier: 'memories-memory-map-entry',
                          button: true,
                          child: ListTile(
                            leading: const Icon(Icons.public_outlined),
                            title: Text(
                              strings.d3('memoryMapTitle'),
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            subtitle: Text(strings.d3('memoryMapIntro')),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: _showMemoryMap,
                          ),
                        ),
                        const Divider(height: 1),
                        Semantics(
                          identifier: 'memories-then-now-entry',
                          button: true,
                          child: ListTile(
                            leading: const Icon(Icons.compare_arrows_outlined),
                            title: Text(
                              strings.d3('thenNowTitle'),
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            subtitle: Text(strings.d3('thenNowIntro')),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: _showThenNow,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hero != null) _forYouHero(context, hero),
                  if (snapshot.isEmpty) ...[
                    const SizedBox(height: AnnaDesignTokens.spaceLg),
                    SimpleCard(
                      child: Text(strings.v100RediscoverEmpty),
                    ),
                  ],
                  if (onThisDay.isNotEmpty) ...[
                    _recallSectionHeader(
                      context,
                      title: strings.v100OnThisDayPast,
                      subtitle: strings.v100SameDatePast(
                        snapshot.onThisDay.length,
                      ),
                      icon: Icons.history_toggle_off,
                    ),
                    ...onThisDay.map(
                      (record) => _recallMemoryRow(context, record),
                    ),
                  ],
                  if (sameMonth.isNotEmpty) ...[
                    _recallSectionHeader(
                      context,
                      title: strings.v100MonthAcrossYears(monthName),
                      subtitle: strings.v100OtherSameMonth,
                      icon: Icons.calendar_month_outlined,
                    ),
                    ...sameMonth.map(
                      (record) => _recallMemoryRow(context, record),
                    ),
                  ],
                  if (yearHighlights.isNotEmpty) ...[
                    _recallSectionHeader(
                      context,
                      title: strings.v100JumpAcrossYears,
                      subtitle: strings.v100RepresentativeMoment,
                      icon: Icons.auto_awesome_outlined,
                    ),
                    ...yearHighlights.map(
                      (record) => _recallMemoryRow(context, record),
                    ),
                  ],
                  if (widget.personId == null)
                    _recallFacetSection(
                      context,
                      title: strings.v100RecurringPeople,
                      icon: Icons.people_outline,
                      facets: linkedPeople,
                    ),
                  _recallFacetSection(
                    context,
                    title: widget.personId == null
                        ? strings.v100RecurringPlaces
                        : strings.v100PlacesTogether,
                    icon: Icons.place_outlined,
                    facets: linkedPlaces,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timelineMemoryCard(
    BuildContext context,
    DiaryBlockReference record,
  ) {
    final strings = AnnaStrings.of(context);
    final block = record.block;
    final title = widget.store.diaryBlockDisplayTitle(
      block,
      strings: strings,
    );
    final date = DateFormat(
      'EEEE d MMMM yyyy',
      AnnaStrings.intlLocale(context),
    ).format(record.date);
    final visual = block.type == DiaryBlockType.photo ||
        block.type == DiaryBlockType.sketch;

    return Card(
      margin: const EdgeInsets.only(bottom: AnnaDesignTokens.spaceSm),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => block.type == DiaryBlockType.photo
            ? _openPhoto(record)
            : _openRecord(record),
        child: visual
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 190,
                    width: double.infinity,
                    child: _coverPreview(context, record),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AnnaDesignTokens.spaceMd),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: AnnaDesignTokens.spaceXs),
                        Text(
                          _cap(date),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Padding(
                padding: const EdgeInsets.all(AnnaDesignTokens.spaceMd),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: context.annaDomainSurface(
                        AnnaVisualDomain.memories,
                      ),
                      foregroundColor: context.annaDomainAccent(
                        AnnaVisualDomain.memories,
                      ),
                      child: Icon(
                        block.type == DiaryBlockType.voice
                            ? Icons.mic_none_outlined
                            : Icons.sticky_note_2_outlined,
                      ),
                    ),
                    const SizedBox(width: AnnaDesignTokens.spaceSm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: AnnaDesignTokens.spaceXs),
                          Text(
                            _cap(date),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _timelineView(
    BuildContext context,
    List<DiaryBlockReference> records,
  ) {
    if (records.isEmpty) return _emptyState();
    final strings = AnnaStrings.of(context);

    return Semantics(
      identifier: 'memories-timeline-list',
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          AnnaDesignTokens.spaceMd,
          AnnaDesignTokens.spaceXs,
          AnnaDesignTokens.spaceMd,
          AnnaDesignTokens.spaceXl,
        ),
        itemCount: records.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AnnaDesignTokens.readingContentWidth,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(
                    bottom: AnnaDesignTokens.spaceMd,
                  ),
                  child: Text(
                    strings.d3('memoriesTimelineIntro'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            );
          }

          final record = records[index - 1];
          final previous = index > 1 ? records[index - 2] : null;
          final startsMonth = previous == null ||
              previous.date.year != record.date.year ||
              previous.date.month != record.date.month;
          final monthLabel = _cap(
            DateFormat(
              'MMMM yyyy',
              AnnaStrings.intlLocale(context),
            ).format(record.date),
          );

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AnnaDesignTokens.readingContentWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (startsMonth)
                    Padding(
                      padding: const EdgeInsets.only(
                        top: AnnaDesignTokens.spaceSm,
                        bottom: AnnaDesignTokens.spaceXs,
                      ),
                      child: Text(
                        monthLabel,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  _timelineMemoryCard(context, record),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showBrowseSheet() async {
    final strings = AnnaStrings.of(context);
    final selected = await showModalBottomSheet<_DiaryMemoriesView>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: AnnaDesignTokens.spaceSm),
          children: [
            ListTile(
              title: Text(
                strings.d3('memoriesBrowseBy'),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.today_outlined),
              title: Text(strings.v100Days),
              onTap: () => Navigator.pop(
                sheetContext,
                _DiaryMemoriesView.days,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month_outlined),
              title: Text(strings.v100Months),
              onTap: () => Navigator.pop(
                sheetContext,
                _DiaryMemoriesView.months,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.insights_outlined),
              title: Text(strings.v100Years),
              onTap: () => Navigator.pop(
                sheetContext,
                _DiaryMemoriesView.years,
              ),
            ),
          ],
        ),
      ),
    );
    if (!mounted || selected == null) return;
    unawaited(AnnaFeedback.selection());
    setState(() => view = selected);
  }

  Future<void> _showFilterSheet() async {
    final strings = AnnaStrings.of(context);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: AnnaDesignTokens.spaceSm),
          children: [
            ListTile(
              title: Text(
                strings.d3('memoriesFilters'),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.layers_outlined),
              title: Text(strings.all),
              selected: filter == null,
              onTap: () {
                setState(() {
                  filter = null;
                  view = _DiaryMemoriesView.timeline;
                });
                Navigator.pop(sheetContext);
              },
            ),
            ...DiaryBlockType.values.map(
              (type) => ListTile(
                leading: Icon(
                  switch (type) {
                    DiaryBlockType.note => Icons.sticky_note_2_outlined,
                    DiaryBlockType.sketch => Icons.draw_outlined,
                    DiaryBlockType.photo => Icons.photo_outlined,
                    DiaryBlockType.voice => Icons.mic_none_outlined,
                  },
                ),
                title: Text(
                  switch (type) {
                    DiaryBlockType.note => strings.v100MemoryNotesFilter,
                    DiaryBlockType.sketch => strings.v100Sketch,
                    DiaryBlockType.photo => strings.v100Photo,
                    DiaryBlockType.voice => strings.v100MemoryVoiceFilter,
                  },
                ),
                selected: filter == type,
                onTap: () {
                  setState(() {
                    filter = type;
                    view = _DiaryMemoriesView.timeline;
                  });
                  Navigator.pop(sheetContext);
                },
              ),
            ),
          ],
        ),
      ),
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
    final strings = AnnaStrings.of(context);
    final secondaryView = switch (view) {
      _DiaryMemoriesView.days => strings.v100Days,
      _DiaryMemoriesView.months => strings.v100Months,
      _DiaryMemoriesView.years => strings.v100Years,
      _ => strings.d3('memoriesBrowse'),
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.personName == null
              ? strings.v100MyMemories
              : strings.v100MemoriesWithPerson(widget.personName!),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: strings.d3('memoriesSearchAction'),
            onPressed: () {
              unawaited(AnnaFeedback.selection());
              setState(() {
                if (searchExpanded) {
                  searchController.clear();
                  searchExpanded = false;
                } else {
                  searchExpanded = true;
                  view = _DiaryMemoriesView.timeline;
                }
              });
            },
            icon: Icon(searchExpanded ? Icons.search_off : Icons.search),
          ),
          IconButton(
            tooltip: strings.d3('memoriesFilters'),
            onPressed: _showFilterSheet,
            icon: Badge(
              isLabelVisible: filter != null,
              child: const Icon(Icons.tune_outlined),
            ),
          ),
        ],
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
              if (searchExpanded)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AnnaDesignTokens.spaceMd,
                    AnnaDesignTokens.space2xs,
                    AnnaDesignTokens.spaceMd,
                    AnnaDesignTokens.spaceXs,
                  ),
                  child: SearchBar(
                    controller: searchController,
                    hintText: strings.v100MemorySearchHint,
                    leading: const Icon(Icons.search),
                    trailing: searchController.text.isEmpty
                        ? null
                        : [
                            IconButton(
                              tooltip: strings.v100ClearSearch,
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
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AnnaDesignTokens.spaceMd,
                  AnnaDesignTokens.spaceXs,
                  AnnaDesignTokens.spaceMd,
                  AnnaDesignTokens.spaceXs,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        identifier: 'memories-for-you',
                        button: true,
                        selected: view == _DiaryMemoriesView.forYou,
                        child: ChoiceChip(
                          showCheckmark: false,
                          selected: view == _DiaryMemoriesView.forYou,
                          avatar: const Icon(Icons.auto_awesome_outlined),
                          label: Text(strings.d3('memoriesForYou')),
                          onSelected: (_) {
                            unawaited(AnnaFeedback.selection());
                            setState(
                              () => view = _DiaryMemoriesView.forYou,
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: AnnaDesignTokens.spaceXs),
                    Expanded(
                      child: Semantics(
                        identifier: 'memories-timeline',
                        button: true,
                        selected: view == _DiaryMemoriesView.timeline,
                        child: ChoiceChip(
                          showCheckmark: false,
                          selected: view == _DiaryMemoriesView.timeline,
                          avatar: const Icon(Icons.view_stream_outlined),
                          label: Text(strings.d3('memoriesTimeline')),
                          onSelected: (_) {
                            unawaited(AnnaFeedback.selection());
                            setState(
                              () => view = _DiaryMemoriesView.timeline,
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: AnnaDesignTokens.spaceXs),
                    Semantics(
                      identifier: 'memories-browse',
                      button: true,
                      child: OutlinedButton.icon(
                        onPressed: _showBrowseSheet,
                        icon: const Icon(Icons.grid_view_outlined, size: 18),
                        label: Text(secondaryView),
                      ),
                    ),
                  ],
                ),
              ),
              if (filter != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AnnaDesignTokens.spaceMd,
                    0,
                    AnnaDesignTokens.spaceMd,
                    AnnaDesignTokens.spaceXs,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.filter_alt_outlined,
                        size: 18,
                        color: context.annaDomainAccent(
                          AnnaVisualDomain.memories,
                        ),
                      ),
                      const SizedBox(width: AnnaDesignTokens.spaceXs),
                      Expanded(
                        child: Text(
                          strings.v100MemorySummary(
                            current.length,
                            _distinctDays(current),
                          ),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(() => filter = null),
                        child: Text(strings.d3('memoriesClearFilters')),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: switch (view) {
                  _DiaryMemoriesView.forYou =>
                    _forYouView(context, current),
                  _DiaryMemoriesView.timeline => Semantics(
                      identifier: 'memories-timeline-surface',
                      child: current.isEmpty
                          ? _emptyState()
                          : _timelineView(context, current),
                    ),
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

class _MemoryMapGridPainter extends CustomPainter {
  final Color lineColor;

  const _MemoryMapGridPainter({
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;

    for (var i = 1; i < 6; i++) {
      final x = size.width * i / 6;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final outline = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.08,
        size.height * 0.18,
        size.width * 0.34,
        size.height * 0.42,
      ),
      outline,
    );
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.47,
        size.height * 0.13,
        size.width * 0.43,
        size.height * 0.50,
      ),
      outline,
    );
  }

  @override
  bool shouldRepaint(covariant _MemoryMapGridPainter oldDelegate) =>
      oldDelegate.lineColor != lineColor;
}
