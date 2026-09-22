part of '../main.dart';

Future<String?> _pickCompressedDiaryImageBase64(
  ImageSource source, {
  int maxSide = 720,
  int quality = 58,
}) async {
  final picked = await ImagePicker().pickImage(
    source: source,
    requestFullMetadata: false,
  );
  if (picked == null) return null;

  final bytes = await picked.readAsBytes();
  var compressed = await FlutterImageCompress.compressWithList(
    bytes,
    minWidth: maxSide,
    minHeight: maxSide,
    quality: quality,
    format: CompressFormat.jpeg,
  );

  if (compressed.lengthInBytes > 220 * 1024) {
    compressed = await FlutterImageCompress.compressWithList(
      bytes,
      minWidth: 520,
      minHeight: 520,
      quality: 48,
      format: CompressFormat.jpeg,
    );
  }

  return base64Encode(compressed);
}

Future<ImageSource?> _chooseDiaryImageSource(BuildContext context) =>
    showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            const ListTile(
              title: Text(
                'Aggiungi una foto',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Text(
                'Nel diario viene salvata una copia compressa, non l’originale.',
              ),
            ),
            ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.photo_camera_outlined),
              ),
              title: const Text('Scatta una foto'),
              onTap: () =>
                  Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.photo_library_outlined),
              ),
              title: const Text('Scegli dalla galleria'),
              onTap: () =>
                  Navigator.pop(sheetContext, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

enum DiaryContentKind { note, photo, sketch }

extension DiaryContentKindUi on DiaryContentKind {
  String get label => switch (this) {
        DiaryContentKind.note => 'Nota',
        DiaryContentKind.photo => 'Foto',
        DiaryContentKind.sketch => 'Sketch',
      };

  IconData get icon => switch (this) {
        DiaryContentKind.note => Icons.sticky_note_2_outlined,
        DiaryContentKind.photo => Icons.photo_outlined,
        DiaryContentKind.sketch => Icons.draw_outlined,
      };
}

class DiaryComposerSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final String memoriesLabel;
  final String emptyText;
  final VoidCallback onMemories;
  final VoidCallback onAddNote;
  final VoidCallback onAddSketch;
  final VoidCallback onAddPhoto;
  final bool photoBusy;
  final List<Widget> children;

  const DiaryComposerSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.memoriesLabel,
    required this.emptyText,
    required this.onMemories,
    required this.onAddNote,
    required this.onAddSketch,
    required this.onAddPhoto,
    required this.photoBusy,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return SimpleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onMemories,
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: Text(memoriesLabel),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: onAddNote,
                icon: const Icon(Icons.sticky_note_2_outlined),
                label: const Text('Nota'),
              ),
              FilledButton.tonalIcon(
                onPressed: onAddSketch,
                icon: const Icon(Icons.draw_outlined),
                label: const Text('Sketch'),
              ),
              FilledButton.tonalIcon(
                onPressed: photoBusy ? null : onAddPhoto,
                icon: photoBusy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Foto'),
              ),
            ],
          ),
          if (children.isEmpty) ...[
            const SizedBox(height: 14),
            Text(emptyText),
          ] else ...[
            const SizedBox(height: 14),
            ...children,
          ],
        ],
      ),
    );
  }
}

class DiaryContentCard extends StatelessWidget {
  final DiaryContentKind kind;
  final String title;
  final String subtitle;
  final Widget? preview;
  final VoidCallback onOpen;
  final VoidCallback? onEdit;
  final VoidCallback? onEditCaption;
  final VoidCallback? onReplacePhoto;
  final VoidCallback onDelete;
  final Widget? footer;
  final Widget? statusIcon;

  const DiaryContentCard({
    super.key,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.onOpen,
    required this.onDelete,
    this.preview,
    this.onEdit,
    this.onEditCaption,
    this.onReplacePhoto,
    this.footer,
    this.statusIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          if (preview != null)
            AspectRatio(
              aspectRatio: 16 / 10,
              child: InkWell(
                onTap: onOpen,
                child: preview!,
              ),
            ),
          ListTile(
            leading: CircleAvatar(child: Icon(kind.icon)),
            title: Text(
              title,
              maxLines: kind == DiaryContentKind.note ? 4 : 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              subtitle,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: onOpen,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (statusIcon != null) ...[
                  statusIcon!,
                  const SizedBox(width: 2),
                ],
                PopupMenuButton<String>(
                  tooltip: 'Azioni ${kind.label.toLowerCase()}',
                  onSelected: (value) {
                    if (value == 'edit') onEdit?.call();
                    if (value == 'caption') onEditCaption?.call();
                    if (value == 'replace') onReplacePhoto?.call();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    if (kind != DiaryContentKind.photo && onEdit != null)
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Modifica'),
                      ),
                    if (kind == DiaryContentKind.photo &&
                        onEditCaption != null)
                      const PopupMenuItem(
                        value: 'caption',
                        child: Text('Modifica didascalia'),
                      ),
                    if (kind == DiaryContentKind.photo &&
                        onReplacePhoto != null)
                      const PopupMenuItem(
                        value: 'replace',
                        child: Text('Sostituisci foto'),
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
          if (footer != null) ...[
            const Divider(height: 1),
            footer!,
          ],
        ],
      ),
    );
  }
}

class DiaryMemoryCard extends StatefulWidget {
  final AgendaStore store;
  final DateTime date;

  const DiaryMemoryCard({
    super.key,
    required this.store,
    required this.date,
  });

  @override
  State<DiaryMemoryCard> createState() => _DiaryMemoryCardState();
}

class _DiaryMemoryCardState extends State<DiaryMemoryCard> {
  bool photoBusy = false;

  List<DiaryBlock> get _blocks {
    final result = [...widget.store.journal(widget.date).blocks];
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  Future<void> _saveBlocks(List<DiaryBlock> blocks) async {
    final current = widget.store.journal(widget.date);
    await widget.store.saveJournal(
      widget.date,
      current.copyWith(blocks: blocks),
    );
  }

  Future<void> _addNote([DiaryBlock? existing]) async {
    final controller = TextEditingController(text: existing?.text ?? '');
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(existing == null ? 'Nuova nota' : 'Modifica nota'),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 5,
          maxLines: 12,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText:
                'Scrivi un ricordo, un pensiero, qualcosa da non dimenticare...',
            border: OutlineInputBorder(),
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
              controller.text.trim(),
            ),
            child: const Text('Salva'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || value.isEmpty) return;

    final blocks = [...widget.store.journal(widget.date).blocks];
    if (existing == null) {
      blocks.add(
        DiaryBlock(
          id: const Uuid().v4(),
          type: DiaryBlockType.note,
          createdAt: DateTime.now(),
          text: value,
        ),
      );
    } else {
      final index = blocks.indexWhere((block) => block.id == existing.id);
      if (index >= 0) blocks[index] = existing.copyWith(text: value);
    }
    await _saveBlocks(blocks);
  }

  Future<void> _addPhoto() async {
    if (photoBusy) return;
    final source = await _chooseDiaryImageSource(context);
    if (source == null || !mounted) return;

    setState(() => photoBusy = true);
    try {
      final imageBase64 = await _pickCompressedDiaryImageBase64(source);
      if (imageBase64 == null || !mounted) return;

      final captionController = TextEditingController();
      final caption = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Aggiungi al diario'),
          content: TextField(
            controller: captionController,
            autofocus: true,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Una didascalia, se vuoi...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, ''),
              child: const Text('Senza testo'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                captionController.text.trim(),
              ),
              child: const Text('Aggiungi'),
            ),
          ],
        ),
      );
      captionController.dispose();
      if (caption == null) return;

      final blocks = [
        ...widget.store.journal(widget.date).blocks,
        DiaryBlock(
          id: const Uuid().v4(),
          type: DiaryBlockType.photo,
          createdAt: DateTime.now(),
          text: caption,
          imageBase64: imageBase64,
        ),
      ];
      await _saveBlocks(blocks);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Non riesco ad aggiungere questa foto.'),
        ),
      );
    } finally {
      if (mounted) setState(() => photoBusy = false);
    }
  }

  Future<void> _editPhotoCaption(DiaryBlock block) async {
    final controller = TextEditingController(text: block.text);
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Didascalia'),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 2,
          maxLines: 5,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Scrivi qualcosa su questo ricordo...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Salva'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null) return;

    final blocks = [...widget.store.journal(widget.date).blocks];
    final index = blocks.indexWhere((candidate) => candidate.id == block.id);
    if (index >= 0) {
      blocks[index] = block.copyWith(text: value);
      await _saveBlocks(blocks);
    }
  }

  Future<void> _replacePhoto(DiaryBlock block) async {
    final source = await _chooseDiaryImageSource(context);
    if (source == null || !mounted) return;

    setState(() => photoBusy = true);
    try {
      final imageBase64 = await _pickCompressedDiaryImageBase64(source);
      if (imageBase64 == null) return;

      final blocks = [...widget.store.journal(widget.date).blocks];
      final index =
          blocks.indexWhere((candidate) => candidate.id == block.id);
      if (index >= 0) {
        blocks[index] = block.copyWith(imageBase64: imageBase64);
        await _saveBlocks(blocks);
      }
    } finally {
      if (mounted) setState(() => photoBusy = false);
    }
  }

  Future<void> _openSketch([DiaryBlock? existing]) async {
    final initialPages = existing?.pages.isNotEmpty == true
        ? existing!.pages
        : [
            DiarySketchPage(
              id: const Uuid().v4(),
            ),
          ];

    final pages = await Navigator.push<List<DiarySketchPage>>(
      context,
      MaterialPageRoute(
        builder: (_) => DiarySketchbookScreen(
          initialPages: initialPages,
        ),
      ),
    );
    if (pages == null || pages.isEmpty) return;

    final blocks = [...widget.store.journal(widget.date).blocks];
    if (existing == null) {
      blocks.add(
        DiaryBlock(
          id: const Uuid().v4(),
          type: DiaryBlockType.sketch,
          createdAt: DateTime.now(),
          pages: pages,
        ),
      );
    } else {
      final index = blocks.indexWhere((block) => block.id == existing.id);
      if (index >= 0) blocks[index] = existing.copyWith(pages: pages);
    }
    await _saveBlocks(blocks);
  }

  Future<void> _delete(DiaryBlock block) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Eliminare dal diario?'),
            content: const Text(
              'Questo contenuto verrà rimosso dalla giornata.',
            ),
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

    final blocks = [...widget.store.journal(widget.date).blocks]
      ..removeWhere((candidate) => candidate.id == block.id);
    await _saveBlocks(blocks);
  }

  void _openPhoto(DiaryBlock block) {
    if (block.imageBase64.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DiaryPhotoViewerScreen(
          store: widget.store,
          date: widget.date,
          block: block,
        ),
      ),
    );
  }

  Widget _blockCard(BuildContext context, DiaryBlock block) {
    final time = DateFormat('HH:mm', 'it_IT').format(block.createdAt);

    switch (block.type) {
      case DiaryBlockType.note:
        return DiaryContentCard(
          kind: DiaryContentKind.note,
          title: block.text,
          subtitle: 'Nota · $time',
          onOpen: () => _addNote(block),
          onEdit: () => _addNote(block),
          onDelete: () => _delete(block),
        );
      case DiaryBlockType.photo:
        return DiaryContentCard(
          kind: DiaryContentKind.photo,
          title: block.text.trim().isEmpty
              ? 'Foto del giorno'
              : block.text,
          subtitle: 'Foto · $time',
          preview: block.imageBase64.isEmpty
              ? null
              : Image.memory(
                  base64Decode(block.imageBase64),
                  fit: BoxFit.cover,
                  cacheWidth: 720,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image_outlined),
                  ),
                ),
          onOpen: () => _openPhoto(block),
          onEditCaption: () => _editPhotoCaption(block),
          onReplacePhoto: () => _replacePhoto(block),
          onDelete: () => _delete(block),
        );
      case DiaryBlockType.sketch:
        final page = block.pages.isEmpty
            ? DiarySketchPage(id: block.id)
            : block.pages.first;
        return DiaryContentCard(
          kind: DiaryContentKind.sketch,
          title: block.pages.length <= 1
              ? 'Sketch'
              : 'Sketch · ${block.pages.length} pagine',
          subtitle: 'Sketch · $time',
          preview: DiarySketchPagePreview(page: page),
          onOpen: () => _openSketch(block),
          onEdit: () => _openSketch(block),
          onDelete: () => _delete(block),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final blocks = _blocks;

    return DiaryComposerSection(
      title: 'Il mio diario',
      subtitle:
          'Note, sketch e foto restano personali. Gli stessi strumenti sono disponibili anche in Noi ♡.',
      memoriesLabel: 'Ricordi',
      emptyText:
          'Qui puoi costruire la giornata come una pagina di diario, un ricordo alla volta.',
      onMemories: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DiaryMemoriesScreen(store: widget.store),
        ),
      ),
      onAddNote: () => _addNote(),
      onAddSketch: () => _openSketch(),
      onAddPhoto: _addPhoto,
      photoBusy: photoBusy,
      children: blocks
          .map((block) => _blockCard(context, block))
          .toList(growable: false),
    );
  }
}

class _DiaryMemoryRecord {
  final DateTime date;
  final DiaryBlock block;

  const _DiaryMemoryRecord({
    required this.date,
    required this.block,
  });
}

enum _DiaryMemoriesView { memories, days, months, years }

class DiaryMemoriesScreen extends StatefulWidget {
  final AgendaStore store;

  const DiaryMemoriesScreen({
    super.key,
    required this.store,
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
    final searchable = [
      block.text,
      sketchText,
      DateFormat('d MMMM yyyy', 'it_IT').format(record.date),
      DateFormat('MMMM yyyy', 'it_IT').format(record.date),
      '${record.date.year}',
      switch (block.type) {
        DiaryBlockType.note => 'nota note',
        DiaryBlockType.sketch => 'sketch disegno',
        DiaryBlockType.photo => 'foto immagine',
      },
    ].join(' ').toLowerCase();
    return searchable.contains(query);
  }

  List<_DiaryMemoryRecord> _records() {
    final query = searchController.text.trim().toLowerCase();
    return _allRecords().where((record) {
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
          record.block.imageBase64.isNotEmpty) {
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
        if (block.imageBase64.isEmpty) {
          return const ColoredBox(
            color: Color(0xFFF2EEF5),
            child: Center(child: Icon(Icons.photo_outlined, size: 42)),
          );
        }
        return Image.memory(
          base64Decode(block.imageBase64),
          fit: fit,
          width: double.infinity,
          height: double.infinity,
          cacheWidth: 720,
          errorBuilder: (_, __, ___) => const ColoredBox(
            color: Color(0xFFF2EEF5),
            child: Center(child: Icon(Icons.broken_image_outlined)),
          ),
        );
      case DiaryBlockType.sketch:
        final page = block.pages.isEmpty
            ? DiarySketchPage(id: block.id)
            : block.pages.first;
        return DiarySketchPagePreview(page: page);
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

  Widget _emptyState() => const Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Text(
            'Nessun ricordo corrisponde a questa ricerca. Aggiungi una nota, una foto o uno sketch in una giornata.',
            textAlign: TextAlign.center,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'I miei ricordi',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: AnimatedBuilder(
        animation: widget.store,
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
                            },
                          ),
                          label: Text(
                            switch (type) {
                              DiaryBlockType.note => 'Note',
                              DiaryBlockType.sketch => 'Sketch',
                              DiaryBlockType.photo => 'Foto',
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

class DiaryPhotoViewerScreen extends StatelessWidget {
  final AgendaStore store;
  final DateTime date;
  final DiaryBlock block;

  const DiaryPhotoViewerScreen({
    super.key,
    required this.store,
    required this.date,
    required this.block,
  });

  @override
  Widget build(BuildContext context) {
    final dateLabel =
        _cap(DateFormat('EEEE d MMMM yyyy', 'it_IT').format(date));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          dateLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: 'Apri giornata',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PlannerScreen(
                  store: store,
                  initialDate: date,
                ),
              ),
            ),
            icon: const Icon(Icons.calendar_today_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: InteractiveViewer(
                minScale: 0.75,
                maxScale: 6,
                child: Center(
                  child: block.imageBase64.isEmpty
                      ? const Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white70,
                          size: 64,
                        )
                      : Image.memory(
                          base64Decode(block.imageBase64),
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white70,
                            size: 64,
                          ),
                        ),
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.92),
                border: const Border(
                  top: BorderSide(color: Colors.white12),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (block.text.trim().isNotEmpty) ...[
                      Text(
                        block.text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white38),
                            ),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MonthScreen(
                                  store: store,
                                  initialMonth:
                                      DateTime(date.year, date.month),
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.calendar_month_outlined),
                            label: const Text('Mese'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white38),
                            ),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => YearScreen(
                                  store: store,
                                  initialYear: date.year,
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.insights_outlined),
                            label: const Text('Anno'),
                          ),
                        ),
                      ],
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

class DiarySketchbookScreen extends StatefulWidget {
  final List<DiarySketchPage> initialPages;

  const DiarySketchbookScreen({
    super.key,
    required this.initialPages,
  });

  @override
  State<DiarySketchbookScreen> createState() =>
      _DiarySketchbookScreenState();
}

class _DiarySketchbookScreenState extends State<DiarySketchbookScreen> {
  late List<DiarySketchPage> pages;
  int pageIndex = 0;
  DiarySketchTool tool = DiarySketchTool.pen;
  int colorValue = 0xFF222222;
  double width = 3;
  double textSize = 22;
  DiarySketchStroke? activeStroke;
  List<DiarySketchPoint> lassoPoints = const [];

  final Set<int> selectedStrokeIndices = {};
  final Set<String> selectedTextIds = {};
  final Set<String> selectedImageIds = {};

  final Map<String, List<DiarySketchPage>> _undo = {};
  final Map<String, List<DiarySketchPage>> _redo = {};
  final TransformationController _transform = TransformationController();
  final GlobalKey _pageBoundaryKey = GlobalKey();

  bool _selectionMoveStarted = false;

  static const _colors = <int>[
    0xFF222222,
    0xFFE86D91,
    0xFF7868D8,
    0xFF4F8EC9,
    0xFF579D78,
    0xFFE19A43,
  ];

  @override
  void initState() {
    super.initState();
    pages = widget.initialPages.map(_clonePage).toList();
    if (pages.isEmpty) {
      pages = [DiarySketchPage(id: const Uuid().v4())];
    }
  }

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  DiarySketchPage _clonePage(DiarySketchPage source, {String? id}) =>
      DiarySketchPage(
        id: id ?? source.id,
        paper: source.paper,
        strokes: source.strokes
            .map(
              (stroke) => DiarySketchStroke(
                tool: stroke.tool,
                colorValue: stroke.colorValue,
                width: stroke.width,
                points: stroke.points
                    .map((point) => DiarySketchPoint(point.x, point.y))
                    .toList(),
              ),
            )
            .toList(),
        textElements: source.textElements
            .map(
              (element) => DiarySketchTextElement(
                id: element.id,
                text: element.text,
                x: element.x,
                y: element.y,
                fontSize: element.fontSize,
                colorValue: element.colorValue,
              ),
            )
            .toList(),
        imageElements: source.imageElements
            .map(
              (element) => DiarySketchImageElement(
                id: element.id,
                imageBase64: element.imageBase64,
                x: element.x,
                y: element.y,
                width: element.width,
                height: element.height,
              ),
            )
            .toList(),
      );

  DiarySketchPage get page => pages[pageIndex];

  void _clearSelection() {
    selectedStrokeIndices.clear();
    selectedTextIds.clear();
    selectedImageIds.clear();
  }

  void _pushHistory() {
    final stack = _undo.putIfAbsent(page.id, () => []);
    stack.add(_clonePage(page));
    if (stack.length > 50) stack.removeAt(0);
    _redo[page.id] = [];
  }

  void _replacePage(
    DiarySketchPage value, {
    bool history = false,
  }) {
    if (history) _pushHistory();
    setState(() => pages[pageIndex] = value);
  }

  void _undoAction() {
    final stack = _undo[page.id];
    if (stack == null || stack.isEmpty) return;
    final previous = stack.removeLast();
    _redo.putIfAbsent(page.id, () => []).add(_clonePage(page));
    setState(() {
      pages[pageIndex] = previous;
      _clearSelection();
      activeStroke = null;
      lassoPoints = const [];
    });
  }

  void _redoAction() {
    final stack = _redo[page.id];
    if (stack == null || stack.isEmpty) return;
    final next = stack.removeLast();
    _undo.putIfAbsent(page.id, () => []).add(_clonePage(page));
    setState(() {
      pages[pageIndex] = next;
      _clearSelection();
      activeStroke = null;
      lassoPoints = const [];
    });
  }

  DiarySketchPoint _point(Offset local, Size size) {
    final canvasWidth = size.width <= 0 ? 1.0 : size.width;
    final canvasHeight = size.height <= 0 ? 1.0 : size.height;
    return DiarySketchPoint(
      (local.dx / canvasWidth).clamp(0.0, 1.0),
      (local.dy / canvasHeight).clamp(0.0, 1.0),
    );
  }

  DiarySketchPoint _strokeCenter(DiarySketchStroke stroke) {
    if (stroke.points.isEmpty) return const DiarySketchPoint(0, 0);
    var sx = 0.0;
    var sy = 0.0;
    for (final point in stroke.points) {
      sx += point.x;
      sy += point.y;
    }
    return DiarySketchPoint(
      sx / stroke.points.length,
      sy / stroke.points.length,
    );
  }

  double _distanceSquared(DiarySketchPoint a, DiarySketchPoint b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    return dx * dx + dy * dy;
  }

  bool _insidePolygon(
    DiarySketchPoint point,
    List<DiarySketchPoint> polygon,
  ) {
    if (polygon.length < 3) return false;
    var inside = false;
    for (var i = 0, j = polygon.length - 1;
        i < polygon.length;
        j = i++) {
      final pi = polygon[i];
      final pj = polygon[j];
      final denominator =
          (pj.y - pi.y).abs() < 0.000001 ? 0.000001 : pj.y - pi.y;
      final intersects = ((pi.y > point.y) != (pj.y > point.y)) &&
          (point.x <
              (pj.x - pi.x) * (point.y - pi.y) / denominator + pi.x);
      if (intersects) inside = !inside;
    }
    return inside;
  }

  void _selectAt(DiarySketchPoint point) {
    _clearSelection();

    for (final image in page.imageElements.reversed) {
      if (point.x >= image.x &&
          point.x <= image.x + image.width &&
          point.y >= image.y &&
          point.y <= image.y + image.height) {
        selectedImageIds.add(image.id);
        return;
      }
    }

    for (final element in page.textElements.reversed) {
      final estimatedWidth =
          (element.text.length * element.fontSize * 0.00095).clamp(0.12, 0.7);
      final estimatedHeight =
          (element.fontSize * 0.0028).clamp(0.05, 0.18);
      if (point.x >= element.x &&
          point.x <= element.x + estimatedWidth &&
          point.y >= element.y &&
          point.y <= element.y + estimatedHeight) {
        selectedTextIds.add(element.id);
        return;
      }
    }

    var bestIndex = -1;
    var bestDistance = double.infinity;
    for (var index = 0; index < page.strokes.length; index++) {
      final stroke = page.strokes[index];
      if (stroke.points.isEmpty) continue;
      var distance = _distanceSquared(point, _strokeCenter(stroke));
      for (final strokePoint in stroke.points) {
        final candidate = _distanceSquared(point, strokePoint);
        if (candidate < distance) distance = candidate;
      }
      if (distance < bestDistance) {
        bestDistance = distance;
        bestIndex = index;
      }
    }
    if (bestIndex >= 0 && bestDistance <= 0.012) {
      selectedStrokeIndices.add(bestIndex);
    }
  }

  void _start(DragStartDetails details, Size size) {
    if (tool == DiarySketchTool.hand) return;
    final p = _point(details.localPosition, size);

    if (tool == DiarySketchTool.select) {
      setState(() {
        _selectAt(p);
        _selectionMoveStarted =
            selectedStrokeIndices.isNotEmpty ||
                selectedTextIds.isNotEmpty ||
                selectedImageIds.isNotEmpty;
        if (_selectionMoveStarted) _pushHistory();
      });
      return;
    }

    if (tool == DiarySketchTool.lasso) {
      setState(() {
        lassoPoints = [p];
        activeStroke = null;
      });
      return;
    }

    setState(() {
      activeStroke = DiarySketchStroke(
        tool: tool,
        colorValue: colorValue,
        width: width,
        points: [p],
      );
    });
  }

  void _moveSelection(Offset delta, Size size) {
    final dx = delta.dx / (size.width <= 0 ? 1 : size.width);
    final dy = delta.dy / (size.height <= 0 ? 1 : size.height);
    if (dx == 0 && dy == 0) return;

    final movedStrokes = page.strokes.asMap().entries.map((entry) {
      if (!selectedStrokeIndices.contains(entry.key)) return entry.value;
      return entry.value.copyWith(
        points: entry.value.points
            .map(
              (point) => DiarySketchPoint(
                (point.x + dx).clamp(0.0, 1.0),
                (point.y + dy).clamp(0.0, 1.0),
              ),
            )
            .toList(),
      );
    }).toList();

    final movedText = page.textElements.map((element) {
      if (!selectedTextIds.contains(element.id)) return element;
      return element.copyWith(
        x: (element.x + dx).clamp(0.0, 0.96),
        y: (element.y + dy).clamp(0.0, 0.96),
      );
    }).toList();

    final movedImages = page.imageElements.map((element) {
      if (!selectedImageIds.contains(element.id)) return element;
      return element.copyWith(
        x: (element.x + dx).clamp(
          0.0,
          (1.0 - element.width).clamp(0.0, 1.0),
        ),
        y: (element.y + dy).clamp(
          0.0,
          (1.0 - element.height).clamp(0.0, 1.0),
        ),
      );
    }).toList();

    setState(() {
      pages[pageIndex] = page.copyWith(
        strokes: movedStrokes,
        textElements: movedText,
        imageElements: movedImages,
      );
    });
  }

  void _update(DragUpdateDetails details, Size size) {
    if (tool == DiarySketchTool.hand) return;

    if (tool == DiarySketchTool.select) {
      if (_selectionMoveStarted) {
        _moveSelection(details.delta, size);
      }
      return;
    }

    final p = _point(details.localPosition, size);
    if (tool == DiarySketchTool.lasso) {
      setState(() => lassoPoints = [...lassoPoints, p]);
      return;
    }

    final current = activeStroke;
    if (current == null) return;
    setState(() {
      if (current.tool == DiarySketchTool.line ||
          current.tool == DiarySketchTool.rectangle ||
          current.tool == DiarySketchTool.ellipse) {
        activeStroke = DiarySketchStroke(
          tool: current.tool,
          colorValue: current.colorValue,
          width: current.width,
          points: [current.points.first, p],
        );
      } else {
        activeStroke = DiarySketchStroke(
          tool: current.tool,
          colorValue: current.colorValue,
          width: current.width,
          points: [...current.points, p],
        );
      }
    });
  }

  void _finishLasso() {
    final polygon = lassoPoints;
    if (polygon.length < 3) {
      setState(() {
        lassoPoints = const [];
        tool = DiarySketchTool.select;
      });
      return;
    }

    _clearSelection();
    for (var index = 0; index < page.strokes.length; index++) {
      if (_insidePolygon(_strokeCenter(page.strokes[index]), polygon)) {
        selectedStrokeIndices.add(index);
      }
    }
    for (final element in page.textElements) {
      if (_insidePolygon(
        DiarySketchPoint(element.x, element.y),
        polygon,
      )) {
        selectedTextIds.add(element.id);
      }
    }
    for (final element in page.imageElements) {
      if (_insidePolygon(
        DiarySketchPoint(
          element.x + element.width / 2,
          element.y + element.height / 2,
        ),
        polygon,
      )) {
        selectedImageIds.add(element.id);
      }
    }

    setState(() {
      lassoPoints = const [];
      tool = DiarySketchTool.select;
    });
  }

  void _end(DragEndDetails details) {
    if (tool == DiarySketchTool.hand) return;

    if (tool == DiarySketchTool.select) {
      _selectionMoveStarted = false;
      return;
    }

    if (tool == DiarySketchTool.lasso) {
      _finishLasso();
      return;
    }

    final stroke = activeStroke;
    if (stroke == null || stroke.points.isEmpty) return;
    _pushHistory();
    setState(() {
      pages[pageIndex] = page.copyWith(
        strokes: [...page.strokes, stroke],
      );
      activeStroke = null;
    });
  }

  Future<void> _addText() async {
    DiarySketchTextElement? existing;
    if (selectedTextIds.length == 1) {
      final id = selectedTextIds.first;
      for (final item in page.textElements) {
        if (item.id == id) {
          existing = item;
          break;
        }
      }
    }

    final controller = TextEditingController(text: existing?.text ?? '');
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(existing == null ? 'Aggiungi testo' : 'Modifica testo'),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 2,
          maxLines: 6,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Scrivi sul foglio...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Inserisci'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || value.isEmpty) return;

    _pushHistory();
    if (existing == null) {
      final element = DiarySketchTextElement(
        id: const Uuid().v4(),
        text: value,
        x: 0.12,
        y: 0.12,
        fontSize: textSize,
        colorValue: colorValue,
      );
      setState(() {
        pages[pageIndex] = page.copyWith(
          textElements: [...page.textElements, element],
        );
        _clearSelection();
        selectedTextIds.add(element.id);
        tool = DiarySketchTool.select;
      });
    } else {
      final existingId = existing.id;
      final updated = page.textElements
          .map(
            (item) => item.id == existingId
                ? item.copyWith(
                    text: value,
                    fontSize: textSize,
                    colorValue: colorValue,
                  )
                : item,
          )
          .toList();
      setState(() {
        pages[pageIndex] = page.copyWith(textElements: updated);
        tool = DiarySketchTool.select;
      });
    }
  }

  Future<void> _addImage() async {
    final source = await _chooseDiaryImageSource(context);
    if (source == null || !mounted) return;

    try {
      final imageBase64 = await _pickCompressedDiaryImageBase64(
        source,
        maxSide: 900,
        quality: 64,
      );
      if (imageBase64 == null) return;
      _pushHistory();
      final element = DiarySketchImageElement(
        id: const Uuid().v4(),
        imageBase64: imageBase64,
        x: 0.12,
        y: 0.12,
      );
      setState(() {
        pages[pageIndex] = page.copyWith(
          imageElements: [...page.imageElements, element],
        );
        _clearSelection();
        selectedImageIds.add(element.id);
        tool = DiarySketchTool.select;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Immagine non inserita.')),
      );
    }
  }

  void _deleteSelection() {
    if (selectedStrokeIndices.isEmpty &&
        selectedTextIds.isEmpty &&
        selectedImageIds.isEmpty) {
      return;
    }
    _pushHistory();

    final strokes = <DiarySketchStroke>[];
    for (var index = 0; index < page.strokes.length; index++) {
      if (!selectedStrokeIndices.contains(index)) {
        strokes.add(page.strokes[index]);
      }
    }

    _replacePage(
      page.copyWith(
        strokes: strokes,
        textElements: page.textElements
            .where((item) => !selectedTextIds.contains(item.id))
            .toList(),
        imageElements: page.imageElements
            .where((item) => !selectedImageIds.contains(item.id))
            .toList(),
      ),
    );
    setState(_clearSelection);
  }

  void _resizeSelectedImage(double value) {
    if (selectedImageIds.length != 1) return;
    final id = selectedImageIds.first;
    final images = page.imageElements.map((item) {
      if (item.id != id) return item;
      final ratio = item.height / (item.width <= 0 ? 1 : item.width);
      final nextHeight = (value * ratio).clamp(0.08, 0.9);
      return item.copyWith(
        width: value,
        height: nextHeight,
        x: item.x.clamp(0.0, (1.0 - value).clamp(0.0, 1.0)),
        y: item.y.clamp(
          0.0,
          (1.0 - nextHeight).clamp(0.0, 1.0),
        ),
      );
    }).toList();
    setState(() => pages[pageIndex] = page.copyWith(imageElements: images));
  }

  void _resizeSelectedText(double value) {
    if (selectedTextIds.length != 1) return;
    final id = selectedTextIds.first;
    final texts = page.textElements
        .map(
          (item) => item.id == id ? item.copyWith(fontSize: value) : item,
        )
        .toList();
    setState(() {
      textSize = value;
      pages[pageIndex] = page.copyWith(textElements: texts);
    });
  }

  void _addPage() {
    if (pages.length >= 64) return;
    setState(() {
      pages.add(
        DiarySketchPage(
          id: const Uuid().v4(),
          paper: page.paper,
        ),
      );
      pageIndex = pages.length - 1;
      _clearSelection();
      activeStroke = null;
      lassoPoints = const [];
      _transform.value = Matrix4.identity();
    });
  }

  void _duplicatePage() {
    if (pages.length >= 64) return;
    final duplicated = DiarySketchPage(
      id: const Uuid().v4(),
      paper: page.paper,
      strokes: page.strokes
          .map(
            (stroke) => DiarySketchStroke(
              tool: stroke.tool,
              colorValue: stroke.colorValue,
              width: stroke.width,
              points: stroke.points
                  .map((point) => DiarySketchPoint(point.x, point.y))
                  .toList(),
            ),
          )
          .toList(),
      textElements: page.textElements
          .map(
            (element) => DiarySketchTextElement(
              id: const Uuid().v4(),
              text: element.text,
              x: element.x,
              y: element.y,
              fontSize: element.fontSize,
              colorValue: element.colorValue,
            ),
          )
          .toList(),
      imageElements: page.imageElements
          .map(
            (element) => DiarySketchImageElement(
              id: const Uuid().v4(),
              imageBase64: element.imageBase64,
              x: element.x,
              y: element.y,
              width: element.width,
              height: element.height,
            ),
          )
          .toList(),
    );
    setState(() {
      pages.insert(pageIndex + 1, duplicated);
      pageIndex++;
      _clearSelection();
      _transform.value = Matrix4.identity();
    });
  }

  void _deletePage() {
    if (pages.length <= 1) {
      _pushHistory();
      setState(() {
        pages[pageIndex] = DiarySketchPage(
          id: page.id,
          paper: page.paper,
        );
        _clearSelection();
      });
      return;
    }
    setState(() {
      pages.removeAt(pageIndex);
      pageIndex = pageIndex.clamp(0, pages.length - 1);
      _clearSelection();
      activeStroke = null;
      lassoPoints = const [];
      _transform.value = Matrix4.identity();
    });
  }

  Future<void> _exportPng() async {
    final selectedStrokes = {...selectedStrokeIndices};
    final selectedTexts = {...selectedTextIds};
    final selectedImages = {...selectedImageIds};

    setState(_clearSelection);
    await WidgetsBinding.instance.endOfFrame;

    try {
      final boundary = _pageBoundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 2.5);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) return;
      final bytes = data.buffer.asUint8List();

      final path = await FilePicker.saveFile(
        dialogTitle: 'Esporta sketch',
        fileName:
            'annas-diary-sketch-${DateFormat('yyyyMMdd-HHmm').format(DateTime.now())}.png',
        type: FileType.custom,
        allowedExtensions: const ['png'],
        bytes: bytes,
      );

      if (!mounted) return;
      if (path != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sketch esportato in PNG.')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Non è stato possibile esportare lo sketch.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          selectedStrokeIndices
            ..clear()
            ..addAll(selectedStrokes);
          selectedTextIds
            ..clear()
            ..addAll(selectedTexts);
          selectedImageIds
            ..clear()
            ..addAll(selectedImages);
        });
      }
    }
  }

  IconData _toolIcon(DiarySketchTool value) => switch (value) {
        DiarySketchTool.pen => Icons.edit_outlined,
        DiarySketchTool.highlighter => Icons.border_color_outlined,
        DiarySketchTool.eraser => Icons.auto_fix_normal_outlined,
        DiarySketchTool.line => Icons.horizontal_rule,
        DiarySketchTool.rectangle => Icons.crop_square,
        DiarySketchTool.ellipse => Icons.circle_outlined,
        DiarySketchTool.select => Icons.open_with_outlined,
        DiarySketchTool.lasso => Icons.gesture_outlined,
        DiarySketchTool.hand => Icons.pan_tool_alt_outlined,
      };

  String _toolLabel(DiarySketchTool value) => switch (value) {
        DiarySketchTool.pen => 'Penna',
        DiarySketchTool.highlighter => 'Evidenziatore',
        DiarySketchTool.eraser => 'Gomma',
        DiarySketchTool.line => 'Linea',
        DiarySketchTool.rectangle => 'Rettangolo',
        DiarySketchTool.ellipse => 'Ellisse',
        DiarySketchTool.select => 'Seleziona',
        DiarySketchTool.lasso => 'Lazo',
        DiarySketchTool.hand => 'Zoom',
      };

  String _paperLabel(DiarySketchPaper value) => switch (value) {
        DiarySketchPaper.plain => 'Bianco',
        DiarySketchPaper.ruled => 'Righe',
        DiarySketchPaper.grid => 'Quadretti',
        DiarySketchPaper.dots => 'Puntini',
      };

  Widget _canvas(Size size) {
    final currentPage = page;
    return RepaintBoundary(
      key: _pageBoundaryKey,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: DiarySketchPainter(
              page: currentPage,
              activeStroke: activeStroke,
              selectedStrokeIndices: Set<int>.of(selectedStrokeIndices),
              lassoPoints: List<DiarySketchPoint>.of(lassoPoints),
            ),
            child: const SizedBox.expand(),
          ),
          ...currentPage.imageElements.map(
            (element) {
              final selected = selectedImageIds.contains(element.id);
              return Positioned(
                left: element.x * size.width,
                top: element.y * size.height,
                width: element.width * size.width,
                height: element.height * size.height,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: selected
                        ? Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2.5,
                          )
                        : null,
                  ),
                  child: Image.memory(
                    base64Decode(element.imageBase64),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const ColoredBox(
                      color: Color(0xFFF0F0F0),
                      child: Center(
                        child: Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          ...currentPage.textElements.map(
            (element) {
              final selected = selectedTextIds.contains(element.id);
              return Positioned(
                left: element.x * size.width,
                top: element.y * size.height,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: selected
                        ? Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 1.5,
                          )
                        : null,
                    color: selected
                        ? Colors.white.withValues(alpha: 0.5)
                        : null,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Text(
                      element.text,
                      style: TextStyle(
                        color: Color(element.colorValue),
                        fontSize: element.fontSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _selectionControls() {
    DiarySketchImageElement? image;
    if (selectedImageIds.length == 1) {
      final id = selectedImageIds.first;
      for (final item in page.imageElements) {
        if (item.id == id) {
          image = item;
          break;
        }
      }
    }

    DiarySketchTextElement? textElement;
    if (selectedTextIds.length == 1) {
      final id = selectedTextIds.first;
      for (final item in page.textElements) {
        if (item.id == id) {
          textElement = item;
          break;
        }
      }
    }

    if (image == null && textElement == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      child: Row(
        children: [
          Icon(
            image != null ? Icons.photo_size_select_large : Icons.text_fields,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(image != null ? 'Dimensione immagine' : 'Dimensione testo'),
          Expanded(
            child: Slider(
              min: image != null ? 0.15 : 12,
              max: image != null ? 0.9 : 48,
              value: image != null
                  ? image.width.clamp(0.15, 0.9)
                  : textElement!.fontSize.clamp(12, 48),
              onChanged:
                  image != null ? _resizeSelectedImage : _resizeSelectedText,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final undoAvailable = (_undo[page.id] ?? const []).isNotEmpty;
    final redoAvailable = (_redo[page.id] ?? const []).isNotEmpty;
    final hasSelection = selectedStrokeIndices.isNotEmpty ||
        selectedTextIds.isNotEmpty ||
        selectedImageIds.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sketchbook',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'Esporta PNG',
            onPressed: _exportPng,
            icon: const Icon(Icons.ios_share_outlined),
          ),
          IconButton(
            tooltip: 'Salva sketch',
            onPressed: () => Navigator.pop(context, pages),
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 58,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                scrollDirection: Axis.horizontal,
                children: DiarySketchTool.values.map((value) {
                  final selected = tool == value;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      selected: selected,
                      avatar: Icon(_toolIcon(value), size: 18),
                      label: Text(_toolLabel(value)),
                      onSelected: (_) => setState(() {
                        tool = value;
                        activeStroke = null;
                        lassoPoints = const [];
                      }),
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(
              height: 48,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                scrollDirection: Axis.horizontal,
                children: [
                  IconButton(
                    tooltip: 'Annulla',
                    onPressed: undoAvailable ? _undoAction : null,
                    icon: const Icon(Icons.undo),
                  ),
                  IconButton(
                    tooltip: 'Ripeti',
                    onPressed: redoAvailable ? _redoAction : null,
                    icon: const Icon(Icons.redo),
                  ),
                  IconButton(
                    tooltip: 'Testo',
                    onPressed: _addText,
                    icon: const Icon(Icons.text_fields_outlined),
                  ),
                  IconButton(
                    tooltip: 'Inserisci immagine',
                    onPressed: _addImage,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                  ),
                  IconButton(
                    tooltip: 'Elimina selezione',
                    onPressed: hasSelection ? _deleteSelection : null,
                    icon: const Icon(Icons.delete_sweep_outlined),
                  ),
                  const SizedBox(width: 4),
                  PopupMenuButton<DiarySketchPaper>(
                    tooltip: 'Carta',
                    initialValue: page.paper,
                    onSelected: (paper) {
                      _replacePage(
                        page.copyWith(paper: paper),
                        history: true,
                      );
                    },
                    itemBuilder: (_) => DiarySketchPaper.values
                        .map(
                          (paper) => PopupMenuItem(
                            value: paper,
                            child: Text(_paperLabel(paper)),
                          ),
                        )
                        .toList(),
                    child: Chip(
                      avatar:
                          const Icon(Icons.grid_4x4_outlined, size: 17),
                      label: Text(_paperLabel(page.paper)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Center(
                    child: Text(
                      '${pageIndex + 1}/${pages.length}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Pagina precedente',
                    onPressed: pageIndex == 0
                        ? null
                        : () => setState(() {
                              pageIndex--;
                              _clearSelection();
                              activeStroke = null;
                              lassoPoints = const [];
                              _transform.value = Matrix4.identity();
                            }),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  IconButton(
                    tooltip: 'Pagina successiva',
                    onPressed: pageIndex >= pages.length - 1
                        ? null
                        : () => setState(() {
                              pageIndex++;
                              _clearSelection();
                              activeStroke = null;
                              lassoPoints = const [];
                              _transform.value = Matrix4.identity();
                            }),
                    icon: const Icon(Icons.chevron_right),
                  ),
                  IconButton(
                    tooltip: 'Nuova pagina',
                    onPressed: pages.length >= 64 ? null : _addPage,
                    icon: const Icon(Icons.add_box_outlined),
                  ),
                  IconButton(
                    tooltip: 'Duplica pagina',
                    onPressed:
                        pages.length >= 64 ? null : _duplicatePage,
                    icon: const Icon(Icons.copy_all_outlined),
                  ),
                  IconButton(
                    tooltip: 'Elimina pagina',
                    onPressed: _deletePage,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ),
            if (tool != DiarySketchTool.select &&
                tool != DiarySketchTool.lasso &&
                tool != DiarySketchTool.hand)
              SizedBox(
                height: 42,
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    ..._colors.map(
                      (value) => Padding(
                        padding: const EdgeInsets.only(right: 7),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () =>
                              setState(() => colorValue = value),
                          child: Container(
                            width: 27,
                            height: 27,
                            decoration: BoxDecoration(
                              color: Color(value),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colorValue == value
                                    ? Theme.of(context)
                                        .colorScheme
                                        .primary
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.line_weight, size: 18),
                    Expanded(
                      child: Slider(
                        value: width.clamp(1, 14),
                        min: 1,
                        max: 14,
                        onChanged: (value) =>
                            setState(() => width = value),
                      ),
                    ),
                  ],
                ),
              ),
            _selectionControls(),
            if (tool == DiarySketchTool.hand)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
                child: Row(
                  children: [
                    const Icon(Icons.pinch_outlined, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Trascina e usa due dita per zoomare. Torna a Penna o Seleziona per modificare.',
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        _transform.value = Matrix4.identity();
                      },
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 3 / 4,
                    child: Material(
                      elevation: 2,
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      clipBehavior: Clip.antiAlias,
                      child: InteractiveViewer(
                        transformationController: _transform,
                        minScale: 0.75,
                        maxScale: 5,
                        panEnabled: tool == DiarySketchTool.hand,
                        scaleEnabled: tool == DiarySketchTool.hand,
                        constrained: true,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final size = Size(
                              constraints.maxWidth,
                              constraints.maxHeight,
                            );
                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTapDown: tool == DiarySketchTool.select
                                  ? (details) => setState(
                                        () => _selectAt(
                                          _point(
                                            details.localPosition,
                                            size,
                                          ),
                                        ),
                                      )
                                  : null,
                              onPanStart: tool == DiarySketchTool.hand
                                  ? null
                                  : (details) => _start(details, size),
                              onPanUpdate: tool == DiarySketchTool.hand
                                  ? null
                                  : (details) => _update(details, size),
                              onPanEnd: tool == DiarySketchTool.hand
                                  ? null
                                  : _end,
                              child: _canvas(size),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DiarySketchPagePreview extends StatelessWidget {
  final DiarySketchPage page;

  const DiarySketchPagePreview({
    super.key,
    required this.page,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(
          constraints.maxWidth,
          constraints.maxHeight,
        );
        return ColoredBox(
          color: Colors.white,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: DiarySketchPainter(page: page),
                child: const SizedBox.expand(),
              ),
              ...page.imageElements.map(
                (element) => Positioned(
                  left: element.x * size.width,
                  top: element.y * size.height,
                  width: element.width * size.width,
                  height: element.height * size.height,
                  child: Image.memory(
                    base64Decode(element.imageBase64),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
              ...page.textElements.map(
                (element) => Positioned(
                  left: element.x * size.width,
                  top: element.y * size.height,
                  child: Text(
                    element.text,
                    style: TextStyle(
                      color: Color(element.colorValue),
                      fontSize: element.fontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class DiarySketchPainter extends CustomPainter {
  final DiarySketchPage page;
  final DiarySketchStroke? activeStroke;
  final Set<int> selectedStrokeIndices;
  final List<DiarySketchPoint> lassoPoints;

  const DiarySketchPainter({
    required this.page,
    this.activeStroke,
    this.selectedStrokeIndices = const {},
    this.lassoPoints = const [],
  });

  Offset _offset(DiarySketchPoint point, Size size) =>
      Offset(point.x * size.width, point.y * size.height);

  void _paintPaper(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    final guide = Paint()
      ..color = const Color(0xFFD8DFEA).withValues(alpha: 0.55)
      ..strokeWidth = 1;

    switch (page.paper) {
      case DiarySketchPaper.plain:
        break;
      case DiarySketchPaper.ruled:
        for (double y = 28; y < size.height; y += 28) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), guide);
        }
      case DiarySketchPaper.grid:
        for (double y = 24; y < size.height; y += 24) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), guide);
        }
        for (double x = 24; x < size.width; x += 24) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), guide);
        }
      case DiarySketchPaper.dots:
        for (double y = 20; y < size.height; y += 20) {
          for (double x = 20; x < size.width; x += 20) {
            canvas.drawCircle(Offset(x, y), 1.2, guide);
          }
        }
    }
  }

  void _drawStroke(
    Canvas canvas,
    Size size,
    DiarySketchStroke stroke, {
    bool selected = false,
  }) {
    if (stroke.points.isEmpty) return;
    final color = Color(stroke.colorValue);
    final baseWidth = stroke.tool == DiarySketchTool.eraser
        ? stroke.width * 2.8
        : stroke.width;

    if (selected && stroke.tool != DiarySketchTool.eraser) {
      final highlight = Paint()
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..strokeWidth = baseWidth + 5
        ..color = const Color(0xFF7C6FE3).withValues(alpha: 0.28);
      _drawStrokeWithPaint(canvas, size, stroke, highlight);
    }

    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = baseWidth
      ..color = stroke.tool == DiarySketchTool.highlighter
          ? color.withValues(alpha: 0.28)
          : color;

    if (stroke.tool == DiarySketchTool.eraser) {
      paint.blendMode = BlendMode.clear;
    }
    _drawStrokeWithPaint(canvas, size, stroke, paint);
  }

  void _drawStrokeWithPaint(
    Canvas canvas,
    Size size,
    DiarySketchStroke stroke,
    Paint paint,
  ) {
    if (stroke.tool == DiarySketchTool.line ||
        stroke.tool == DiarySketchTool.rectangle ||
        stroke.tool == DiarySketchTool.ellipse) {
      if (stroke.points.length < 2) return;
      final first = _offset(stroke.points.first, size);
      final last = _offset(stroke.points.last, size);
      if (stroke.tool == DiarySketchTool.line) {
        canvas.drawLine(first, last, paint);
      } else {
        final rect = Rect.fromPoints(first, last);
        if (stroke.tool == DiarySketchTool.rectangle) {
          canvas.drawRect(rect, paint);
        } else {
          canvas.drawOval(rect, paint);
        }
      }
      return;
    }

    if (stroke.points.length == 1) {
      final p = _offset(stroke.points.first, size);
      canvas.drawCircle(
        p,
        paint.strokeWidth / 2,
        paint..style = PaintingStyle.fill,
      );
      return;
    }

    final path = Path();
    final first = _offset(stroke.points.first, size);
    path.moveTo(first.dx, first.dy);
    for (final point in stroke.points.skip(1)) {
      final p = _offset(point, size);
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    _paintPaper(canvas, size);
    canvas.saveLayer(Offset.zero & size, Paint());
    for (var index = 0; index < page.strokes.length; index++) {
      _drawStroke(
        canvas,
        size,
        page.strokes[index],
        selected: selectedStrokeIndices.contains(index),
      );
    }
    if (activeStroke != null) {
      _drawStroke(canvas, size, activeStroke!);
    }

    if (lassoPoints.length > 1) {
      final lassoPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF7C6FE3);
      final path = Path();
      final first = _offset(lassoPoints.first, size);
      path.moveTo(first.dx, first.dy);
      for (final point in lassoPoints.skip(1)) {
        final p = _offset(point, size);
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, lassoPaint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant DiarySketchPainter oldDelegate) {
    return oldDelegate.page != page ||
        oldDelegate.activeStroke != activeStroke ||
        !setEquals(
          oldDelegate.selectedStrokeIndices,
          selectedStrokeIndices,
        ) ||
        !listEquals(oldDelegate.lassoPoints, lassoPoints);
  }
}
