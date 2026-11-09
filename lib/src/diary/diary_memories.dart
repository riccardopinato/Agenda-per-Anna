part of '../../main.dart';

/// CAP-0145: private count of user-created memory blocks. No mood, health,
/// Vault, shared inference, tracking or background collection. Missing dates
/// mean 'not recorded', never 'no life activity'.
Map<String, int> annaRecordedMemoriesByDay(
  Iterable<DiaryBlockReference> authorizedMemories, {
  required DateTime endingMonth,
}) {
  final from = DateTime(endingMonth.year, endingMonth.month - 11, 1);
  final until = DateTime(endingMonth.year, endingMonth.month + 1, 1);
  final counts = <String, int>{};
  final seen = <String>{};
  for (final ref in authorizedMemories) {
    final block = ref.block;
    final day = DateTime(ref.date.year, ref.date.month, ref.date.day);
    if (block.archived || day.isBefore(from) || !day.isBefore(until) ||
        block.id.trim().isEmpty || !seen.add(block.id)) {
      continue;
    }
    final key = AgendaStore.dateKey(day);
    counts[key] = (counts[key] ?? 0) + 1;
  }
  return Map.unmodifiable(counts);
}

String _annaMemoryFrequencyCopy(String code, String key) {
  const copies = <String, Map<String, String>>{
    'title': {
      'it': 'Ricordi registrati', 'en': 'Recorded memories',
      'es': 'Recuerdos registrados', 'fr': 'Souvenirs enregistrés',
      'pt': 'Memórias registadas',
    },
    'empty': {
      'it': 'Nessun ricordo registrato', 'en': 'No memory recorded',
      'es': 'No se registraron recuerdos', 'fr': 'Aucun souvenir enregistré',
      'pt': 'Nenhuma memória registada',
    },
    'count': {
      'it': 'ricordi', 'en': 'memories', 'es': 'recuerdos',
      'fr': 'souvenirs', 'pt': 'memórias',
    },
    'private': {
      'it': 'Solo ricordi privati già salvati',
      'en': 'Only already saved private memories',
      'es': 'Solo recuerdos privados ya guardados',
      'fr': 'Uniquement les souvenirs privés enregistrés',
      'pt': 'Apenas memórias privadas já guardadas',
    },
    'hidden': {
      'it': 'Dettagli nascosti per privacy', 'en': 'Details hidden for privacy',
      'es': 'Detalles ocultos por privacidad',
      'fr': 'Détails masqués pour la confidentialité',
      'pt': 'Detalhes ocultos por privacidade',
    },
  };
  return copies[key]?[code] ?? copies[key]?['en'] ?? key;
}

Future<void> showAnnaMemoryFrequency(
  BuildContext context,
  AgendaStore store, {
  String? personId,
}) async {
  final accountAtOpen = store.activeAccountId;
  final now = DateTime.now();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final strings = AnnaStrings.of(context);
        final code = strings.languageCode;
        final blocked = store.activeAccountId != accountAtOpen ||
            store.preferences.hideHomeDetails;
        final counts = blocked
            ? const <String, int>{}
            : annaRecordedMemoriesByDay(
                store.memoryReferences(
                  includeArchived: false, personId: personId),
                endingMonth: now);
        return SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_annaMemoryFrequencyCopy(code, 'title'),
                      style: Theme.of(context).textTheme.titleLarge),
                    Text(blocked ? _annaMemoryFrequencyCopy(code, 'hidden') : 
                        _annaMemoryFrequencyCopy(code, 'private'),
                      style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Expanded(
                child: blocked
                    ? const SizedBox.shrink()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: 12,
                        itemBuilder: (context, index) {
                          final month = DateTime(now.year, now.month - index, 1);
                          final days = DateTime(month.year, month.month + 1, 0).day;
                          final locale = AnnaStrings.intlLocale(context);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 18),
                            child: AnnaJournalCard(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(DateFormat('MMMM yyyy', locale).format(month),
                                  style: Theme.of(context).textTheme.titleMedium),
                                const SizedBox(height: 10),
                                GridView.count(
                                  crossAxisCount: 7,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  mainAxisSpacing: 4,
                                  crossAxisSpacing: 4,
                                  children: [
                                    for (var day = 1; day <= days; day++)
                                      Builder(builder: (context) {
                                        final date = DateTime(
                                            month.year, month.month, day);
                                        final count = counts[
                                            AgendaStore.dateKey(date)] ?? 0;
                                        final info = count == 0
                                            ? _annaMemoryFrequencyCopy(code, 'empty')
                                            : '$count ${_annaMemoryFrequencyCopy(code, 'count')}';
                                        final label = '${DateFormat('d MMMM', locale).format(date)} · $info';
                                        return Semantics(
                                          label: label,
                                          child: Tooltip(
                                            message: label,
                                            child: DecoratedBox(
                                              decoration: BoxDecoration(
                                                color: count == 0
                                                    ? Theme.of(context)
                                                        .colorScheme.surfaceContainerHigh
                                                    : Theme.of(context).colorScheme.primary
                                                        .withValues(alpha:
                                                          count >= 4 ? 0.9 :
                                                          count >= 2 ? 0.65 : 0.35),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Center(child: Text('$day',
                                                style: Theme.of(context)
                                                    .textTheme.labelSmall)),
                                            ),
                                          ),
                                        );
                                      }),
                                  ],
                                ),
                              ],
                            )),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

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

  // DF-25–28: accordion state is in memory only for this live screen session.
  final Map<String, bool> _expandedTimelineMonths = <String, bool>{};
  final Map<int, GlobalKey> _timelineYearKeys = <int, GlobalKey>{};
  int? _selectedTimelineYear;
  String? _highlightTimelineMonth;
  String? _yearJumpTarget;
  bool _timelineInitialized = false;
  bool _suggestionsExpanded = false;
  int _anniversaryIndex = 0;
  final PageController _anniversaryPager = PageController();

  @override
  void dispose() {
    searchController.dispose();
    _anniversaryPager.dispose();
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
        return Semantics(
          image: true,
          label: widget.store.preferences.hideHomeDetails
              ? AnnaStrings.of(context).v100Photo
              : (block.altText.isEmpty
                  ? (block.text.isEmpty
                      ? AnnaStrings.of(context).v100Photo : block.text)
                  : block.altText),
          child: DiaryMediaImage(
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
    if (AnnaEditorialTodayMode.enabled.value) {
      return _editorialFeaturedMemory(context, record);
    }
    final strings = AnnaStrings.of(context);
    final title = widget.store.diaryBlockDisplayTitle(
      record.block,
      strings: strings,
    );
    final date = DateFormat(
      'd MMMM yyyy',
      AnnaStrings.intlLocale(context),
    ).format(record.date);

    // Text and voice memories use an editorial hero, never an empty
    // photographic placeholder or a dark photo overlay.
    final visual = record.block.type == DiaryBlockType.photo ||
        record.block.type == DiaryBlockType.sketch;
    if (!visual) {
      return Semantics(
        identifier: 'memories-for-you-hero',
        button: true,
        label: '$title · $date',
        child: Padding(
          padding: const EdgeInsets.only(top: AnnaDesignTokens.spaceSm),
          child: AnnaJournalCard(
            domain: AnnaVisualDomain.memories,
            hero: true,
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                key: const ValueKey<String>('memories-editorial-hero'),
                onTap: () => _openRecord(record),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    record.block.type == DiaryBlockType.voice
                        ? Icons.mic_none_outlined
                        : Icons.auto_stories_outlined,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: AnnaDesignTokens.spaceSm),
                  Text(
                    title,
                    style: AnnaJournalTypography.editorial(
                      context,
                      size: 25,
                    ),
                  ),
                  const SizedBox(height: AnnaDesignTokens.spaceXs),
                  Text(
                    date,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Semantics(
      identifier: 'memories-for-you-hero',
      button: true,
      label: '$title · $date',
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.only(top: AnnaDesignTokens.spaceMd),
        child: InkWell(
          onTap: () => record.block.type == DiaryBlockType.photo
              ? _openPhoto(record)
              : _openRecord(record),
          child: SizedBox(
            height: 286,
            child: Stack(
              fit: StackFit.expand,
              children: [
                record.block.type == DiaryBlockType.photo &&
                        record.block.hasPhotoMedia
                    ? Hero(
                        tag: 'v108-photo-${record.block.id}',
                        child: _coverPreview(context, record),
                      )
                    : _coverPreview(context, record),
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
                  child: AnnaMotionStagger(
                    order: 2,
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
                        style: AnnaJournalTypography.editorial(
                          context,
                          size: 25,
                        ).copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
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
                  AnnaMotionMapEntry(
                    child: LayoutBuilder(
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
                                      child: AnnaMotionMapPin(
  count: place.count,
  order: located.indexOf(place),
  onPressed: () {
    final memory = place.latestMemory;
    unawaited(showModalBottomSheet<void>(
      context: sheetContext,
      showDragHandle: true,
      builder: (previewContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AnnaDesignTokens.spaceMd),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: SizedBox(
                  width: 48, height: 48,
                  child: _coverPreview(previewContext, memory),
                ),
                title: Text(widget.store.diaryBlockDisplayTitle(
                  memory.block, strings: strings)),
                subtitle: Text('${place.label} · ${place.count}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(previewContext);
                  Navigator.pop(sheetContext);
                  if (memory.block.type == DiaryBlockType.photo) {
                    unawaited(_openPhoto(memory));
                  } else {
                    unawaited(_openRecord(memory));
                  }
                },
              ),
              TextButton.icon(
                icon: const Icon(Icons.place_outlined),
                label: Text(strings.d3('memoryMapSelectablePlaces')),
                onPressed: () {
                  Navigator.pop(previewContext);
                  Navigator.pop(sheetContext);
                  searchController.text = place.label;
                  setState(() {
                    filter = null;
                    searchExpanded = true;
                    view = _DiaryMemoriesView.timeline;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    ));
  },
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
                  ),
                if (located.isNotEmpty) ...[
                  const SizedBox(height: AnnaDesignTokens.spaceMd),
                  Text(
                    strings.d3('memoryMapSelectablePlaces'),
                    style: Theme.of(sheetContext)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: AnnaDesignTokens.spaceXs),
                  Semantics(
                    identifier: 'memory-map-located-list',
                    container: true,
                    child: Wrap(
                      spacing: AnnaDesignTokens.spaceXs,
                      runSpacing: AnnaDesignTokens.spaceXs,
                      children: located
                          .map(
                            (place) => ActionChip(
                              avatar:
                                  const Icon(Icons.place_outlined, size: 18),
                              label: Text('${place.label} · ${place.count}'),
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
                  ),
                ],
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
                                if (pair.thenMemory.block.type == DiaryBlockType.photo &&
                                    pair.nowMemory.block.type == DiaryBlockType.photo &&
                                    pair.thenMemory.block.hasPhotoMedia &&
                                    pair.nowMemory.block.hasPhotoMedia) ...[
                                  AnnaThenNowWipe(
                                    before: pair.thenMemory.block,
                                    after: pair.nowMemory.block,
                                    beforeLabel: strings.d3('thenNowThen'),
                                    afterLabel: strings.d3('thenNowNow'),
                                  ),
                                  const SizedBox(height: AnnaDesignTokens.spaceSm),
                                ],
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
    final editorial = AnnaEditorialTodayMode.enabled.value;
    final now = DateTime.now();
    final snapshot = widget.store.memoryRecallSnapshot(
      now,
      personId: widget.personId,
      references: records,
    );
    // All individual exact-date matches remain swipeable. Only when there
    // are NONE do we show clearly labeled same-month historical fallback.
    final exact = [...snapshot.onThisDay]..sort((a, b) {
      final c = b.date.compareTo(a.date);
      return c != 0 ? c : b.block.createdAt.compareTo(a.block.createdAt);
    });
    final fallback = [...snapshot.sameMonthPastYears]..sort((a, b) {
      final c = b.date.compareTo(a.date);
      return c != 0 ? c : b.block.createdAt.compareTo(a.block.createdAt);
    });
    final anniversary = exact.isNotEmpty ? exact : fallback;
    if (_anniversaryIndex >= anniversary.length) {
      _anniversaryIndex = anniversary.isEmpty ? 0 : anniversary.length - 1;
      final targetPage = _anniversaryIndex;
      if (anniversary.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _anniversaryPager.hasClients) {
            _anniversaryPager.jumpToPage(targetPage);
          }
        });
      }
    }
    final anniversaryIds = anniversary.map((e) => e.block.id).toSet();
    final suggestions = <DiaryBlockReference>[];
    final shownIds = <String>{...anniversaryIds};
    for (final record in <DiaryBlockReference>[
      ...snapshot.forYou,
      ...snapshot.yearHighlights,
      ...snapshot.sameMonthPastYears,
    ]) {
      if (shownIds.add(record.block.id)) suggestions.add(record);
    }
    final linkedPeople = snapshot.people
        .where((facet) => facet.id != widget.personId)
        .take(8)
        .toList(growable: false);
    final linkedPlaces = snapshot.places.take(8).toList(growable: false);
    final monthName = _cap(DateFormat(
      'MMMM', AnnaStrings.intlLocale(context)).format(now));
    final activeRecord = anniversary.isEmpty ? null : anniversary[_anniversaryIndex];
    final activeYear = activeRecord?.date.year;
    final years = anniversary.map((entry) => entry.date.year).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    final yearIndex = activeYear == null ? 0 :
        anniversary.take(_anniversaryIndex + 1).where(
          (entry) => entry.date.year == activeYear).length;
    final yearTotal = activeYear == null ? 0 : anniversary.where(
      (entry) => entry.date.year == activeYear).length;

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
                  if (editorial)
                    AnnaEditorialHeader(
                      title: strings.d3('memoriesForYou'),
                      subtitle: strings.d3('memoriesForYouIntro'),
                    )
                  else
                    AnnaJournalPageHeader(
                      title: strings.d3('memoriesForYou'),
                      subtitle: strings.d3('memoriesForYouIntro'),
                      editorial: true,
                    ),
                  const SizedBox(height: AnnaDesignTokens.spaceMd),
                  if (!editorial) ...[
                    ContextualMemoryPanel(
                      store: widget.store,
                      authorizedPrivateMemories: records,
                      onOpen: (record) => unawaited(_openRecord(record)),
                    ),
                    const SizedBox(height: AnnaDesignTokens.spaceSm),
                  ],
                  if (anniversary.isNotEmpty) ...[
                    if (editorial)
                      AnnaEditorialSectionHeading(
                        title: exact.isNotEmpty
                            ? strings.d3('ui5OnThisDay')
                            : strings.v100MonthAcrossYears(monthName),
                      )
                    else
                      AnnaJournalSectionHeading(
                        title: exact.isNotEmpty
                            ? strings.d3('ui5OnThisDay')
                            : strings.v100MonthAcrossYears(monthName),
                      ),
                    if (exact.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(strings.v100OtherSameMonth),
                      ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 44,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: years.map((year) => Padding(
                          padding: const EdgeInsets.only(right: 7),
                          child: ChoiceChip(
                            key: ValueKey<String>('ui5-anniversary-year-$year'),
                            label: Text('$year'),
                            selected: activeYear == year,
                            onSelected: (_) {
                              final position = anniversary.indexWhere(
                                (record) => record.date.year == year);
                              if (position < 0) return;
                              _anniversaryPager.jumpToPage(position);
                              setState(() => _anniversaryIndex = position);
                            },
                          ),
                        )).toList(),
                      ),
                    ),
                    SizedBox(
                      height: 328,
                      child: PageView.builder(
                        key: const ValueKey<String>('ui5-anniversary-carousel'),
                        controller: _anniversaryPager,
                        itemCount: anniversary.length,
                        onPageChanged: (position) =>
                            setState(() => _anniversaryIndex = position),
                        itemBuilder: (context, position) =>
                            AnnaMotionStagger(
                              key: ValueKey<String>(
                                'v108-featured-${anniversary[position].block.id}'),
                              order: 0,
                              child: _forYouHero(context, anniversary[position]),
                            ),
                      ),
                    ),
                    if (activeRecord != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          exact.isEmpty
                              ? DateFormat('d MMMM yyyy',
                                  AnnaStrings.intlLocale(context)).format(activeRecord.date)
                              : '${now.year - activeRecord.date.year == 1 ? strings.d3('ui5OneYearAgo') : strings.d3Format('ui5YearsAgo', {'years': now.year - activeRecord.date.year})} · ${strings.d3Format('ui5MemoryYearCount', {'index': yearIndex, 'total': yearTotal})}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                  ],
                  if (editorial) ...[
                    const SizedBox(height: AnnaDesignTokens.spaceMd),
                    ContextualMemoryPanel(
                      store: widget.store,
                      authorizedPrivateMemories: records,
                      onOpen: (record) => unawaited(_openRecord(record)),
                    ),
                    const SizedBox(height: AnnaDesignTokens.spaceMd),
                  ],
                  if (suggestions.isNotEmpty) ...[
                    if (editorial)
                      AnnaEditorialSectionHeading(
                        title: strings.d3('ui5ForYou'),
                      )
                    else
                      AnnaJournalSectionHeading(
                        title: strings.d3('ui5ForYou'),
                      ),
                    const SizedBox(height: 8),
                    ...suggestions.take(3)
                        .map((record) => _recallMemoryRow(context, record)),
                    AnimatedSize(
                      duration: AnnaMotionV108.duration(context, 330),
                      alignment: Alignment.topCenter,
                      child: Column(
                        children: _suggestionsExpanded
                            ? <Widget>[
                                for (var i = 3; i < suggestions.length; i++)
                                  if (i < 7)
                                    AnnaMotionStagger(
                                      key: ValueKey<String>(
                                        'v108-suggestion-${suggestions[i].block.id}'),
                                      order: i - 3,
                                      child: _recallMemoryRow(context, suggestions[i]),
                                    )
                                  else
                                    _recallMemoryRow(context, suggestions[i]),
                              ]
                            : const <Widget>[],
                      ),
                    ),
                    if (suggestions.length > 3)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => setState(
                            () => _suggestionsExpanded = !_suggestionsExpanded),
                          icon: Icon(_suggestionsExpanded
                              ? Icons.expand_less : Icons.expand_more),
                          label: Text(strings.d3(_suggestionsExpanded
                              ? 'ui5ShowLess' : 'ui5ShowAll')),
                        ),
                      ),
                    const SizedBox(height: 10),
                  ],
                  _memoryExploreSurface(
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
                        const Divider(height: 1),
                        Semantics(
                          identifier: 'memories-collections-entry',
                          button: true,
                          child: ListTile(
                            leading:
                                const Icon(Icons.collections_bookmark_outlined),
                            title: Text(
                              '${strings.v105Collections} · ${strings.v105LifeThreads}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            subtitle: Text(strings.v105CollectionsIntro),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => MemoryCollectionsScreen(
                                  store: widget.store,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (snapshot.isEmpty) ...[
                    const SizedBox(height: AnnaDesignTokens.spaceLg),
                    SimpleCard(
                      child: Text(strings.v100RediscoverEmpty),
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
    if (AnnaEditorialTodayMode.enabled.value) {
      return _editorialTimelineMemoryCard(context, record);
    }
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
                    child: block.type == DiaryBlockType.photo &&
                            block.hasPhotoMedia
                        ? Hero(
                            tag: 'v108-photo-${block.id}',
                            child: _coverPreview(context, record),
                          )
                        : _coverPreview(context, record),
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
    final sorted = [...records]..sort((a, b) {
      final byDate = b.date.compareTo(a.date);
      if (byDate != 0) return byDate;
      return b.block.createdAt.compareTo(a.block.createdAt);
    });
    final groups = _groupByMonth(sorted);
    final months = groups.entries.toList(growable: false);
    final available = months.map((entry) => entry.key).toSet();
    _expandedTimelineMonths.removeWhere((key, _) => !available.contains(key));
    final years = months.map((entry) => entry.value.first.date.year).toSet()
        .toList()..sort((a, b) => b.compareTo(a));
    if (!_timelineInitialized) {
      _timelineInitialized = true;
      _selectedTimelineYear = years.first;
      _expandedTimelineMonths[months.first.key] = true;
    }
    if (!years.contains(_selectedTimelineYear)) {
      _selectedTimelineYear = years.first;
      _expandedTimelineMonths[months.first.key] = true;
    }

    void jumpToYear(int selected) {
      final target = months.firstWhere(
        (group) => group.value.first.date.year == selected);
      setState(() {
        _selectedTimelineYear = selected;
        _expandedTimelineMonths[target.key] = true;
        _highlightTimelineMonth = target.key;
        _yearJumpTarget = target.key;
      });
      Future<void>.delayed(const Duration(milliseconds: 670), () {
        if (mounted && _highlightTimelineMonth == target.key) {
          setState(() => _highlightTimelineMonth = null);
        }
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final targetContext = _timelineYearKeys[selected]?.currentContext;
        if (targetContext != null) {
          Scrollable.ensureVisible(targetContext,
            duration: AnnaDesignTokens.animationsEnabled(context)
                ? const Duration(milliseconds: 240) : Duration.zero,
            alignment: 0.05,
          );
        }
      });
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AnnaDesignTokens.spaceMd, 4, AnnaDesignTokens.spaceMd, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Icon(Icons.calendar_month_outlined, size: 19),
              const SizedBox(width: 8),
              DropdownButton<int>(
                key: const ValueKey<String>('ui5-timeline-year-jump'),
                value: _selectedTimelineYear,
                underline: const SizedBox.shrink(),
                items: years.map((year) => DropdownMenuItem<int>(
                  value: year,
                  child: Text('$year'),
                )).toList(),
                onChanged: (value) {
                  if (value != null) jumpToYear(value);
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: Semantics(
            identifier: 'memories-timeline-list',
            child: SingleChildScrollView(
              key: const PageStorageKey<String>('ui5-timeline-scroll'),
              padding: const EdgeInsets.fromLTRB(
                AnnaDesignTokens.spaceMd,
                AnnaDesignTokens.spaceXs,
                AnnaDesignTokens.spaceMd,
                AnnaDesignTokens.spaceXl,
              ),
              // Eager layout mounts the first-month key of every year.
              child: Column(children: months.map((entry) {
                final bucket = entry.value;
                final date = bucket.first.date;
                final isExpanded = _expandedTimelineMonths[entry.key] ?? false;
                final firstInYear = months.indexOf(entry) == 0 ||
                    months[months.indexOf(entry) - 1].value.first.date.year != date.year;
                final title = _cap(DateFormat(
                  'MMMM yyyy',
                  AnnaStrings.intlLocale(context),
                ).format(date));
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AnnaDesignTokens.readingContentWidth),
                    child: Column(
                      key: firstInYear
                          ? _timelineYearKeys.putIfAbsent(date.year, () => GlobalKey())
                          : null,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _memoryMonthSurface(
                          child: Semantics(
                            button: true,
                            expanded: isExpanded,
                            label: '$title · ${strings.d3Format(bucket.length == 1 ? 'ui5MemoryCountOne' : 'ui5MemoryCount', {'count': bucket.length})}',
                            child: InkWell(
                              key: ValueKey<String>('ui5-timeline-month-${entry.key}'),
                              borderRadius: BorderRadius.circular(18),
                              onTap: () => setState(() {
                                _selectedTimelineYear = date.year;
                                _expandedTimelineMonths[entry.key] = !isExpanded;
                                _yearJumpTarget = null;
                              }),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: AnimatedDefaultTextStyle(
                                        duration: AnnaMotionV108.duration(context, 420),
                                        style: (AnnaEditorialTodayMode.enabled.value
                                            ? AnnaJournalTypography.editorial(
                                                context, size: 20)
                                            : (Theme.of(context).textTheme.titleMedium ??
                                                const TextStyle())).copyWith(
                                          color: _highlightTimelineMonth == entry.key
                                              ? Theme.of(context).colorScheme.primary
                                              : Theme.of(context).colorScheme.onSurface,
                                        ),
                                        child: Text(title),
                                      ),
                                    ),
                                    Text(strings.d3Format(
                                      bucket.length == 1 ? 'ui5MemoryCountOne' : 'ui5MemoryCount', {'count': bucket.length}),
                                      style: Theme.of(context).textTheme.bodySmall),
                                    const SizedBox(width: 8),
                                    Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        AnimatedSize(
                          duration: AnnaMotionV108.duration(context, 300),
                          alignment: Alignment.topCenter,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: isExpanded
                                ? <Widget>[
                                    for (var i = 0; i < bucket.length; i++)
                                      if (i < 4 && _yearJumpTarget != entry.key)
                                        AnnaMotionStagger(
                                          key: ValueKey<String>(
                                            'v108-timeline-${bucket[i].block.id}'),
                                          order: i,
                                          child: _timelineMemoryCard(context, bucket[i]),
                                        )
                                      else
                                        _timelineMemoryCard(context, bucket[i]),
                                  ]
                                : const <Widget>[],
                          ),
                        ),
                        const SizedBox(height: 5),
                      ],
                    ),
                  ),
                );
              }).toList()),
            ),
          ),
        ),
      ],
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

    return ValueListenableBuilder<bool>(
      valueListenable: AnnaEditorialTodayMode.enabled,
      builder: (context, editorial, _) => Scaffold(
      backgroundColor: editorial ? AnnaEditorialColors.of(context).canvas : null,
      appBar: AppBar(
        backgroundColor: editorial ? AnnaEditorialColors.of(context).canvas : null,
        surfaceTintColor: editorial ? Colors.transparent : null,
        toolbarHeight: 78,
        title: Text(
          widget.personName == null
              ? strings.v100MyMemories
              : strings.v100MemoriesWithPerson(widget.personName!),
          style: AnnaJournalTypography.editorial(context, size: 29),
        ),
        actions: [
          IconButton(
            key: const ValueKey('cap0151-memory-extractive-summary'),
            tooltip: memoryExtractiveCopy(strings.languageCode, 'title'),
            icon: const Icon(Icons.summarize_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => MemoryExtractiveSummaryScreen(
                  store: widget.store,
                  personId: widget.personId,
                ),
              ),
            ),
          ),
          IconButton(
            key: const ValueKey('cap0145-memory-frequency'),
            tooltip: _annaMemoryFrequencyCopy(
                strings.languageCode, 'title'),
            onPressed: widget.store.preferences.hideHomeDetails
                ? null
                : () => showAnnaMemoryFrequency(
                    context, widget.store, personId: widget.personId),
            icon: const Icon(Icons.calendar_view_month_outlined),
          ),
          IconButton(
            tooltip: strings.d3('memoriesSearchAction'),
            onPressed: () {
              unawaited(AnnaFeedback.selection());
              Navigator.of(context).push(
                PageRouteBuilder<void>(
                  transitionDuration: AnnaMotionV108.duration(context, 310),
                  reverseTransitionDuration: AnnaMotionV108.duration(context, 230),
                  pageBuilder: (_, animation, secondaryAnimation) =>
                      _DiaryGlobalSearchScreen(
                        store: widget.store,
                        personId: widget.personId,
                      ),
                  transitionsBuilder: (context, animation, secondary, child) =>
                      FadeTransition(
                        opacity: CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                        child: child,
                      ),
                ),
              );
            },
            icon: const Hero(
              tag: 'v108-search-lens',
              child: Icon(Icons.search),
            ),
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
                child: AnnaMotionReveal(
                  token: view.index,
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
              ),
            ],
          );
        },
      ),
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

const String futureLetterTag = 'future_letter_v1';

class FutureLetterRecord {
  final DateTime day;
  final DiaryBlock block;
  const FutureLetterRecord(this.day, this.block);

  /// An in-app date cue, never a cryptographic lock or a push reminder.
  bool isAvailableOn(DateTime now) =>
      !DateTime(day.year, day.month, day.day)
          .isAfter(DateTime(now.year, now.month, now.day));
}

List<FutureLetterRecord> personalFutureLetters(AgendaStore store) {
  if (!store.entryScopeReady ||
      store.agendaContentFilter == AgendaContentFilter.sharedOnly) {
    return const <FutureLetterRecord>[];
  }
  final result = <FutureLetterRecord>[];
  for (final entry in store.journals.entries) {
    final day = DateTime.tryParse(entry.key);
    if (day == null) continue;
    for (final block in entry.value.blocks) {
      if (!block.archived && block.type == DiaryBlockType.note &&
          block.tags.contains(futureLetterTag)) {
        result.add(FutureLetterRecord(day, block));
      }
    }
  }
  result.sort((a, b) => a.day.compareTo(b.day));
  return List<FutureLetterRecord>.unmodifiable(result);
}

/// Uses the same canonical diary writer, protected against A -> B -> A
/// account changes even if the dialogue remains open.
Future<bool> savePersonalFutureLetter(
  AgendaStore store, DateTime day, String text, {
  required String? accountAtOpen,
  Cap0160TagEditGuard? scopeGuard,
}) async {
  final guard = scopeGuard ?? Cap0160TagEditGuard(store);
  final body = text.trim();
  final now = DateTime.now();
  final target = DateTime(day.year, day.month, day.day);
  final today = DateTime(now.year, now.month, now.day);
  if (!guard.isCurrent || guard.accountId != accountAtOpen ||
      !target.isAfter(today) || body.isEmpty || body.length > 10000) {
    return false;
  }
  final journal = store.journal(target);
  final letter = DiaryBlock(
    id: 'future_letter_${const Uuid().v4()}',
    type: DiaryBlockType.note,
    createdAt: now,
    text: body,
    tags: const [futureLetterTag],
  );
  try {
    await store.saveJournal(
      target, journal.copyWith(blocks: [...journal.blocks, letter]),
      scopeGuard: guard,
    );
    return guard.isCurrent;
  } on Cap0160ScopeChanged {
    return false;
  }
}

/// Resolve the exact active canonical block again before reading it. A stale
/// tile/reference from a former account cannot reveal another profile's data.
FutureLetterRecord? currentPersonalFutureLetter(
    AgendaStore store, FutureLetterRecord record) {
  if (!store.entryScopeReady ||
      store.agendaContentFilter == AgendaContentFilter.sharedOnly) {
    return null;
  }
  for (final block in store.journal(record.day).blocks) {
    if (block.id == record.block.id && !block.archived &&
        block.type == DiaryBlockType.note &&
        block.tags.contains(futureLetterTag)) {
      return FutureLetterRecord(record.day, block);
    }
  }
  return null;
}

String futureLetterTitle(AnnaStrings s) => switch (s.languageCode) {
  'it' => 'Lettere al me futuro',
  'es' => 'Cartas a mi yo futuro',
  'fr' => 'Lettres à mon futur moi',
  'pt' => 'Cartas ao meu eu futuro',
  _ => 'Letters to future me',
};

String futureLetterLabel(AnnaStrings s, String key) {
  const labels = <String, List<String>>{
    'create': ['Write a letter', 'Scrivi una lettera', 'Escribe una carta', 'Écrire une lettre', 'Escrever uma carta'],
    'save': ['Save letter', 'Salva lettera', 'Guardar carta', 'Enregistrer', 'Guardar carta'],
    'date': ['Open on', 'Apri il', 'Abrir el', 'Ouvrir le', 'Abrir em'],
    'body': ['Write for your future self', 'Scrivi al te del futuro', 'Escribe a tu yo futuro', 'Écris à ton futur moi', 'Escreva para seu eu futuro'],
    'empty': ['No letters yet', 'Nessuna lettera', 'Sin cartas todavía', 'Aucune lettre', 'Ainda sem cartas'],
    'early': ['Open ahead of time?', 'Aprire in anticipo?', '¿Abrir antes de tiempo?', 'Ouvrir avant la date ?', 'Abrir antes da data?'],
    'read': ['Read letter', 'Leggi lettera', 'Leer carta', 'Lire la lettre', 'Ler carta'],
    'waiting': ['Waiting for its date', 'In attesa della data',
      'En espera de la fecha', 'En attente de la date',
      'À espera da data'],
    'ready': ['Ready to read', 'Pronta da leggere',
      'Lista para leer', 'Prête à lire',
      'Pronta para ler'],
    'unavailable': ['This letter is no longer available in this profile.',
      'Questa lettera non è più disponibile in questo profilo.',
      'Esta carta ya no está disponible en este perfil.',
      'Cette lettre n’est plus disponible dans ce profil.',
      'Esta carta já não está disponível neste perfil.'],
    'saveFailed': ['Could not save this letter. Check local storage and try again.',
      'Impossibile salvare la lettera. Controlla la memoria locale e riprova.',
      'No se pudo guardar la carta. Comprueba el almacenamiento local.',
      'Impossible d’enregistrer la lettre. Vérifiez le stockage local.',
      'Não foi possível guardar a carta. Verifica o armazenamento local.'],
    'trash': ['Move to Trash', 'Sposta nel Cestino', 'Mover a la papelera', 'Mettre à la corbeille', 'Mover para lixeira'],
    'notice': ['A reminder date, not a security lock: this note remains accessible from Diary.',
      'Una data da ricordare, non un blocco: la nota resta accessibile dal Diario.',
      'Una fecha, no un bloqueo: la nota sigue accesible en el Diario.',
      'Une date, pas un verrou: la note reste accessible dans le journal.',
      'Uma data, não um bloqueio: a nota continua acessível no Diário.'],
  };
  final i = switch (s.languageCode) {
    'it' => 1, 'es' => 2, 'fr' => 3, 'pt' => 4, _ => 0,
  };
  return labels[key]![i];
}

Future<void> composePersonalFutureLetter(
    BuildContext context, AgendaStore store) async {
  if (!store.entryScopeReady) return;
  final guard = Cap0160TagEditGuard(store);
  final account = store.activeAccountId;
  final controller = TextEditingController();
  var saving = false;
  final now = DateTime.now();
  var target = DateTime(now.year, now.month, now.day + 30);
  await showDialog<void>(
    context: context,
    builder: (dialog) => StatefulBuilder(builder: (dialog, refresh) {
      final text = AnnaStrings.of(dialog);
      return AlertDialog(
        title: Text(futureLetterTitle(text)),
        content: SingleChildScrollView(child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(futureLetterLabel(text, 'notice')),
            TextField(
              controller: controller, maxLines: 6, maxLength: 10000,
              onChanged: (_) => refresh(() {}),
              decoration: InputDecoration(
                labelText: futureLetterLabel(text, 'body')),
            ),
            TextButton.icon(
              icon: const Icon(Icons.event_outlined),
              label: Text('${futureLetterLabel(text, 'date')} ${DateFormat.yMMMd(AnnaStrings.intlLocale(dialog)).format(target)}'),
              onPressed: () async {
                final value = await showDatePicker(
                  context: dialog,
                  initialDate: target,
                  firstDate: DateTime(now.year, now.month, now.day + 1),
                  lastDate: DateTime(now.year + 10),
                );
                if (value != null) refresh(() => target = value);
              },
            ),
          ],
        )),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog),
            child: Text(quickWinText(text, 'undo'))),
          FilledButton(
            onPressed: saving || !guard.isCurrent ||
                    controller.text.trim().isEmpty
                ? null
                : () async {
                    refresh(() => saving = true);
                    try {
                      final saved = await savePersonalFutureLetter(
                        store, target, controller.text,
                        accountAtOpen: account, scopeGuard: guard,
                      );
                      if (saved && dialog.mounted) {
                        Navigator.pop(dialog);
                      } else if (dialog.mounted) {
                        ScaffoldMessenger.maybeOf(dialog)?.showSnackBar(
                          SnackBar(content: Text(
                            futureLetterLabel(text, 'unavailable'))),
                        );
                      }
                    } catch (_) {
                      if (dialog.mounted) {
                        ScaffoldMessenger.maybeOf(dialog)?.showSnackBar(
                          SnackBar(content: Text(
                            futureLetterLabel(text, 'saveFailed'))),
                        );
                      }
                    } finally {
                      if (dialog.mounted) refresh(() => saving = false);
                    }
                  },
            child: Text(futureLetterLabel(text, 'save')),
          ),
        ],
      );
    }),
  );
  controller.dispose();
}

Future<void> openPersonalFutureLetter(
    BuildContext context, AgendaStore store, FutureLetterRecord record) async {
  final guard = Cap0160TagEditGuard(store);
  if (!guard.isCurrent ||
      currentPersonalFutureLetter(store, record) == null) return;
  final today = DateTime.now();
  if (!record.isAvailableOn(today)) {
    final early = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(futureLetterLabel(AnnaStrings.of(dialog), 'early')),
        content: Text(futureLetterLabel(AnnaStrings.of(dialog), 'notice')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog, false),
            child: Text(quickWinText(AnnaStrings.of(dialog), 'undo'))),
          FilledButton(onPressed: () => Navigator.pop(dialog, true),
            child: Text(futureLetterLabel(AnnaStrings.of(dialog), 'read'))),
        ],
      ),
    );
    if (early != true) return;
  }
  if (!context.mounted || !guard.isCurrent ||
      currentPersonalFutureLetter(store, record) == null) return;
  await showDialog<void>(
    context: context,
    builder: (dialog) => AlertDialog(
      title: Text(futureLetterTitle(AnnaStrings.of(dialog))),
      // If the account switches or the letter is trashed while open, erase
      // the visible text on the next store notification. No stale snapshot.
      content: AnimatedBuilder(
        animation: store,
        builder: (dialog, _) {
          final current = guard.isCurrent
              ? currentPersonalFutureLetter(store, record) : null;
          return SingleChildScrollView(
            child: current == null
                ? Text(futureLetterLabel(
                    AnnaStrings.of(dialog), 'unavailable'))
                : SelectableText(current.block.text),
          );
        },
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialog),
          child: Text(futureLetterLabel(
              AnnaStrings.of(dialog), 'read'))),
      ],
    ),
  );
}

class PersonalFutureLettersScreen extends StatelessWidget {
  final AgendaStore store;
  const PersonalFutureLettersScreen({super.key, required this.store});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: store,
    builder: (context, _) {
      final strings = AnnaStrings.of(context);
      final letters = personalFutureLetters(store);
      final available = letters.where(
        (letter) => letter.isAvailableOn(DateTime.now())).toList();
      final waiting = letters.where(
        (letter) => !letter.isAvailableOn(DateTime.now())).toList();
      return Scaffold(
        appBar: AppBar(title: Text(futureLetterTitle(strings))),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: store.entryScopeReady &&
                  store.agendaContentFilter != AgendaContentFilter.sharedOnly
              ? () => composePersonalFutureLetter(context, store)
              : null,
          icon: const Icon(Icons.edit_note_outlined),
          label: Text(futureLetterLabel(strings, 'create')),
        ),
        body: SafeArea(child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(futureLetterLabel(strings, 'notice'),
              style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            if (letters.isEmpty)
              Text(futureLetterLabel(strings, 'empty')),
            for (final letter in [...available, ...waiting])
              Card(child: ListTile(
                key: ValueKey('future-letter-${letter.block.id}'),
                leading: const Icon(Icons.mark_email_unread_outlined),
                title: Text(DateFormat.yMMMMd(
                    AnnaStrings.intlLocale(context)).format(letter.day)),
                subtitle: Text(futureLetterLabel(strings,
                    letter.isAvailableOn(DateTime.now())
                        ? 'ready' : 'waiting')),
                onTap: () => openPersonalFutureLetter(
                    context, store, letter),
                trailing: IconButton(
                  tooltip: futureLetterLabel(strings, 'trash'),
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final account = store.activeAccountId;
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (dialog) => AlertDialog(
                        title: Text(futureLetterLabel(
                            AnnaStrings.of(dialog), 'trash')),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialog, false),
                            child: Text(quickWinText(
                                AnnaStrings.of(dialog), 'undo')),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(dialog, true),
                            child: Text(futureLetterLabel(
                                AnnaStrings.of(dialog), 'trash')),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && store.entryScopeReady &&
                        store.activeAccountId == account) {
                      await store.moveDiaryBlockToTrash(
                          letter.day, letter.block.id);
                    }
                  },
                ),
              )),
          ],
        )),
      );
    },
  );
}
