part of '../main.dart';

enum UnifiedCaptureEntryPoint { home, month, week, day, inbox, external }

enum _UnifiedCaptureAction {
  text,
  voice,
  photo,
  sketch,
  templates,
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
  final strings = AnnaStrings.of(context);
  return showModalBottomSheet<ImageSource>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Wrap(
        children: [
          ListTile(
            title: Text(
              strings.addPhoto,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            subtitle: Text(strings.photoStoredAsDiaryMoment),
          ),
          if (!kIsWeb)
            ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.photo_camera_outlined),
              ),
              title: Text(strings.takePhoto),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
          ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.photo_library_outlined),
            ),
            title: Text(kIsWeb ? strings.choosePhoto : strings.chooseGallery),
            onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
}

Future<String?> _showUnifiedInboxEditor(BuildContext context) async {
  final strings = AnnaStrings.of(context);
  final controller = TextEditingController();
  final value = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(strings.quickNote),
      content: TextField(
        controller: controller,
        autofocus: true,
        minLines: 2,
        maxLines: 6,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          hintText: strings.writeQuickly,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(strings.cancel),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.pop(dialogContext, controller.text.trim()),
          child: Text(strings.save),
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
  final strings = AnnaStrings.of(context);
  var targetDay = _normalizeUnifiedCaptureDay(initialDate);
  var dayLabel = strings.dayWord(targetDay);

  final action = await showModalBottomSheet<_UnifiedCaptureAction>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      var showAllActions = false;

      Widget actionTile({
        required IconData icon,
        required String title,
        String? subtitle,
        required _UnifiedCaptureAction action,
        bool primary = false,
      }) {
        return ListTile(
          leading: primary
              ? CircleAvatar(child: Icon(icon))
              : Icon(icon),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: primary ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
          subtitle: subtitle == null ? null : Text(subtitle),
          onTap: () {
            unawaited(AnnaFeedback.selection());
            Navigator.pop(sheetContext, action);
          },
        );
      }

      return StatefulBuilder(
        builder: (context, setSheetState) {
          final animate = AnnaDesignTokens.animationsEnabled(context);
          return SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text(
                      strings.capture,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      entryPoint == UnifiedCaptureEntryPoint.inbox
                          ? strings.captureInboxDescription
                          : strings.captureDayDescription,
                    ),
                  ),
                  // DF-06/07: display the effective date and permit a
                  // reversible override before any capture writer runs.
                  Semantics(
                    identifier: 'capture-effective-date',
                    child: ListTile(
                      leading: const Icon(Icons.event_available_outlined),
                      title: Text(_cap(DateFormat(
                        'EEEE d MMMM yyyy',
                        AnnaStrings.intlLocale(sheetContext),
                      ).format(targetDay))),
                      trailing: const Icon(Icons.edit_calendar_outlined),
                      onTap: () async {
                        final changed = await showDatePicker(
                          context: sheetContext,
                          initialDate: targetDay,
                          firstDate: DateTime(1900),
                          lastDate: DateTime(2100),
                        );
                        if (changed == null || !sheetContext.mounted) return;
                        setSheetState(() {
                          targetDay = _normalizeUnifiedCaptureDay(changed);
                          dayLabel = strings.dayWord(targetDay);
                        });
                      },
                    ),
                  ),
                  actionTile(
                    icon: Icons.edit_note_outlined,
                    title: strings.writeMoment,
                    subtitle: strings.addDiaryNote(dayLabel),
                    action: _UnifiedCaptureAction.text,
                    primary: true,
                  ),
                  actionTile(
                    icon: Icons.photo_camera_back_outlined,
                    title: strings.photo,
                    subtitle: strings.savePhotoMoment(dayLabel),
                    action: _UnifiedCaptureAction.photo,
                    primary: true,
                  ),
                  actionTile(
                    icon: Icons.check_circle_outline,
                    title: strings.task,
                    action: _UnifiedCaptureAction.task,
                    primary: true,
                  ),
                  actionTile(
                    icon: Icons.mic_none_outlined,
                    title: strings.voiceNote,
                    subtitle: strings.recordDiaryAudio(dayLabel),
                    action: _UnifiedCaptureAction.voice,
                    primary: true,
                  ),
                  actionTile(
                    icon: Icons.draw_outlined,
                    title: strings.v100Sketch,
                    action: _UnifiedCaptureAction.sketch,
                    primary: true,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AnnaDesignTokens.spaceSm,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () {
                          unawaited(AnnaFeedback.selection());
                          setSheetState(() => showAllActions = !showAllActions);
                        },
                        icon: AnimatedRotation(
                          turns: showAllActions ? 0.5 : 0,
                          duration: animate
                              ? AnnaDesignTokens.motionStandard
                              : Duration.zero,
                          child: const Icon(Icons.expand_more),
                        ),
                        label: Text(
                          strings.d3(
                            showAllActions
                                ? 'captureFewerActions'
                                : 'captureMoreActions',
                          ),
                        ),
                      ),
                    ),
                  ),
                  AnimatedSize(
                    duration: animate
                        ? AnnaDesignTokens.motionStandard
                        : Duration.zero,
                    alignment: Alignment.topCenter,
                    child: showAllActions
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Divider(height: 1),
                              actionTile(
                                icon: Icons.inbox_outlined,
                                title: strings.quickInboxNote,
                                subtitle: strings.organizeLater,
                                action: _UnifiedCaptureAction.inbox,
                              ),
                              actionTile(
                                icon: Icons.event_outlined,
                                title: strings.appointment,
                                action: _UnifiedCaptureAction.event,
                              ),
                              actionTile(
                                icon: Icons.cake_outlined,
                                title: strings.birthday,
                                action: _UnifiedCaptureAction.birthday,
                              ),
                              actionTile(
                                icon: Icons.person_add_alt_1_outlined,
                                title: strings.importantPerson,
                                action: _UnifiedCaptureAction.person,
                              ),
                              actionTile(
                                icon: Icons.library_books_outlined,
                                title: strings.d3('templates'),
                                action: _UnifiedCaptureAction.templates,
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AnnaDesignTokens.spaceSm,
                      0,
                      AnnaDesignTokens.spaceSm,
                      AnnaDesignTokens.spaceXs,
                    ),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        child: Text(strings.close),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  if (!context.mounted || action == null) return;

  switch (action) {
    case _UnifiedCaptureAction.sketch:
      final pages = await Navigator.push<List<DiarySketchPage>>(
        context,
        MaterialPageRoute(
          builder: (_) => DiarySketchbookScreen(
            initialPages: [DiarySketchPage(id: const Uuid().v4())],
          ),
        ),
      );
      if (pages == null || pages.isEmpty) return;
      final journal = store.journal(targetDay);
      await store.saveJournal(
        targetDay,
        journal.copyWith(
          blocks: [
            ...journal.blocks,
            DiaryBlock(
              id: const Uuid().v4(),
              type: DiaryBlockType.sketch,
              createdAt: _unifiedCaptureTimestamp(targetDay),
              pages: pages,
            ),
          ],
        ),
      );
      unawaited(AnnaFeedback.success());
      return;

    case _UnifiedCaptureAction.templates:
      final preset = await showDiaryTemplatePicker(context);
      if (preset == null || !context.mounted) return;
      var draft = await showDiaryNoteEditor(
        context,
        initialText: preset.seedText.replaceAll('☐', '•'),
      );
      while (draft != null && draft.trim().isNotEmpty && context.mounted) {
        try {
          await store.applyDiaryTemplate(
            targetDay,
            preset,
            createdAt: _unifiedCaptureTimestamp(targetDay),
            textOverride: draft.trim(),
          );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(strings.d3Format(
                  'templateAdded',
                  {'title': preset.title},
                )),
              ),
            );
          }
          return;
        } catch (_) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(strings.d3('templateSaveFailed'))),
          );
          // Never silently lose the draft if a local save fails.
          draft = await showDiaryNoteEditor(context, initialText: draft);
        }
      }
      return;

    case _UnifiedCaptureAction.text:
      final text = await showDiaryNoteEditor(context);
      if (text == null || text.trim().isEmpty) return;
      await _saveUnifiedCaptureText(store, targetDay, text);
      unawaited(AnnaFeedback.success());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.momentSaved(dayLabel))),
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
      unawaited(AnnaFeedback.success());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.voiceSaved(dayLabel))),
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
      unawaited(AnnaFeedback.success());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.photoSaved(dayLabel))),
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
      unawaited(AnnaFeedback.success());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.inboxSaved)),
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
