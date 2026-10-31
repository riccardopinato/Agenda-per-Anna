part of '../../main.dart';

/// DF-29–35: a fresh, dedicated search route. Its state survives pushing a
/// memory detail, but closing and reopening this route starts a NEW search.
class _DiaryGlobalSearchScreen extends StatefulWidget {
  final AgendaStore store;
  final String? personId;

  const _DiaryGlobalSearchScreen({required this.store, this.personId});

  @override
  State<_DiaryGlobalSearchScreen> createState() => _DiaryGlobalSearchScreenState();
}

class _DiaryGlobalSearchScreenState extends State<_DiaryGlobalSearchScreen> {
  final TextEditingController _query = TextEditingController();
  final ScrollController _scroll = ScrollController();
  DiaryBlockType? _type;
  bool _didAnimateSearchGroup = false;

  @override
  void dispose() {
    _query.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String _typeLabel(AnnaStrings strings, DiaryBlockType? type) => switch (type) {
    null => strings.all,
    DiaryBlockType.note => strings.v100MemoryNotesFilter,
    DiaryBlockType.photo => strings.v100Photo,
    DiaryBlockType.sketch => strings.v100Sketch,
    DiaryBlockType.voice => strings.v100MemoryVoiceFilter,
  };

  bool _matches(DiaryBlockReference record, String query, AnnaStrings strings) {
    final block = record.block;
    final text = <String>[
      block.text,
      ...block.pages.expand((page) => page.textElements).map((element) => element.text),
      ...block.places.map((place) => place.name),
      ...widget.store.peopleForIds(block.personIds)
          .map((person) => '${person.name} ${person.relationship}'),
      DateFormat('d MMMM yyyy', AnnaStrings.intlLocale(context)).format(record.date),
      DateFormat('MMMM yyyy', AnnaStrings.intlLocale(context)).format(record.date),
      '${record.date.year}',
      _typeLabel(strings, block.type),
      switch (block.type) {
        DiaryBlockType.note => 'note nota journal diario',
        DiaryBlockType.photo => 'photo foto image imagen immagine',
        DiaryBlockType.sketch => 'sketch drawing disegno boceto croquis',
        DiaryBlockType.voice => 'voice voz voix audio registrazione',
      },
    ].join(' ').toLowerCase();
    return text.contains(query);
  }

  List<DiaryBlockReference> _results(AnnaStrings strings) {
    final query = _query.text.trim().toLowerCase();
    if (query.isEmpty) return const <DiaryBlockReference>[];
    final records = widget.store.memoryReferences(
      includeArchived: false,
      personId: widget.personId,
    ).where((record) =>
        !record.block.archived &&
        (_type == null || record.block.type == _type) &&
        _matches(record, query, strings)).toList();
    records.sort((a, b) {
      final byDate = b.date.compareTo(a.date);
      if (byDate != 0) return byDate;
      final byCreated = b.block.createdAt.compareTo(a.block.createdAt);
      return byCreated != 0 ? byCreated : a.block.id.compareTo(b.block.id);
    });
    return records;
  }

  Future<void> _open(DiaryBlockReference record) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => record.block.type == DiaryBlockType.photo
            ? DiaryPhotoViewerScreen(
                store: widget.store, date: record.date, block: record.block)
            : _DiarySearchItemScreen(store: widget.store, record: record),
      ),
    );
    if (mounted) setState(() {});
  }

  Widget _thumbnail(DiaryBlock block) {
    final scheme = Theme.of(context).colorScheme;
    if (block.type == DiaryBlockType.photo && block.hasPhotoMedia) {
      return DiaryMediaImage(
        assetId: block.mediaThumbnailAssetId.isNotEmpty
            ? block.mediaThumbnailAssetId : block.mediaAssetId,
        fallbackBase64: block.imageBase64,
        cacheWidth: 120,
        empty: const Icon(Icons.broken_image_outlined),
      );
    }
    if (block.type == DiaryBlockType.sketch && block.pages.isNotEmpty) {
      return DiarySketchPagePreview(page: block.pages.first);
    }
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(child: Icon(switch (block.type) {
        DiaryBlockType.note => Icons.sticky_note_2_outlined,
        DiaryBlockType.photo => Icons.photo_outlined,
        DiaryBlockType.sketch => Icons.draw_outlined,
        DiaryBlockType.voice => Icons.mic_none_outlined,
      }, color: scheme.primary)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AnnaStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.d3('memoriesSearchAction')),
      ),
      body: SafeArea(
        child: Column(
          children: [
            AnnaMotionStagger(
              order: 0,
              child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _query,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: (_) {
                  if (_scroll.hasClients) _scroll.jumpTo(0);
                  setState(() {});
                },
                decoration: InputDecoration(
                  prefixIcon: const Hero(
                    tag: 'v108-search-lens',
                    child: Icon(Icons.search),
                  ),
                  hintText: strings.v100MemorySearchHint,
                  suffixIcon: _query.text.isEmpty ? null : IconButton(
                    tooltip: strings.v100ClearSearch,
                    onPressed: () {
                      _query.clear();
                      if (_scroll.hasClients) _scroll.jumpTo(0);
                      setState(() {});
                    },
                    icon: const Icon(Icons.close),
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              ),
            ),
            AnnaMotionStagger(
              order: 1,
              child: SizedBox(
              height: 54,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: <DiaryBlockType?>[
                  null,
                  DiaryBlockType.note,
                  DiaryBlockType.photo,
                  DiaryBlockType.sketch,
                  DiaryBlockType.voice,
                ].map((type) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    key: ValueKey<String>('ui5-search-${type?.name ?? 'all'}'),
                    label: Text(_typeLabel(strings, type)),
                    selected: _type == type,
                    onSelected: (_) {
                      if (_scroll.hasClients) _scroll.jumpTo(0);
                      setState(() => _type = type);
                    },
                  ),
                )).toList(),
              ),
              ),
            ),
            Expanded(
              child: AnimatedBuilder(
                animation: widget.store.journalRevision,
                builder: (context, _) {
                  final query = _query.text.trim();
                  if (query.isEmpty) {
                    _didAnimateSearchGroup = false;
                    return Center(child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.search, size: 32),
                          const SizedBox(height: 12),
                          Text(strings.d3('ui5SearchHint'),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ));
                  }
                  final records = _results(strings);
                  if (records.isEmpty) {
                    return Center(child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.search_off_outlined, size: 32),
                          const SizedBox(height: 12),
                          Text(strings.d3('ui5SearchNoResults'),
                            style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 6),
                          Text(strings.d3('ui5SearchNoResultsHint'),
                            textAlign: TextAlign.center),
                          if (_type != null) ...[
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () => setState(() => _type = null),
                              icon: const Icon(Icons.restart_alt),
                              label: Text(strings.d3('ui5SearchAll')),
                            ),
                          ],
                        ],
                      ),
                    ));
                  }
                  final animateFirstGroup = !_didAnimateSearchGroup;
                  _didAnimateSearchGroup = true;
                  return ListView.builder(
                    key: const ValueKey<String>('ui5-search-results'),
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: records.length,
                    itemBuilder: (context, i) {
                      final record = records[i];
                      final title = widget.store.diaryBlockDisplayTitle(
                        record.block, strings: strings);
                      final date = DateFormat('EEEE d MMMM yyyy',
                        AnnaStrings.intlLocale(context)).format(record.date);
                      final resultCard = Card(
                        margin: const EdgeInsets.only(bottom: 6),
                        child: ListTile(
                          key: ValueKey<String>('ui5-search-result-${record.block.id}'),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(height: 52, width: 52,
                              child: _thumbnail(record.block)),
                          ),
                          title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
                          subtitle: Text(date),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _open(record),
                        ),
                      );
                      return i < 4 && animateFirstGroup
                          ? AnnaMotionStagger(
                              key: ValueKey<String>(
                                'v108-search-${record.block.id}'),
                              order: i,
                              child: resultCard,
                            )
                          : resultCard;
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A real single-item route for text, sketch and audio search results.
/// Editing and canonical state ownership remain in the day diary.
class _DiarySearchItemScreen extends StatelessWidget {
  final AgendaStore store;
  final DiaryBlockReference record;

  const _DiarySearchItemScreen({required this.store, required this.record});

  Future<void> _playVoice(BuildContext context) async {
    final block = record.block;
    final bytes = await _readDiaryMediaBytes(
      assetId: block.mediaAssetId, fallbackBase64: block.audioBase64);
    if (bytes == null || bytes.isEmpty || !context.mounted) return;
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AnnaStrings.of(context).d3('webAudioHint'))));
      return;
    }
    try {
      await VoiceDiaryService.instance.play(bytes);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AnnaStrings.of(context).d3('cannotPlayAudio'))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AnnaStrings.of(context);
    final block = record.block;
    final title = store.diaryBlockDisplayTitle(block, strings: strings);
    final date = DateFormat('EEEE d MMMM yyyy',
      AnnaStrings.intlLocale(context)).format(record.date);
    return Scaffold(
      appBar: AppBar(title: Text(strings.navMemories)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AnnaDesignTokens.readingContentWidth),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(title, style: AnnaJournalTypography.editorial(context, size: 26)),
              const SizedBox(height: 8),
              Text(date, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 20),
              if (block.type == DiaryBlockType.note)
                SelectableText(block.text, style: Theme.of(context).textTheme.bodyLarge),
              if (block.type == DiaryBlockType.sketch)
                AspectRatio(
                  aspectRatio: 1,
                  child: block.pages.isEmpty
                    ? const Center(child: Icon(Icons.draw_outlined))
                    : DiarySketchPagePreview(page: block.pages.first),
                ),
              if (block.type == DiaryBlockType.voice) ...[
                if (block.text.isNotEmpty) Text(block.text),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: block.hasVoiceMedia ? () => _playVoice(context) : null,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(strings.d3('ui5PlayVoice')),
                ),
              ],
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PlannerScreen(
                      store: store, initialDate: record.date),
                  ),
                ),
                icon: const Icon(Icons.today_outlined),
                label: Text(strings.d3('ui5OpenDiaryDay')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
