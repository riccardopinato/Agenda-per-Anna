part of '../../main.dart';

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
    final imageFuture = _readDiaryMediaBytes(
      assetId: block.mediaAssetId,
      fallbackBase64: block.imageBase64,
    );

    final actionStyle = OutlinedButton.styleFrom(
      foregroundColor: Colors.white,
      side: const BorderSide(color: Colors.white38),
    );

    return DiaryPhotoViewerShell(
      title: dateLabel,
      image: FutureBuilder<Uint8List?>(
        future: imageFuture,
        builder: (context, snapshot) => DiaryZoomableImage(
          bytes: snapshot.data,
          loading: snapshot.connectionState != ConnectionState.done,
        ),
      ),
      caption: block.text,
      appBarActions: [
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
      actions: [
        OutlinedButton.icon(
          style: actionStyle,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MonthScreen(
                store: store,
                initialMonth: DateTime(date.year, date.month),
              ),
            ),
          ),
          icon: const Icon(Icons.calendar_month_outlined),
          label: const Text('Mese'),
        ),
        OutlinedButton.icon(
          style: actionStyle,
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
      ],
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
  final List<DiarySketchPoint> _activeStrokePoints = <DiarySketchPoint>[];
  final List<DiarySketchPoint> lassoPoints = <DiarySketchPoint>[];
  int _gestureRevision = 0;

  List<DiarySketchStroke>? _selectionWorkingStrokes;
  List<DiarySketchTextElement>? _selectionWorkingText;
  List<DiarySketchImageElement>? _selectionWorkingImages;
  Set<int> _selectionTextIndices = <int>{};
  Set<int> _selectionImageIndices = <int>{};

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
                mediaAssetId: element.mediaAssetId,
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

  DiarySketchPage _historySnapshot(DiarySketchPage source) =>
      DiarySketchPage(
        id: source.id,
        paper: source.paper,
        strokes: List<DiarySketchStroke>.unmodifiable(source.strokes),
        textElements:
            List<DiarySketchTextElement>.unmodifiable(source.textElements),
        imageElements:
            List<DiarySketchImageElement>.unmodifiable(source.imageElements),
      );

  int _historyLimit(DiarySketchPage source) {
    var pointCount = 0;
    for (final stroke in source.strokes) {
      pointCount += stroke.points.length;
    }
    if (pointCount > 5000) return 12;
    if (pointCount > 1500) return 20;
    return 32;
  }

  void _pushHistory() {
    final stack = _undo.putIfAbsent(page.id, () => []);
    stack.add(_historySnapshot(page));
    final limit = _historyLimit(page);
    if (stack.length > limit) {
      stack.removeRange(0, stack.length - limit);
    }
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
    _redo.putIfAbsent(page.id, () => []).add(_historySnapshot(page));
    setState(() {
      pages[pageIndex] = previous;
      _clearSelection();
      activeStroke = null;
      _activeStrokePoints.clear();
      lassoPoints.clear();
      _gestureRevision++;
    });
  }

  void _redoAction() {
    final stack = _redo[page.id];
    if (stack == null || stack.isEmpty) return;
    final next = stack.removeLast();
    _undo.putIfAbsent(page.id, () => []).add(_historySnapshot(page));
    setState(() {
      pages[pageIndex] = next;
      _clearSelection();
      activeStroke = null;
      _activeStrokePoints.clear();
      lassoPoints.clear();
      _gestureRevision++;
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

  bool _appendSampledPoint(
    List<DiarySketchPoint> buffer,
    DiarySketchPoint point,
    Size size, {
    double minPixels = 1.8,
  }) {
    if (buffer.isEmpty) {
      buffer.add(point);
      return true;
    }
    final last = buffer.last;
    final dx = (point.x - last.x) * (size.width <= 0 ? 1 : size.width);
    final dy = (point.y - last.y) * (size.height <= 0 ? 1 : size.height);
    if (dx * dx + dy * dy < minPixels * minPixels) return false;
    buffer.add(point);
    return true;
  }

  void _resetGesturePreview() {
    activeStroke = null;
    _activeStrokePoints.clear();
    lassoPoints.clear();
    _gestureRevision++;
  }

  void _prepareSelectionMove() {
    _selectionWorkingStrokes = List<DiarySketchStroke>.of(page.strokes);
    _selectionWorkingText =
        List<DiarySketchTextElement>.of(page.textElements);
    _selectionWorkingImages =
        List<DiarySketchImageElement>.of(page.imageElements);

    _selectionTextIndices = {
      for (var i = 0; i < page.textElements.length; i++)
        if (selectedTextIds.contains(page.textElements[i].id)) i,
    };
    _selectionImageIndices = {
      for (var i = 0; i < page.imageElements.length; i++)
        if (selectedImageIds.contains(page.imageElements[i].id)) i,
    };
  }

  void _clearSelectionMoveBuffers() {
    _selectionWorkingStrokes = null;
    _selectionWorkingText = null;
    _selectionWorkingImages = null;
    _selectionTextIndices = <int>{};
    _selectionImageIndices = <int>{};
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
        if (_selectionMoveStarted) {
          _pushHistory();
          _prepareSelectionMove();
        }
      });
      return;
    }

    if (tool == DiarySketchTool.lasso) {
      setState(() {
        activeStroke = null;
        _activeStrokePoints.clear();
        lassoPoints
          ..clear()
          ..add(p);
        _gestureRevision++;
      });
      return;
    }

    setState(() {
      lassoPoints.clear();
      _activeStrokePoints
        ..clear()
        ..add(p);
      activeStroke = DiarySketchStroke(
        tool: tool,
        colorValue: colorValue,
        width: width,
        points: _activeStrokePoints,
      );
      _gestureRevision++;
    });
  }

  void _moveSelection(Offset delta, Size size) {
    final dx = delta.dx / (size.width <= 0 ? 1 : size.width);
    final dy = delta.dy / (size.height <= 0 ? 1 : size.height);
    if (dx == 0 && dy == 0) return;

    final strokes = _selectionWorkingStrokes;
    final texts = _selectionWorkingText;
    final images = _selectionWorkingImages;
    if (strokes == null || texts == null || images == null) return;

    for (final index in selectedStrokeIndices) {
      if (index < 0 || index >= strokes.length) continue;
      final stroke = strokes[index];
      strokes[index] = stroke.copyWith(
        points: stroke.points
            .map(
              (point) => DiarySketchPoint(
                (point.x + dx).clamp(0.0, 1.0),
                (point.y + dy).clamp(0.0, 1.0),
              ),
            )
            .toList(growable: false),
      );
    }

    for (final index in _selectionTextIndices) {
      if (index < 0 || index >= texts.length) continue;
      final element = texts[index];
      texts[index] = element.copyWith(
        x: (element.x + dx).clamp(0.0, 0.96),
        y: (element.y + dy).clamp(0.0, 0.96),
      );
    }

    for (final index in _selectionImageIndices) {
      if (index < 0 || index >= images.length) continue;
      final element = images[index];
      images[index] = element.copyWith(
        x: (element.x + dx).clamp(
          0.0,
          (1.0 - element.width).clamp(0.0, 1.0),
        ),
        y: (element.y + dy).clamp(
          0.0,
          (1.0 - element.height).clamp(0.0, 1.0),
        ),
      );
    }

    setState(() {
      pages[pageIndex] = DiarySketchPage(
        id: page.id,
        paper: page.paper,
        strokes: strokes,
        textElements: texts,
        imageElements: images,
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
      if (!_appendSampledPoint(
        lassoPoints,
        p,
        size,
        minPixels: 3,
      )) {
        return;
      }
      setState(() => _gestureRevision++);
      return;
    }

    final current = activeStroke;
    if (current == null) return;

    if (current.tool == DiarySketchTool.line ||
        current.tool == DiarySketchTool.rectangle ||
        current.tool == DiarySketchTool.ellipse) {
      if (_activeStrokePoints.length == 1) {
        _activeStrokePoints.add(p);
      } else {
        _activeStrokePoints[1] = p;
      }
      setState(() => _gestureRevision++);
      return;
    }

    final minPixels = current.tool == DiarySketchTool.highlighter ||
            current.tool == DiarySketchTool.eraser
        ? 2.4
        : 1.8;
    if (!_appendSampledPoint(
      _activeStrokePoints,
      p,
      size,
      minPixels: minPixels,
    )) {
      return;
    }
    setState(() => _gestureRevision++);
  }

  void _finishLasso() {
    final polygon = List<DiarySketchPoint>.of(lassoPoints);
    if (polygon.length < 3) {
      setState(() {
        lassoPoints.clear();
        _gestureRevision++;
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
      lassoPoints.clear();
      _gestureRevision++;
      tool = DiarySketchTool.select;
    });
  }

  void _end(DragEndDetails details) {
    if (tool == DiarySketchTool.hand) return;

    if (tool == DiarySketchTool.select) {
      _selectionMoveStarted = false;
      _clearSelectionMoveBuffers();
      return;
    }

    if (tool == DiarySketchTool.lasso) {
      _finishLasso();
      return;
    }

    final stroke = activeStroke;
    if (stroke == null || _activeStrokePoints.isEmpty) return;

    final frozenStroke = DiarySketchStroke(
      tool: stroke.tool,
      colorValue: stroke.colorValue,
      width: stroke.width,
      points: List<DiarySketchPoint>.unmodifiable(
        _activeStrokePoints.map(
          (point) => DiarySketchPoint(point.x, point.y),
        ),
      ),
    );

    _pushHistory();
    setState(() {
      pages[pageIndex] = page.copyWith(
        strokes: [...page.strokes, frozenStroke],
      );
      _resetGesturePreview();
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
      final imageBytes = await _pickCompressedDiaryImageBytes(
        source,
        maxSide: 1280,
        quality: 80,
        fallbackMaxSide: 1100,
        fallbackQuality: 74,
      );
      if (imageBytes == null) return;
      final mediaAssetId = await MediaAssetStore.instance.put(imageBytes);
      _pushHistory();
      final element = DiarySketchImageElement(
        id: const Uuid().v4(),
        mediaAssetId: mediaAssetId,
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
      _activeStrokePoints.clear();
      lassoPoints.clear();
      _gestureRevision++;
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
              mediaAssetId: element.mediaAssetId,
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
      _activeStrokePoints.clear();
      lassoPoints.clear();
      _gestureRevision++;
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
              lassoPoints: lassoPoints,
              gestureRevision: _gestureRevision,
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
                  child: DiaryMediaImage(
                    assetId: element.mediaAssetId,
                    fallbackBase64: element.imageBase64,
                    fit: BoxFit.cover,
                    empty: const ColoredBox(
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
                        _resetGesturePreview();
                        _clearSelectionMoveBuffers();
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
                              _resetGesturePreview();
                              _clearSelectionMoveBuffers();
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
                              _resetGesturePreview();
                              _clearSelectionMoveBuffers();
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
                  child: DiaryMediaImage(
                    assetId: element.mediaAssetId,
                    fallbackBase64: element.imageBase64,
                    fit: BoxFit.cover,
                    empty: const SizedBox.shrink(),
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
  final int gestureRevision;

  const DiarySketchPainter({
    required this.page,
    this.activeStroke,
    this.selectedStrokeIndices = const {},
    this.lassoPoints = const [],
    this.gestureRevision = 0,
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
        oldDelegate.gestureRevision != gestureRevision ||
        !setEquals(
          oldDelegate.selectedStrokeIndices,
          selectedStrokeIndices,
        ) ||
        !listEquals(oldDelegate.lassoPoints, lassoPoints);
  }
}
