part of '../main.dart';

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
            hintText: 'Scrivi un ricordo, un pensiero, qualcosa da non dimenticare...',
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
    setState(() => photoBusy = true);
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        requestFullMetadata: false,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      var compressed = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: 1080,
        minHeight: 1080,
        quality: 72,
        format: CompressFormat.jpeg,
      );
      if (compressed.lengthInBytes > 450 * 1024) {
        compressed = await FlutterImageCompress.compressWithList(
          bytes,
          minWidth: 800,
          minHeight: 800,
          quality: 62,
          format: CompressFormat.jpeg,
        );
      }

      if (!mounted) return;
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
          imageBase64: base64Encode(compressed),
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
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                child: Image.memory(
                  base64Decode(block.imageBase64),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox(
                    height: 220,
                    child: Center(child: Icon(Icons.broken_image_outlined)),
                  ),
                ),
              ),
              if (block.text.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(block.text),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _blockCard(BuildContext context, DiaryBlock block) {
    final time = DateFormat('HH:mm', 'it_IT').format(block.createdAt);

    switch (block.type) {
      case DiaryBlockType.note:
        return Card(
          margin: const EdgeInsets.only(bottom: 9),
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.sticky_note_2_outlined),
            ),
            title: Text(
              block.text,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text('Nota · $time'),
            onTap: () => _addNote(block),
            trailing: IconButton(
              tooltip: 'Elimina',
              onPressed: () => _delete(block),
              icon: const Icon(Icons.delete_outline),
            ),
          ),
        );
      case DiaryBlockType.photo:
        return Card(
          margin: const EdgeInsets.only(bottom: 9),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _openPhoto(block),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (block.imageBase64.isNotEmpty)
                  AspectRatio(
                    aspectRatio: 16 / 10,
                    child: Image.memory(
                      base64Decode(block.imageBase64),
                      fit: BoxFit.cover,
                      cacheWidth: 720,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 6, 8),
                  child: Row(
                    children: [
                      const Icon(Icons.photo_outlined, size: 19),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          block.text.trim().isEmpty
                              ? 'Foto del giorno · $time'
                              : block.text,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Elimina',
                        onPressed: () => _delete(block),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      case DiaryBlockType.sketch:
        final page = block.pages.isEmpty
            ? DiarySketchPage(id: block.id)
            : block.pages.first;
        return Card(
          margin: const EdgeInsets.only(bottom: 9),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _openSketch(block),
            child: Column(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: ColoredBox(
                    color: Colors.white,
                    child: CustomPaint(
                      painter: DiarySketchPainter(page: page),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.draw_outlined),
                  ),
                  title: Text(
                    block.pages.length <= 1
                        ? 'Sketch'
                        : 'Sketch · ${block.pages.length} pagine',
                  ),
                  subtitle: Text(time),
                  trailing: IconButton(
                    tooltip: 'Elimina',
                    onPressed: () => _delete(block),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final blocks = _blocks;

    return SimpleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Il mio diario',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            'Note, sketch e foto restano personali. Le foto vengono compresse prima di essere salvate.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: () => _addNote(),
                icon: const Icon(Icons.sticky_note_2_outlined),
                label: const Text('Nota'),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _openSketch(),
                icon: const Icon(Icons.draw_outlined),
                label: const Text('Sketch'),
              ),
              FilledButton.tonalIcon(
                onPressed: photoBusy ? null : _addPhoto,
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
          if (blocks.isEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'Qui puoi costruire la giornata come una pagina di diario, un ricordo alla volta.',
            ),
          ] else ...[
            const SizedBox(height: 14),
            ...blocks.map((block) => _blockCard(context, block)),
          ],
        ],
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
  State<DiarySketchbookScreen> createState() => _DiarySketchbookScreenState();
}

class _DiarySketchbookScreenState extends State<DiarySketchbookScreen> {
  late List<DiarySketchPage> pages;
  int pageIndex = 0;
  DiarySketchTool tool = DiarySketchTool.pen;
  int colorValue = 0xFF222222;
  double width = 3;
  DiarySketchStroke? activeStroke;
  final Map<String, List<DiarySketchStroke>> _redo = {};

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
    pages = widget.initialPages
        .map(
          (page) => DiarySketchPage(
            id: page.id,
            paper: page.paper,
            strokes: [...page.strokes],
          ),
        )
        .toList();
    if (pages.isEmpty) {
      pages = [DiarySketchPage(id: const Uuid().v4())];
    }
  }

  DiarySketchPage get page => pages[pageIndex];

  void _replacePage(DiarySketchPage value) {
    setState(() => pages[pageIndex] = value);
  }

  DiarySketchPoint _point(Offset local, Size size) {
    final canvasWidth = size.width <= 0 ? 1.0 : size.width;
    final canvasHeight = size.height <= 0 ? 1.0 : size.height;
    return DiarySketchPoint(
      (local.dx / canvasWidth).clamp(0.0, 1.0),
      (local.dy / canvasHeight).clamp(0.0, 1.0),
    );
  }

  void _start(DragStartDetails details, Size size) {
    final p = _point(details.localPosition, size);
    setState(() {
      activeStroke = DiarySketchStroke(
        tool: tool,
        colorValue: colorValue,
        width: width,
        points: [p],
      );
    });
  }

  void _update(DragUpdateDetails details, Size size) {
    final current = activeStroke;
    if (current == null) return;
    final p = _point(details.localPosition, size);
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

  void _end(DragEndDetails details) {
    final stroke = activeStroke;
    if (stroke == null || stroke.points.isEmpty) return;
    final next = [...page.strokes, stroke];
    _redo[page.id] = [];
    setState(() {
      pages[pageIndex] = page.copyWith(strokes: next);
      activeStroke = null;
    });
  }

  void _undo() {
    if (page.strokes.isEmpty) return;
    final next = [...page.strokes];
    final removed = next.removeLast();
    _redo.putIfAbsent(page.id, () => []).add(removed);
    _replacePage(page.copyWith(strokes: next));
  }

  void _redoStroke() {
    final stack = _redo[page.id];
    if (stack == null || stack.isEmpty) return;
    final stroke = stack.removeLast();
    _replacePage(page.copyWith(strokes: [...page.strokes, stroke]));
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
      activeStroke = null;
    });
  }

  void _deletePage() {
    if (pages.length <= 1) {
      _replacePage(page.copyWith(strokes: const []));
      _redo[page.id] = [];
      return;
    }
    setState(() {
      pages.removeAt(pageIndex);
      pageIndex = pageIndex.clamp(0, pages.length - 1);
      activeStroke = null;
    });
  }

  IconData _toolIcon(DiarySketchTool value) => switch (value) {
        DiarySketchTool.pen => Icons.edit_outlined,
        DiarySketchTool.highlighter => Icons.border_color_outlined,
        DiarySketchTool.eraser => Icons.auto_fix_normal_outlined,
        DiarySketchTool.line => Icons.horizontal_rule,
        DiarySketchTool.rectangle => Icons.crop_square,
        DiarySketchTool.ellipse => Icons.circle_outlined,
      };

  String _toolLabel(DiarySketchTool value) => switch (value) {
        DiarySketchTool.pen => 'Penna',
        DiarySketchTool.highlighter => 'Evidenziatore',
        DiarySketchTool.eraser => 'Gomma',
        DiarySketchTool.line => 'Linea',
        DiarySketchTool.rectangle => 'Rettangolo',
        DiarySketchTool.ellipse => 'Ellisse',
      };

  String _paperLabel(DiarySketchPaper value) => switch (value) {
        DiarySketchPaper.plain => 'Bianco',
        DiarySketchPaper.ruled => 'Righe',
        DiarySketchPaper.grid => 'Quadretti',
        DiarySketchPaper.dots => 'Puntini',
      };

  @override
  Widget build(BuildContext context) {
    final redoAvailable = (_redo[page.id] ?? const []).isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sketchbook',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
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
                      onSelected: (_) => setState(() => tool = value),
                    ),
                  );
                }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Annulla tratto',
                    onPressed: page.strokes.isEmpty ? null : _undo,
                    icon: const Icon(Icons.undo),
                  ),
                  IconButton(
                    tooltip: 'Ripeti tratto',
                    onPressed: redoAvailable ? _redoStroke : null,
                    icon: const Icon(Icons.redo),
                  ),
                  const SizedBox(width: 6),
                  PopupMenuButton<DiarySketchPaper>(
                    tooltip: 'Carta',
                    initialValue: page.paper,
                    onSelected: (paper) =>
                        _replacePage(page.copyWith(paper: paper)),
                    itemBuilder: (_) => DiarySketchPaper.values
                        .map(
                          (paper) => PopupMenuItem(
                            value: paper,
                            child: Text(_paperLabel(paper)),
                          ),
                        )
                        .toList(),
                    child: Chip(
                      avatar: const Icon(Icons.grid_4x4_outlined, size: 17),
                      label: Text(_paperLabel(page.paper)),
                    ),
                  ),
                  const Spacer(),
                  Text('${pageIndex + 1}/${pages.length}'),
                  IconButton(
                    tooltip: 'Pagina precedente',
                    onPressed: pageIndex == 0
                        ? null
                        : () => setState(() {
                              pageIndex--;
                              activeStroke = null;
                            }),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  IconButton(
                    tooltip: 'Pagina successiva',
                    onPressed: pageIndex >= pages.length - 1
                        ? null
                        : () => setState(() {
                              pageIndex++;
                              activeStroke = null;
                            }),
                    icon: const Icon(Icons.chevron_right),
                  ),
                  IconButton(
                    tooltip: 'Nuova pagina',
                    onPressed: pages.length >= 64 ? null : _addPage,
                    icon: const Icon(Icons.add_box_outlined),
                  ),
                  IconButton(
                    tooltip: 'Elimina pagina',
                    onPressed: _deletePage,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ),
            if (tool != DiarySketchTool.eraser)
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
                          onTap: () => setState(() => colorValue = value),
                          child: Container(
                            width: 27,
                            height: 27,
                            decoration: BoxDecoration(
                              color: Color(value),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colorValue == value
                                    ? Theme.of(context).colorScheme.primary
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
                        onChanged: (value) => setState(() => width = value),
                      ),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    const Icon(Icons.auto_fix_normal_outlined, size: 18),
                    const SizedBox(width: 8),
                    const Text('Dimensione gomma'),
                    Expanded(
                      child: Slider(
                        value: width.clamp(2, 14),
                        min: 2,
                        max: 14,
                        onChanged: (value) => setState(() => width = value),
                      ),
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
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final size = Size(
                            constraints.maxWidth,
                            constraints.maxHeight,
                          );
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onPanStart: (details) => _start(details, size),
                            onPanUpdate: (details) => _update(details, size),
                            onPanEnd: _end,
                            child: CustomPaint(
                              painter: DiarySketchPainter(
                                page: page,
                                activeStroke: activeStroke,
                              ),
                              child: const SizedBox.expand(),
                            ),
                          );
                        },
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

class DiarySketchPainter extends CustomPainter {
  final DiarySketchPage page;
  final DiarySketchStroke? activeStroke;

  const DiarySketchPainter({
    required this.page,
    this.activeStroke,
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

  void _drawStroke(Canvas canvas, Size size, DiarySketchStroke stroke) {
    if (stroke.points.isEmpty) return;
    final color = Color(stroke.colorValue);
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke.tool == DiarySketchTool.eraser
          ? stroke.width * 2.8
          : stroke.width
      ..color = stroke.tool == DiarySketchTool.highlighter
          ? color.withValues(alpha: 0.28)
          : color;

    if (stroke.tool == DiarySketchTool.eraser) {
      paint.blendMode = BlendMode.clear;
    }

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
    for (final stroke in page.strokes) {
      _drawStroke(canvas, size, stroke);
    }
    if (activeStroke != null) {
      _drawStroke(canvas, size, activeStroke!);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant DiarySketchPainter oldDelegate) =>
      oldDelegate.page != page || oldDelegate.activeStroke != activeStroke;
}
