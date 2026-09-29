part of '../main.dart';

enum UnifiedCaptureEntryPoint { home, day, inbox }

enum _UnifiedCaptureAction {
  text,
  voice,
  photo,
  inbox,
  task,
  event,
  birthday,
  person,
}

DateTime _normalizeUnifiedCaptureDay(DateTime? value) {
  final source = value ?? DateTime.now();
  return DateTime(source.year, source.month, source.day);
}

DateTime _unifiedCaptureTimestamp(DateTime day) {
  final now = DateTime.now();
  return DateTime(
    day.year,
    day.month,
    day.day,
    now.hour,
    now.minute,
    now.second,
    now.millisecond,
    now.microsecond,
  );
}

Future<void> _saveUnifiedCaptureText(
  AgendaStore store,
  DateTime day,
  String text, {
  bool toInbox = false,
}) async {
  final value = text.trim();
  if (value.isEmpty) return;

  if (toInbox) {
    await store.addInboxEntry(value);
    return;
  }

  final normalizedDay = _normalizeUnifiedCaptureDay(day);
  final journal = store.journal(normalizedDay);
  await store.saveJournal(
    normalizedDay,
    journal.copyWith(
      blocks: [
        ...journal.blocks,
        DiaryBlock(
          id: const Uuid().v4(),
          type: DiaryBlockType.note,
          createdAt: _unifiedCaptureTimestamp(normalizedDay),
          text: value,
        ),
      ],
    ),
  );
}

Future<void> _saveUnifiedCaptureVoice(
  AgendaStore store,
  DateTime day,
  _VoiceCapture capture, {
  String caption = '',
}) async {
  final normalizedDay = _normalizeUnifiedCaptureDay(day);
  final assetId = await MediaAssetStore.instance.put(capture.bytes);
  final journal = store.journal(normalizedDay);
  await store.saveJournal(
    normalizedDay,
    journal.copyWith(
      blocks: [
        ...journal.blocks,
        DiaryBlock(
          id: const Uuid().v4(),
          type: DiaryBlockType.voice,
          createdAt: _unifiedCaptureTimestamp(normalizedDay),
          text: caption.trim(),
          mediaAssetId: assetId,
          audioDurationMs: capture.durationMs,
          audioMimeType: capture.mimeType,
        ),
      ],
    ),
  );
}

Future<void> _saveUnifiedCapturePhoto(
  AgendaStore store,
  DateTime day,
  Uint8List imageBytes, {
  String caption = '',
}) async {
  if (imageBytes.isEmpty) return;

  final normalizedDay = _normalizeUnifiedCaptureDay(day);
  final mediaAssetId = await MediaAssetStore.instance.put(imageBytes);
  final mediaThumbnailAssetId = await MediaAssetStore.instance.put(
    await _diaryThumbnailBytes(imageBytes),
  );
  final journal = store.journal(normalizedDay);

  await store.saveJournal(
    normalizedDay,
    journal.copyWith(
      blocks: [
        ...journal.blocks,
        DiaryBlock(
          id: const Uuid().v4(),
          type: DiaryBlockType.photo,
          createdAt: _unifiedCaptureTimestamp(normalizedDay),
          text: caption.trim(),
          mediaAssetId: mediaAssetId,
          mediaThumbnailAssetId: mediaThumbnailAssetId,
        ),
      ],
    ),
  );
}

Future<ImageSource?> _chooseUnifiedCaptureImageSource(
  BuildContext context,
) {
  return showModalBottomSheet<ImageSource>(
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
              'La foto viene salvata come normale momento del diario.',
            ),
          ),
          if (!kIsWeb)
            ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.photo_camera_outlined),
              ),
              title: const Text('Scatta una foto'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
          ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.photo_library_outlined),
            ),
            title: const Text(kIsWeb ? 'Scegli una foto' : 'Scegli dalla galleria'),
            onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
}

Future<String?> _showUnifiedInboxEditor(BuildContext context) async {
  final controller = TextEditingController();
  final value = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Nota rapida'),
      content: TextField(
        controller: controller,
        autofocus: true,
        minLines: 2,
        maxLines: 6,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          hintText: 'Scrivi al volo...',
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
  return value;
}

Future<void> showUnifiedCapture(
  BuildContext context,
  AgendaStore store, {
  DateTime? initialDate,
  UnifiedCaptureEntryPoint entryPoint = UnifiedCaptureEntryPoint.home,
}) async {
  final targetDay = _normalizeUnifiedCaptureDay(initialDate);
  final dayLabel = AgendaStore.sameDay(targetDay, DateTime.now())
      ? 'oggi'
      : DateFormat('d MMMM', 'it_IT').format(targetDay);

  final action = await showModalBottomSheet<_UnifiedCaptureAction>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text(
                'Cattura',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Text(
                entryPoint == UnifiedCaptureEntryPoint.inbox
                    ? 'Scrivi al volo oppure salva un momento nella giornata.'
                    : 'Testo, voce e foto entrano nello stesso flusso della giornata.',
              ),
            ),
            ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.edit_note_outlined),
              ),
              title: const Text('Scrivi un momento'),
              subtitle: Text('Aggiungi una nota al diario di $dayLabel.'),
              onTap: () =>
                  Navigator.pop(sheetContext, _UnifiedCaptureAction.text),
            ),
            ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.mic_none_outlined),
              ),
              title: const Text('Nota vocale'),
              subtitle: Text('Registra un audio nel diario di $dayLabel.'),
              onTap: () =>
                  Navigator.pop(sheetContext, _UnifiedCaptureAction.voice),
            ),
            ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.photo_camera_back_outlined),
              ),
              title: const Text('Foto'),
              subtitle: Text('Salva una foto come momento di $dayLabel.'),
              onTap: () =>
                  Navigator.pop(sheetContext, _UnifiedCaptureAction.photo),
            ),
            ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.inbox_outlined),
              ),
              title: const Text('Nota rapida in Inbox'),
              subtitle: const Text('Da organizzare in un secondo momento.'),
              onTap: () =>
                  Navigator.pop(sheetContext, _UnifiedCaptureAction.inbox),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: const Text('Attività'),
              onTap: () =>
                  Navigator.pop(sheetContext, _UnifiedCaptureAction.task),
            ),
            ListTile(
              leading: const Icon(Icons.event_outlined),
              title: const Text('Appuntamento'),
              onTap: () =>
                  Navigator.pop(sheetContext, _UnifiedCaptureAction.event),
            ),
            ListTile(
              leading: const Icon(Icons.cake_outlined),
              title: const Text('Compleanno'),
              onTap: () =>
                  Navigator.pop(sheetContext, _UnifiedCaptureAction.birthday),
            ),
            ListTile(
              leading: const Icon(Icons.person_add_alt_1_outlined),
              title: const Text('Persona importante'),
              onTap: () =>
                  Navigator.pop(sheetContext, _UnifiedCaptureAction.person),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Chiudi'),
              onTap: () => Navigator.pop(sheetContext),
            ),
          ],
        ),
      ),
    ),
  );

  if (!context.mounted || action == null) return;

  switch (action) {
    case _UnifiedCaptureAction.text:
      final text = await showDiaryNoteEditor(context);
      if (text == null || text.trim().isEmpty) return;
      await _saveUnifiedCaptureText(store, targetDay, text);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Momento salvato nel diario di $dayLabel.')),
        );
      }
      return;

    case _UnifiedCaptureAction.voice:
      final capture = await _captureVoiceClip(context);
      if (capture == null || !context.mounted) return;
      final caption = await showDiaryCaptionEditor(context, adding: true);
      if (caption == null) return;
      await _saveUnifiedCaptureVoice(
        store,
        targetDay,
        capture,
        caption: caption,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nota vocale salvata nel diario di $dayLabel.')),
        );
      }
      return;

    case _UnifiedCaptureAction.photo:
      final source = await _chooseUnifiedCaptureImageSource(context);
      if (source == null || !context.mounted) return;
      final imageBytes = await _pickCompressedDiaryImageBytes(source);
      if (imageBytes == null || imageBytes.isEmpty || !context.mounted) return;
      final caption = await showDiaryCaptionEditor(context, adding: true);
      if (caption == null) return;
      await _saveUnifiedCapturePhoto(
        store,
        targetDay,
        imageBytes,
        caption: caption,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Foto salvata nel diario di $dayLabel.')),
        );
      }
      return;

    case _UnifiedCaptureAction.inbox:
      final value = await _showUnifiedInboxEditor(context);
      if (value == null || value.trim().isEmpty) return;
      await _saveUnifiedCaptureText(
        store,
        targetDay,
        value,
        toInbox: true,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nota salvata in Inbox.')),
        );
      }
      return;

    case _UnifiedCaptureAction.task:
      await openUnifiedItemComposer(
        context,
        store,
        targetDay,
        initialType: ItemType.task,
      );
      return;

    case _UnifiedCaptureAction.event:
      await openUnifiedItemComposer(
        context,
        store,
        targetDay,
        initialType: ItemType.appointment,
      );
      return;

    case _UnifiedCaptureAction.birthday:
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BirthdaysScreen(store: store),
        ),
      );
      return;

    case _UnifiedCaptureAction.person:
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PeopleScreen(
            store: store,
            startAdding: true,
          ),
        ),
      );
      return;
  }
}
