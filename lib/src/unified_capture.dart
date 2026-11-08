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
  taskFromText,
  checklistFromNote,
  event,
  birthday,
  person,
}

/// CAP-0092/0093: preview-only local proposals. No persistence until the
/// existing canonical item editor explicitly saves. No new task database.
class AnnaCaptureTaskProposal {
  final String title;
  final String note;
  final DateTime date;
  final TimeOfDay? time;

  const AnnaCaptureTaskProposal({
    required this.title,
    required this.note,
    required this.date,
    this.time,
  });

  AgendaItem toEditorDraft() => AgendaItem(
    id: const Uuid().v4(),
    title: title,
    note: note,
    date: date,
    start: time,
    type: ItemType.task,
  );
}

AnnaCaptureTaskProposal? annaProposeTaskFromText(
  String text, {
  required DateTime selectedDay,
  required String languageCode,
  required DateTime now,
}) {
  final clean = text.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (clean.length < 3 || clean.length > 300 ||
      !const {'it', 'en', 'es', 'fr', 'pt'}.contains(languageCode)) {
    return null;
  }
  // Reuse the established parser if the phrase has an unambiguous date/time.
  // Unsupported explicit timezone abbreviations fail closed.
  if (RegExp(r'\b(?:utc|gmt|cet|cest|pst|pdt|est|edt)\b',
      caseSensitive: false).hasMatch(clean)) { return null; }
  final parsed = parseNaturalEvent(clean,
    languageCode: languageCode, now: now);
  final label = parsed?.title.trim() ?? clean;
  if (label.length < 3 || label.length > 160) return null;
  return AnnaCaptureTaskProposal(
    title: label,
    note: parsed == null ? '' : clean,
    date: parsed?.date ?? DateTime(
      selectedDay.year, selectedDay.month, selectedDay.day),
    time: parsed?.start,
  );
}

AnnaCaptureTaskProposal? annaProposeChecklistFromDiary(
  String sourceText, {
  required DateTime targetDay,
}) {
  if (sourceText.isEmpty || sourceText.length > 4000) return null;
  final lines = sourceText.split('\n');
  final checklist = <EventPreparationStep>[];
  final other = <String>[];
  final pattern = RegExp(r'^\s*(?:[-*•]|\d+[.)]|\[[ xX]\]|[☐☑])\s+(.+?)\s*$');
  for (final line in lines) {
    final match = pattern.firstMatch(line);
    if (match == null) {
      other.add(line);
      continue;
    }
    final label = match.group(1)!.trim();
    if (label.length < 2 || label.length > 180) return null;
    checklist.add(EventPreparationStep(label));
    if (checklist.length > 20) return null;
  }
  if (checklist.isEmpty) return null;
  final prose = other.join('\n').trim();
  final title = (prose.isEmpty ? checklist.first.text : prose.split('\n').first)
      .trim();
  final safeTitle = title.length > 120 ? title.substring(0, 120) : title;
  if (safeTitle.isEmpty) return null;
  final note = EventPreparationDraft(note: prose, steps: checklist).compose();
  return AnnaCaptureTaskProposal(
    title: safeTitle, note: note,
    date: DateTime(targetDay.year, targetDay.month, targetDay.day),
  );
}

String _annaCaptureProposalLabel(String languageCode, String key) {
  const strings = <String, Map<String, String>>{
    'taskFromText': {
      'it': 'Task da una frase', 'en': 'Task from a sentence',
      'es': 'Tarea desde una frase', 'fr': 'Tâche depuis une phrase',
      'pt': 'Tarefa a partir de uma frase',
    },
    'checklistFromNote': {
      'it': 'Checklist da una nota', 'en': 'Checklist from a note',
      'es': 'Lista desde una nota', 'fr': 'Liste depuis une note',
      'pt': 'Lista a partir de uma nota',
    },
    'writePhrase': {
      'it': 'Scrivi cosa vorresti fare', 'en': 'Write what you want to do',
      'es': 'Escribe lo que quieres hacer', 'fr': 'Écris ce que tu veux faire',
      'pt': 'Escreve o que queres fazer',
    },
    'review': {
      'it': 'Rivedi la bozza', 'en': 'Review draft',
      'es': 'Revisar borrador', 'fr': 'Vérifier le brouillon',
      'pt': 'Rever rascunho',
    },
    'noChecklist': {
      'it': 'Nessuna nota con un elenco adatto', 'en': 'No note has a suitable list',
      'es': 'No hay notas con una lista válida', 'fr': 'Aucune note avec une liste adaptée',
      'pt': 'Nenhuma nota com uma lista adequada',
    },
    'staleSource': {
      'it': 'La nota è cambiata. Riapri la cattura.',
      'en': 'The note changed. Open capture again.',
      'es': 'La nota ha cambiado. Vuelve a abrir la captura.',
      'fr': 'La note a changé. Rouvre la saisie.',
      'pt': 'A nota mudou. Abre novamente a captura.',
    },
  };
  return strings[key]?[languageCode] ?? strings[key]?['en'] ?? key;
}

Future<String?> _askLocalTaskSentence(BuildContext context) async {
  final language = AnnaStrings.of(context).languageCode;
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(_annaCaptureProposalLabel(language, 'taskFromText')),
      content: TextField(
        key: const ValueKey('anna-cap0092-task-source'),
        controller: controller,
        autofocus: true,
        minLines: 2,
        maxLines: 4,
        maxLength: 300,
        decoration: InputDecoration(
          hintText: _annaCaptureProposalLabel(language, 'writePhrase')),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(AnnaStrings.of(dialogContext).cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, controller.text),
          child: Text(_annaCaptureProposalLabel(language, 'review')),
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}

Future<DiaryBlockReference?> _pickLocalChecklistNote(
  BuildContext context,
  AgendaStore store,
  DateTime targetDay,
) async {
  final language = AnnaStrings.of(context).languageCode;
  final available = store.allDiaryBlockReferences(includeArchived: false)
      .where((ref) => ref.block.type == DiaryBlockType.note &&
          annaProposeChecklistFromDiary(ref.block.text,
              targetDay: targetDay) != null)
      .take(40)
      .toList(growable: false);
  if (available.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(_annaCaptureProposalLabel(language, 'noChecklist'))));
    return null;
  }
  return showDialog<DiaryBlockReference>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(_annaCaptureProposalLabel(language, 'checklistFromNote')),
      content: SizedBox(
        width: 540,
        height: 420,
        child: ListView.builder(
          itemCount: available.length,
          itemBuilder: (context, index) {
            final ref = available[index];
            final preview = ref.block.text.replaceAll(RegExp(r'\s+'), ' ');
            return ListTile(
              title: Text(preview.length > 95
                  ? '${preview.substring(0, 95)}…' : preview),
              subtitle: Text(DateFormat('d MMM yyyy',
                  AnnaStrings.intlLocale(context)).format(ref.date)),
              onTap: () => Navigator.pop(dialogContext, ref),
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext),
          child: Text(AnnaStrings.of(dialogContext).cancel)),
      ],
    ),
  );
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
      // Make the quick capture feel like a writing surface while remaining
      // keyboard-safe on compact Android screens and under large text scale.
      key: const ValueKey('quick-note-comfort-dialog'),
      scrollable: true,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
      constraints: const BoxConstraints(maxWidth: 560),
      contentPadding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      title: Text(strings.quickNote),
      content: SizedBox(
        width: MediaQuery.sizeOf(dialogContext).width - 64,
        child: TextField(
          key: const ValueKey('quick-note-comfort-field'),
          controller: controller,
          autofocus: true,
          minLines: 5,
          maxLines: 8,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: strings.writeQuickly,
            alignLabelWithHint: true,
          ),
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
  final accountAtCaptureOpen = store.activeAccountId;
  final counts = await Qw2UiSettings.captureCounts(store);
  if (!context.mounted ||
      store.activeAccountId != accountAtCaptureOpen) {
    return;
  }
  final availableActions =
      <({IconData icon, String title, String? subtitle,
          _UnifiedCaptureAction action})>[
    (icon: Icons.edit_note_outlined, title: strings.writeMoment,
     subtitle: strings.addDiaryNote(dayLabel),
     action: _UnifiedCaptureAction.text),
    (icon: Icons.photo_camera_back_outlined, title: strings.photo,
     subtitle: strings.savePhotoMoment(dayLabel),
     action: _UnifiedCaptureAction.photo),
    (icon: Icons.check_circle_outline, title: strings.task,
     subtitle: null, action: _UnifiedCaptureAction.task),
    (icon: Icons.auto_awesome_motion_outlined,
     title: _annaCaptureProposalLabel(strings.languageCode, 'taskFromText'),
     subtitle: null, action: _UnifiedCaptureAction.taskFromText),
    (icon: Icons.playlist_add_check_outlined,
     title: _annaCaptureProposalLabel(strings.languageCode, 'checklistFromNote'),
     subtitle: null, action: _UnifiedCaptureAction.checklistFromNote),
    (icon: Icons.mic_none_outlined, title: strings.voiceNote,
     subtitle: strings.recordDiaryAudio(dayLabel),
     action: _UnifiedCaptureAction.voice),
    (icon: Icons.draw_outlined, title: strings.v100Sketch,
     subtitle: null, action: _UnifiedCaptureAction.sketch),
    (icon: Icons.inbox_outlined, title: strings.quickInboxNote,
     subtitle: strings.organizeLater, action: _UnifiedCaptureAction.inbox),
    (icon: Icons.event_outlined, title: strings.appointment,
     subtitle: null, action: _UnifiedCaptureAction.event),
    (icon: Icons.cake_outlined, title: strings.birthday,
     subtitle: null, action: _UnifiedCaptureAction.birthday),
    (icon: Icons.person_add_alt_1_outlined, title: strings.importantPerson,
     subtitle: null, action: _UnifiedCaptureAction.person),
    (icon: Icons.library_books_outlined, title: strings.d3('templates'),
     subtitle: null, action: _UnifiedCaptureAction.templates),
  ];
  final rankedActions = qw2RankCaptureActions(
      availableActions, counts, (choice) => choice.action.name);
  String? subtitleFor(_UnifiedCaptureAction selected, String? fallback) =>
      switch (selected) {
        _UnifiedCaptureAction.text => strings.addDiaryNote(dayLabel),
        _UnifiedCaptureAction.photo => strings.savePhotoMoment(dayLabel),
        _UnifiedCaptureAction.voice => strings.recordDiaryAudio(dayLabel),
        _ => fallback,
      };

  final action = await showModalBottomSheet<_UnifiedCaptureAction>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    sheetAnimationStyle: AnimationStyle(
      duration: AnnaMotionV108.duration(context, 416),
      reverseDuration: AnnaMotionV108.duration(context, 220),
    ),
    builder: (sheetContext) {
      var showAllActions = false;

      Widget actionTile({
        required IconData icon,
        required String title,
        String? subtitle,
        required _UnifiedCaptureAction action,
        bool primary = false,
        int order = 0,
      }) {
        final tile = ListTile(
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
        return AnnaMotionStagger(
          key: ValueKey<String>('v108-capture-action-${action.name}'),
          order: order,
          fan: primary,
          captureCascade: true,
          child: tile,
        );
      }

      return StatefulBuilder(
        builder: (context, setSheetState) {
          final animate = AnnaDesignTokens.animationsEnabled(context);
          final effectiveDateText = _cap(DateFormat(
            'EEEE d MMMM yyyy',
            AnnaStrings.intlLocale(sheetContext),
          ).format(targetDay));
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
                      title: AnnaEditorialTodayMode.enabled.value
                          ? AnnaEditorialDateLabel(
                              key: const ValueKey<String>(
                                  'capture-editorial-effective-date'),
                              text: effectiveDateText,
                            )
                          : Text(effectiveDateText),
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
                  // Four most chosen capture actions, sorted locally.
                  for (var i = 0; i < 4; i++)
                    actionTile(
                      icon: rankedActions[i].icon,
                      title: rankedActions[i].title,
                      subtitle: subtitleFor(
                          rankedActions[i].action, rankedActions[i].subtitle),
                      action: rankedActions[i].action,
                      primary: true,
                      order: i,
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
                              ? const Duration(milliseconds: 300)
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
                        ? const Duration(milliseconds: 320)
                        : Duration.zero,
                    curve: Curves.easeInOutCubic,
                    alignment: Alignment.topCenter,
                    child: showAllActions
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Divider(height: 1),
                              for (var i = 4; i < rankedActions.length; i++)
                                actionTile(
                                  icon: rankedActions[i].icon,
                                  title: rankedActions[i].title,
                                  subtitle: subtitleFor(
                          rankedActions[i].action, rankedActions[i].subtitle),
                                  action: rankedActions[i].action,
                                  order: i - 4,
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

  if (!context.mounted || action == null ||
      store.activeAccountId != accountAtCaptureOpen) {
    return;
  }
  // Counts represent deliberate action selections, never personal content.
  unawaited(Qw2UiSettings.recordCaptureChoice(
      store, action.name, accountAtCaptureOpen));

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
      if (!context.mounted) return;
      AnnaMotionV108.showSaveSuccess(context);
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
            AnnaMotionV108.showSaveSuccess(context);
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
      if (!context.mounted) return;
      AnnaMotionV108.showSaveSuccess(context);
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
      if (!context.mounted) return;
      AnnaMotionV108.showSaveSuccess(context);
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
      if (!context.mounted) return;
      AnnaMotionV108.showSaveSuccess(context);
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
      if (!context.mounted) return;
      unawaited(AnnaFeedback.success());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.inboxSaved)),
        );
      }
      return;

    case _UnifiedCaptureAction.taskFromText:
      final phrase = await _askLocalTaskSentence(context);
      if (phrase == null || !context.mounted ||
          store.activeAccountId != accountAtCaptureOpen) { return; }
      final proposal = annaProposeTaskFromText(
        phrase, selectedDay: targetDay,
        languageCode: strings.languageCode, now: DateTime.now());
      if (proposal == null) return;
      // Explicit editor Save owns writes, account checks and reminders.
      await openItemEditor(context, store, proposal.date,
        initialType: ItemType.task, duplicateOf: proposal.toEditorDraft());
      return;

    case _UnifiedCaptureAction.checklistFromNote:
      final selected = await _pickLocalChecklistNote(context, store, targetDay);
      if (selected == null || !context.mounted ||
          store.activeAccountId != accountAtCaptureOpen) { return; }
      final current = store.journal(selected.date).blocks
          .where((b) => b.id == selected.block.id).toList(growable: false);
      if (current.length != 1 || current.single.archived ||
          current.single.type != DiaryBlockType.note ||
          current.single.text != selected.block.text) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_annaCaptureProposalLabel(
              strings.languageCode, 'staleSource'))));
        return;
      }
      final draft = annaProposeChecklistFromDiary(
        current.single.text, targetDay: targetDay);
      if (draft == null) return;
      await openItemEditor(context, store, targetDay,
        initialType: ItemType.task, duplicateOf: draft.toEditorDraft());
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
