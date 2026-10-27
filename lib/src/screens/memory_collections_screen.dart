part of '../../main.dart';

class MemoryCollectionsScreen extends StatefulWidget {
  final AgendaStore store;

  const MemoryCollectionsScreen({
    super.key,
    required this.store,
  });

  @override
  State<MemoryCollectionsScreen> createState() =>
      _MemoryCollectionsScreenState();
}

class _MemoryCollectionsScreenState extends State<MemoryCollectionsScreen> {
  String _typeLabel(AnnaStrings strings, DiaryBlockType type) => switch (type) {
        DiaryBlockType.note => strings.v100Note,
        DiaryBlockType.sketch => strings.v100Sketch,
        DiaryBlockType.photo => strings.v100Photo,
        DiaryBlockType.voice => strings.v100VoiceNote,
      };

  String _collectionSummary(
    AnnaStrings strings,
    MemoryCollectionDefinition definition,
  ) {
    final parts = <String>[];
    if (definition.personId != null) {
      final person = widget.store.personById(definition.personId!);
      if (person != null) parts.add(person.name);
    }
    if (definition.place?.trim().isNotEmpty ?? false) {
      parts.add(definition.place!.trim());
    }
    if (definition.tag?.trim().isNotEmpty ?? false) {
      final tag = definition.tag!.trim();
      parts.add(tag.startsWith('#') ? tag : '#$tag');
    }
    if (definition.type != null) {
      parts.add(_typeLabel(strings, definition.type!));
    }
    if (definition.year != null) {
      parts.add(definition.year.toString());
    }
    return parts.join(' · ');
  }

  Future<void> _createCollection() async {
    final strings = AnnaStrings.of(context);
    final name = TextEditingController();
    final tag = TextEditingController();
    final year = TextEditingController();
    var personId = '';
    var place = '';
    var type = '';

    final people = [...widget.store.people]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final places = widget.store.diaryPlaceNames;

    final definition = await showDialog<MemoryCollectionDefinition>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final hasFilter = personId.isNotEmpty ||
              place.isNotEmpty ||
              tag.text.trim().isNotEmpty ||
              type.isNotEmpty ||
              year.text.trim().isNotEmpty;

          return AlertDialog(
            title: Text(strings.v105NewCollection),
            content: SizedBox(
              width: 440,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: name,
                      autofocus: true,
                      onChanged: (_) => setDialogState(() {}),
                      decoration: InputDecoration(
                        labelText: strings.v105CollectionName,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: personId,
                      decoration: InputDecoration(
                        labelText: strings.v105AnyPerson,
                      ),
                      items: [
                        DropdownMenuItem<String>(
                          value: '',
                          child: Text(strings.v105AnyPerson),
                        ),
                        ...people.map(
                          (person) => DropdownMenuItem<String>(
                            value: person.id,
                            child: Text(person.name),
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          setDialogState(() => personId = value ?? ''),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: place,
                      decoration: InputDecoration(
                        labelText: strings.v105AnyPlace,
                      ),
                      items: [
                        DropdownMenuItem<String>(
                          value: '',
                          child: Text(strings.v105AnyPlace),
                        ),
                        ...places.map(
                          (value) => DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          setDialogState(() => place = value ?? ''),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: type,
                      decoration: InputDecoration(
                        labelText: strings.v105AnyType,
                      ),
                      items: [
                        DropdownMenuItem<String>(
                          value: '',
                          child: Text(strings.v105AnyType),
                        ),
                        ...DiaryBlockType.values.map(
                          (value) => DropdownMenuItem<String>(
                            value: value.name,
                            child: Text(_typeLabel(strings, value)),
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          setDialogState(() => type = value ?? ''),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: tag,
                      onChanged: (_) => setDialogState(() {}),
                      decoration: InputDecoration(
                        labelText: strings.v105OptionalTag,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: year,
                      onChanged: (_) => setDialogState(() {}),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: strings.v105OptionalYear,
                      ),
                    ),
                    if (!hasFilter) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          strings.v105ChooseFilter,
                          style: TextStyle(
                            color: Theme.of(dialogContext).colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(strings.cancel),
              ),
              FilledButton(
                onPressed: name.text.trim().isEmpty || !hasFilter
                    ? null
                    : () {
                        final parsedYear = int.tryParse(year.text.trim());
                        final parsedType =
                            _memoryCollectionTypeFromName(type);
                        Navigator.pop(
                          dialogContext,
                          MemoryCollectionDefinition(
                            id: const Uuid().v4(),
                            name: name.text.trim(),
                            personId: personId.isEmpty ? null : personId,
                            place: place.isEmpty ? null : place,
                            tag: tag.text.trim().isEmpty
                                ? null
                                : tag.text.trim(),
                            type: parsedType,
                            year: parsedYear,
                          ),
                        );
                      },
                child: Text(strings.add),
              ),
            ],
          );
        },
      ),
    );

    name.dispose();
    tag.dispose();
    year.dispose();

    if (definition == null) return;
    await widget.store.saveMemoryCollection(definition);
    if (mounted) setState(() {});
  }

  Future<void> _openCollection(
    MemoryCollectionDefinition definition,
  ) async {
    final records = widget.store.memoryCollectionReferences(definition);
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => _MemoryDerivedResultsScreen(
          store: widget.store,
          title: definition.name,
          records: records,
        ),
      ),
    );
  }

  Future<void> _openThread(MemoryLifeThread thread) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => _MemoryDerivedResultsScreen(
          store: widget.store,
          title: thread.label,
          records: thread.memories,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AnnaStrings.of(context);
    final collections = widget.store.preferences.memoryCollections;
    final threads = widget.store.memoryLifeThreads();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${strings.v105Collections} · ${strings.v105LifeThreads}',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey<String>('memory-collections-add'),
        onPressed: _createCollection,
        icon: const Icon(Icons.add),
        label: Text(strings.v105NewCollection),
      ),
      body: Semantics(
        identifier: 'memory-collections-surface',
        container: true,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AnnaDesignTokens.spaceMd,
            AnnaDesignTokens.spaceSm,
            AnnaDesignTokens.spaceMd,
            100,
          ),
          children: [
            Text(
              strings.v105Collections,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: AnnaDesignTokens.space2xs),
            Text(strings.v105CollectionsIntro),
            const SizedBox(height: AnnaDesignTokens.spaceMd),
            if (collections.isEmpty)
              SimpleCard(child: Text(strings.v105NoCollections))
            else
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (var i = 0; i < collections.length; i++) ...[
                      Builder(
                        builder: (context) {
                          final definition = collections[i];
                          final count = widget.store
                              .memoryCollectionReferences(definition)
                              .length;
                          return ListTile(
                            key: ValueKey<String>(
                              'memory-collection-${definition.id}',
                            ),
                            leading:
                                const Icon(Icons.collections_bookmark_outlined),
                            title: Text(
                              definition.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            subtitle: Text(
                              [
                                _collectionSummary(strings, definition),
                                strings.v105MemoryCount(count),
                              ].where((value) => value.isNotEmpty).join(' · '),
                            ),
                            onTap: () => _openCollection(definition),
                            trailing: IconButton(
                              tooltip: strings.delete,
                              onPressed: () async {
                                await widget.store
                                    .deleteMemoryCollection(definition.id);
                                if (mounted) setState(() {});
                              },
                              icon: const Icon(Icons.delete_outline),
                            ),
                          );
                        },
                      ),
                      if (i != collections.length - 1)
                        const Divider(height: 1),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: AnnaDesignTokens.spaceXl),
            Text(
              strings.v105LifeThreads,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: AnnaDesignTokens.space2xs),
            Text(strings.v105LifeThreadsIntro),
            const SizedBox(height: AnnaDesignTokens.spaceMd),
            if (threads.isEmpty)
              SimpleCard(child: Text(strings.v105NoThreads))
            else
              ...threads.map(
                (thread) => Card(
                  child: ListTile(
                    key: ValueKey<String>('memory-thread-${thread.id}'),
                    leading: Icon(
                      switch (thread.kind) {
                        MemoryLifeThreadKind.person => Icons.person_outline,
                        MemoryLifeThreadKind.place => Icons.place_outlined,
                        MemoryLifeThreadKind.tag => Icons.tag,
                      },
                    ),
                    title: Text(
                      thread.label,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(strings.v105MemoryCount(thread.count)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openThread(thread),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MemoryDerivedResultsScreen extends StatelessWidget {
  final AgendaStore store;
  final String title;
  final List<DiaryBlockReference> records;

  const _MemoryDerivedResultsScreen({
    required this.store,
    required this.title,
    required this.records,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AnnaStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: records.isEmpty
          ? Center(child: Text(strings.v100RediscoverEmpty))
          : ListView.separated(
              padding: const EdgeInsets.all(AnnaDesignTokens.spaceMd),
              itemCount: records.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final reference = records[index];
                return ListTile(
                  leading: Icon(
                    switch (reference.block.type) {
                      DiaryBlockType.note => Icons.sticky_note_2_outlined,
                      DiaryBlockType.sketch => Icons.draw_outlined,
                      DiaryBlockType.photo => Icons.photo_outlined,
                      DiaryBlockType.voice => Icons.mic_none_outlined,
                    },
                  ),
                  title: Text(
                    store.diaryBlockDisplayTitle(
                      reference.block,
                      strings: strings,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    DateFormat(
                      'd MMMM yyyy',
                      AnnaStrings.intlLocale(context),
                    ).format(reference.date),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => PlannerScreen(
                        store: store,
                        initialDate: reference.date,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
