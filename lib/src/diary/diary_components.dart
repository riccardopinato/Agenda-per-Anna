part of '../../main.dart';

Future<Uint8List?> _pickCompressedDiaryImageBytes(
  ImageSource source, {
  int maxSide = 1600,
  int quality = 82,
  int fallbackMaxSide = 1280,
  int fallbackQuality = 76,
  int maxEncodedBytes = 2 * 1024 * 1024,
}) async {
  final picked = await ImagePicker().pickImage(
    source: source,
    requestFullMetadata: false,
  );
  if (picked == null) return null;

  final bytes = await picked.readAsBytes();
  if (bytes.isEmpty) return null;

  try {
    final compressed = await FlutterImageCompress.compressWithList(
      bytes,
      minWidth: maxSide,
      minHeight: maxSide,
      quality: quality,
      format: CompressFormat.jpeg,
    );
    if (compressed.isEmpty) return Uint8List.fromList(bytes);
    if (compressed.lengthInBytes <= maxEncodedBytes) return compressed;

    final fallback = await FlutterImageCompress.compressWithList(
      bytes,
      minWidth: fallbackMaxSide,
      minHeight: fallbackMaxSide,
      quality: fallbackQuality,
      format: CompressFormat.jpeg,
    );
    return fallback.isEmpty ? compressed : fallback;
  } catch (_) {
    // Never destroy a selected memory just because native compression failed.
    return Uint8List.fromList(bytes);
  }
}

Future<Uint8List> _diaryThumbnailBytes(Uint8List bytes) async {
  try {
    final thumbnail = await FlutterImageCompress.compressWithList(
      bytes,
      minWidth: 420,
      minHeight: 420,
      quality: 46,
      format: CompressFormat.jpeg,
    );
    if (thumbnail.isNotEmpty) return thumbnail;
  } catch (_) {}
  return Uint8List.fromList(bytes);
}

String _formatVoiceDuration(int milliseconds) {
  final duration = Duration(milliseconds: max(0, milliseconds));
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds.remainder(60);
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

class _VoiceCapture {
  final Uint8List bytes;
  final int durationMs;
  final String mimeType;

  const _VoiceCapture({
    required this.bytes,
    required this.durationMs,
    required this.mimeType,
  });
}

class _VoiceRecordingDialog extends StatefulWidget {
  final DateTime startedAt;

  const _VoiceRecordingDialog({required this.startedAt});

  @override
  State<_VoiceRecordingDialog> createState() => _VoiceRecordingDialogState();
}

class _VoiceRecordingDialogState extends State<_VoiceRecordingDialog> {
  Timer? _timer;
  int _elapsedMs = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => _refresh(),
    );
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {
      _elapsedMs = DateTime.now().difference(widget.startedAt).inMilliseconds;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.mic, color: Colors.red),
          SizedBox(width: 10),
          Text('Registrazione in corso'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatVoiceDuration(_elapsedMs),
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
          const SizedBox(height: 12),
          const Text(
            'L’audio originale resterà nel diario finché non lo elimini.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton.icon(
          onPressed: () => Navigator.pop(context, false),
          icon: const Icon(Icons.delete_outline),
          label: const Text('Annulla'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(context, true),
          icon: const Icon(Icons.stop_circle_outlined),
          label: const Text('Termina'),
        ),
      ],
    );
  }
}

Future<_VoiceCapture?> captureVoiceClip(BuildContext context) async {
  if (kIsWeb) {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return null;
    final file = picked.files.single;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) return null;
    return _VoiceCapture(
      bytes: Uint8List.fromList(bytes),
      durationMs: 0,
      mimeType: 'audio/*',
    );
  }

  try {
    await VoiceDiaryService.instance.startRecording();
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Consenti l’accesso al microfono e tocca di nuovo “Voce”.',
          ),
        ),
      );
    }
    return null;
  }

  final startedAt = DateTime.now();
  final save = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _VoiceRecordingDialog(startedAt: startedAt),
      ) ??
      false;

  if (!save) {
    await VoiceDiaryService.instance.cancelRecording();
    return null;
  }

  try {
    final bytes = await VoiceDiaryService.instance.stopRecording();
    return _VoiceCapture(
      bytes: bytes,
      durationMs: DateTime.now().difference(startedAt).inMilliseconds,
      mimeType: 'audio/mp4',
    );
  } catch (_) {
    await VoiceDiaryService.instance.cancelRecording();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registrazione non salvata. Riprova.')),
      );
    }
    return null;
  }
}

Future<Uint8List?> _readDiaryMediaBytes({
  String assetId = '',
  String fallbackBase64 = '',
}) async {
  if (assetId.isNotEmpty) {
    final stored = await MediaAssetStore.instance.read(assetId);
    if (stored != null) return stored;
  }
  if (fallbackBase64.isNotEmpty) {
    try {
      return base64Decode(fallbackBase64);
    } catch (_) {}
  }
  return null;
}

class DiaryMediaImage extends StatefulWidget {
  final String assetId;
  final String fallbackBase64;
  final BoxFit fit;
  final int? cacheWidth;
  final Widget? empty;

  const DiaryMediaImage({
    super.key,
    this.assetId = '',
    this.fallbackBase64 = '',
    this.fit = BoxFit.cover,
    this.cacheWidth,
    this.empty,
  });

  @override
  State<DiaryMediaImage> createState() => _DiaryMediaImageState();
}

class _DiaryMediaImageState extends State<DiaryMediaImage> {
  late Future<Uint8List?> _future = _load();

  Future<Uint8List?> _load() => _readDiaryMediaBytes(
        assetId: widget.assetId,
        fallbackBase64: widget.fallbackBase64,
      );

  @override
  void didUpdateWidget(covariant DiaryMediaImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetId != widget.assetId ||
        oldWidget.fallbackBase64 != widget.fallbackBase64) {
      _future = _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _future,
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null || bytes.isEmpty) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          return widget.empty ??
              const Center(child: Icon(Icons.broken_image_outlined));
        }
        return Image.memory(
          bytes,
          fit: widget.fit,
          width: double.infinity,
          height: double.infinity,
          cacheWidth: widget.cacheWidth,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) =>
              widget.empty ??
              const Center(child: Icon(Icons.broken_image_outlined)),
        );
      },
    );
  }
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
                'Nel diario viene salvata una copia ottimizzata ad alta qualità.',
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

Future<String?> showDiaryNoteEditor(
  BuildContext context, {
  String initialText = '',
  bool editing = false,
}) async {
  final controller = TextEditingController(text: initialText);
  final value = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(editing ? 'Modifica nota' : 'Nuova nota'),
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
  return value;
}

Future<String?> showDiaryCaptionEditor(
  BuildContext context, {
  String initialText = '',
  bool adding = false,
}) async {
  final controller = TextEditingController(text: initialText);
  final value = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(adding ? 'Aggiungi al diario' : 'Didascalia'),
      content: TextField(
        controller: controller,
        autofocus: true,
        minLines: adding ? 1 : 2,
        maxLines: 5,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          hintText: adding
              ? 'Una didascalia, se vuoi...'
              : 'Scrivi qualcosa su questo ricordo...',
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        if (adding)
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, ''),
            child: const Text('Senza testo'),
          )
        else
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annulla'),
          ),
        FilledButton(
          onPressed: () => Navigator.pop(
            dialogContext,
            controller.text.trim(),
          ),
          child: Text(adding ? 'Aggiungi' : 'Salva'),
        ),
      ],
    ),
  );
  controller.dispose();
  return value;
}

Future<bool> confirmDiaryContentDelete(
  BuildContext context, {
  bool movesToTrash = false,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminare dal diario?'),
        content: Text(
          movesToTrash
              ? 'Questo contenuto verrà spostato nel Cestino e potrai ripristinarlo.'
              : 'Questo contenuto verrà rimosso dalla giornata.',
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

enum DiaryContentKind { note, photo, sketch, voice }

extension DiaryContentKindUi on DiaryContentKind {
  String get label => switch (this) {
        DiaryContentKind.note => 'Nota',
        DiaryContentKind.photo => 'Foto',
        DiaryContentKind.sketch => 'Sketch',
        DiaryContentKind.voice => 'Voce',
      };

  IconData get icon => switch (this) {
        DiaryContentKind.note => Icons.sticky_note_2_outlined,
        DiaryContentKind.photo => Icons.photo_outlined,
        DiaryContentKind.sketch => Icons.draw_outlined,
        DiaryContentKind.voice => Icons.mic_none_outlined,
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
  final VoidCallback onAddVoice;
  final bool photoBusy;
  final bool voiceBusy;
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
    required this.onAddVoice,
    required this.photoBusy,
    required this.voiceBusy,
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
                onPressed: voiceBusy ? null : onAddVoice,
                icon: voiceBusy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.mic_none_outlined),
                label: const Text('Voce'),
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
  final VoidCallback? onPeople;
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
    this.onPeople,
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
                    if (value == 'people') onPeople?.call();
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
                    if (onPeople != null)
                      const PopupMenuItem(
                        value: 'people',
                        child: Text('Collega persone'),
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

class DiaryZoomableImage extends StatelessWidget {
  final Uint8List? bytes;
  final bool loading;

  const DiaryZoomableImage({
    super.key,
    required this.bytes,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final data = bytes;
    if (data == null || data.isEmpty) {
      return const Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: Colors.white70,
          size: 64,
        ),
      );
    }
    return InteractiveViewer(
      minScale: 0.75,
      maxScale: 6,
      child: Center(
        child: Image.memory(
          data,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.broken_image_outlined,
            color: Colors.white70,
            size: 64,
          ),
        ),
      ),
    );
  }
}

class DiaryPhotoViewerShell extends StatelessWidget {
  final String title;
  final Widget image;
  final String caption;
  final List<Widget> metadata;
  final List<Widget> actions;
  final List<Widget> appBarActions;

  const DiaryPhotoViewerShell({
    super.key,
    required this.title,
    required this.image,
    this.caption = '',
    this.metadata = const [],
    this.actions = const [],
    this.appBarActions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: appBarActions,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: image),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                color: Colors.black,
                border: Border(
                  top: BorderSide(color: Colors.white12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (caption.trim().isNotEmpty) ...[
                    Text(
                      caption.trim(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  for (var i = 0; i < metadata.length; i++) ...[
                    metadata[i],
                    if (i < metadata.length - 1) const SizedBox(height: 4),
                  ],
                  if (actions.isNotEmpty) ...[
                    if (metadata.isNotEmpty || caption.trim().isNotEmpty)
                      const SizedBox(height: 12),
                    Row(
                      children: [
                        for (var i = 0; i < actions.length; i++) ...[
                          Expanded(child: actions[i]),
                          if (i < actions.length - 1)
                            const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
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
  bool voiceBusy = false;

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
    final value = await showDiaryNoteEditor(
      context,
      initialText: existing?.text ?? '',
      editing: existing != null,
    );
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
      final imageBytes = await _pickCompressedDiaryImageBytes(source);
      if (imageBytes == null || !mounted) return;

      final caption = await showDiaryCaptionEditor(
        context,
        adding: true,
      );
      if (caption == null) return;

      final mediaAssetId = await MediaAssetStore.instance.put(imageBytes);
      final mediaThumbnailAssetId = await MediaAssetStore.instance.put(
        await _diaryThumbnailBytes(imageBytes),
      );
      final blocks = [
        ...widget.store.journal(widget.date).blocks,
        DiaryBlock(
          id: const Uuid().v4(),
          type: DiaryBlockType.photo,
          createdAt: DateTime.now(),
          text: caption,
          mediaAssetId: mediaAssetId,
          mediaThumbnailAssetId: mediaThumbnailAssetId,
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

  Future<void> _addVoice() async {
    if (voiceBusy) return;
    setState(() => voiceBusy = true);
    try {
      final capture = await captureVoiceClip(context);
      if (capture == null || !mounted) return;

      final caption = await showDiaryCaptionEditor(
        context,
        adding: true,
      );
      if (caption == null) return;

      final mediaAssetId = await MediaAssetStore.instance.put(capture.bytes);
      final blocks = [
        ...widget.store.journal(widget.date).blocks,
        DiaryBlock(
          id: const Uuid().v4(),
          type: DiaryBlockType.voice,
          createdAt: DateTime.now(),
          text: caption,
          mediaAssetId: mediaAssetId,
          audioDurationMs: capture.durationMs,
          audioMimeType: capture.mimeType,
        ),
      ];
      await _saveBlocks(blocks);
    } finally {
      if (mounted) setState(() => voiceBusy = false);
    }
  }

  Future<void> _editVoiceCaption(DiaryBlock block) async {
    final value = await showDiaryCaptionEditor(
      context,
      initialText: block.text,
    );
    if (value == null) return;

    final blocks = [...widget.store.journal(widget.date).blocks];
    final index = blocks.indexWhere((candidate) => candidate.id == block.id);
    if (index >= 0) {
      blocks[index] = block.copyWith(text: value);
      await _saveBlocks(blocks);
    }
  }

  Future<void> _playVoice(DiaryBlock block) async {
    if (!block.hasVoiceMedia) return;
    final bytes = await _readDiaryMediaBytes(
      assetId: block.mediaAssetId,
      fallbackBase64: block.audioBase64,
    );
    if (bytes == null || bytes.isEmpty || !mounted) return;

    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sul web puoi conservare/importare l’audio; il player integrato è disponibile nell’app Android.',
          ),
        ),
      );
      return;
    }

    try {
      await VoiceDiaryService.instance.play(bytes);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Non riesco a riprodurre questo audio.')),
        );
      }
    }
  }

  Future<void> _editPhotoCaption(DiaryBlock block) async {
    final value = await showDiaryCaptionEditor(
      context,
      initialText: block.text,
    );
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
      final imageBytes = await _pickCompressedDiaryImageBytes(source);
      if (imageBytes == null) return;

      final mediaAssetId = await MediaAssetStore.instance.put(imageBytes);
      final mediaThumbnailAssetId = await MediaAssetStore.instance.put(
        await _diaryThumbnailBytes(imageBytes),
      );
      final blocks = [...widget.store.journal(widget.date).blocks];
      final index =
          blocks.indexWhere((candidate) => candidate.id == block.id);
      if (index >= 0) {
        blocks[index] = block.copyWith(
          imageBase64: '',
          mediaAssetId: mediaAssetId,
          mediaThumbnailAssetId: mediaThumbnailAssetId,
        );
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

  Future<void> _editPeople(DiaryBlock block) async {
    final selected = await showPeoplePicker(
      context,
      widget.store,
      initialIds: block.personIds,
    );
    if (selected == null) return;
    await widget.store.tagDiaryBlockPeople(widget.date, block.id, selected);
  }

  Widget? _peopleFooter(DiaryBlock block) {
    final linked = widget.store.peopleForIds(block.personIds);
    if (linked.isEmpty) return null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: linked
            .map(
              (person) => Chip(
                visualDensity: VisualDensity.compact,
                avatar: Icon(
                  person.favorite ? Icons.star : Icons.person_outline,
                  size: 16,
                ),
                label: Text(person.name),
              ),
            )
            .toList(),
      ),
    );
  }

  Future<void> _delete(DiaryBlock block) async {
    final confirmed = await confirmDiaryContentDelete(
      context,
      movesToTrash: true,
    );
    if (!confirmed) return;

    await widget.store.moveDiaryBlockToTrash(widget.date, block.id);
  }

  void _openPhoto(DiaryBlock block) {
    if (!block.hasPhotoMedia) return;
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
          onPeople: () => _editPeople(block),
          footer: _peopleFooter(block),
          onDelete: () => _delete(block),
        );
      case DiaryBlockType.photo:
        return DiaryContentCard(
          kind: DiaryContentKind.photo,
          title: block.text.trim().isEmpty
              ? 'Foto del giorno'
              : block.text,
          subtitle: 'Foto · $time',
          preview: !block.hasPhotoMedia
              ? null
              : DiaryMediaImage(
                  assetId: block.mediaThumbnailAssetId.isNotEmpty
                      ? block.mediaThumbnailAssetId
                      : block.mediaAssetId,
                  fallbackBase64: block.imageBase64,
                  fit: BoxFit.cover,
                  cacheWidth: 720,
                ),
          onOpen: () => _openPhoto(block),
          onEditCaption: () => _editPhotoCaption(block),
          onReplacePhoto: () => _replacePhoto(block),
          onPeople: () => _editPeople(block),
          footer: _peopleFooter(block),
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
          onPeople: () => _editPeople(block),
          footer: _peopleFooter(block),
          onDelete: () => _delete(block),
        );
      case DiaryBlockType.voice:
        final duration = block.audioDurationMs <= 0
            ? ''
            : ' · ${_formatVoiceDuration(block.audioDurationMs)}';
        return DiaryContentCard(
          kind: DiaryContentKind.voice,
          title: block.text.trim().isEmpty ? 'Nota vocale' : block.text,
          subtitle: 'Voce$duration · $time',
          onOpen: () => _playVoice(block),
          onEdit: () => _editVoiceCaption(block),
          onPeople: () => _editPeople(block),
          footer: _peopleFooter(block),
          statusIcon: const Icon(Icons.play_circle_outline),
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
      onAddVoice: _addVoice,
      photoBusy: photoBusy,
      voiceBusy: voiceBusy,
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
