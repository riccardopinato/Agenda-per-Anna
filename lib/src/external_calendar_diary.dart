part of '../main.dart';

/// A read-only correspondence report. External providers never own the diary.
enum ExternalDiaryMatchState {
  unavailable,
  recoverableTrash,
  linked,
  reviewCandidates,
  unlinked,
}

class ExternalDiaryCorrespondence {
  final ExternalDiaryMatchState state;
  final int candidateCount;
  const ExternalDiaryCorrespondence(this.state, {this.candidateCount = 0});

  bool get canCapture =>
      state == ExternalDiaryMatchState.linked ||
      state == ExternalDiaryMatchState.reviewCandidates ||
      state == ExternalDiaryMatchState.unlinked;
}

/// Provider occurrence + calendar namespace prevents accidental overlap with
/// native Anna appointments. The ID lives only in the existing DayJournal.
String externalCalendarMemoryBlockId(ExternalCalendarEvent event) {
  final digest = sha256.convert(utf8.encode(
    'anna:external-calendar:diary:v1:${event.calendarId}:${event.id}:'
    '${AgendaStore.dateKey(event.date)}',
  )).toString();
  return 'external-calendar-memory-${digest.substring(0, 32)}';
}

bool canCaptureExternalCalendarMemory(ExternalCalendarEvent event, DateTime now) {
  if (event.title.trim().isEmpty) return false;
  final today = DateTime(now.year, now.month, now.day);
  return event.date.isBefore(today);
}

bool externalCalendarMemoryHasRecoverableTrash(
  AgendaStore store, ExternalCalendarEvent event,
) {
  final day = AgendaStore.dateKey(event.date);
  final id = externalCalendarMemoryBlockId(event);
  return store.trash.any((entry) =>
      (entry.kind == TrashEntityKind.diaryBlock &&
          entry.entityId == id && entry.parentId == day) ||
      (entry.kind == TrashEntityKind.journal && entry.entityId == day));
}

/// Candidates are a *warning*, never a proven link or an automatic merge.
/// A minimum title length avoids presenting generic short words as matches.
List<DiaryBlock> externalCalendarDiaryCandidates(
  AgendaStore store, ExternalCalendarEvent event,
) {
  final title = event.title.trim().toLowerCase().replaceAll(
    RegExp(r'\s+'), ' ',
  );
  if (title.length < 6) return const <DiaryBlock>[];
  final linkedId = externalCalendarMemoryBlockId(event);
  return List<DiaryBlock>.unmodifiable(store.journal(event.date).blocks.where(
    (block) => block.type == DiaryBlockType.note &&
        block.id != linkedId &&
        block.text.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').contains(title),
  ));
}

ExternalDiaryCorrespondence externalCalendarDiaryCorrespondence(
  AgendaStore store,
  ExternalCalendarEvent event, {
  DateTime? now,
}) {
  if (!store.entryScopeReady ||
      !canCaptureExternalCalendarMemory(event, now ?? DateTime.now())) {
    return const ExternalDiaryCorrespondence(
      ExternalDiaryMatchState.unavailable,
    );
  }
  if (externalCalendarMemoryHasRecoverableTrash(store, event)) {
    return const ExternalDiaryCorrespondence(
      ExternalDiaryMatchState.recoverableTrash,
    );
  }
  final id = externalCalendarMemoryBlockId(event);
  if (store.journal(event.date).blocks.any((block) => block.id == id)) {
    return const ExternalDiaryCorrespondence(ExternalDiaryMatchState.linked);
  }
  final count = externalCalendarDiaryCandidates(store, event).length;
  if (count > 0) {
    return ExternalDiaryCorrespondence(
      ExternalDiaryMatchState.reviewCandidates, candidateCount: count,
    );
  }
  return const ExternalDiaryCorrespondence(ExternalDiaryMatchState.unlinked);
}

String externalDiaryCopy(AnnaStrings strings, String key) {
  const copy = <String, List<String>>{
    'linked': ['Linked to your diary', 'Collegato al diario', 'Vinculado al diario', 'Associé au journal', 'Ligado ao diário'],
    'none': ['No linked diary memory', 'Nessun ricordo collegato', 'Ningún recuerdo vinculado', 'Aucun souvenir associé', 'Nenhuma memória ligada'],
    'review': ['{count} possible diary matches. Review before creating another.', '{count} possibili corrispondenze nel diario. Controlla prima di creare un altro ricordo.', '{count} posibles coincidencias. Revísalas antes de crear otro recuerdo.', '{count} correspondances possibles. Vérifiez avant de créer un autre souvenir.', '{count} possíveis correspondências. Reveja antes de criar outra memória.'],
    'unavailable': ['Past events only: no automatic memories', 'Solo eventi passati: nessun ricordo automatico', 'Solo eventos pasados; sin recuerdos automáticos', 'Événements passés uniquement, sans souvenir automatique', 'Apenas eventos passados, sem memórias automáticas'],
    'trash': ['A linked memory is in Trash. Restore it before editing.', 'Un ricordo collegato è nel Cestino. Ripristinalo prima di modificarlo.', 'Un recuerdo vinculado está en la papelera. Restáuralo antes.', 'Un souvenir associé est dans la corbeille. Restaurez-le.', 'Uma memória ligada está no lixo. Restaure-a primeiro.'],
    'create': ['Create diary memory', 'Crea ricordo nel diario', 'Crear recuerdo en el diario', 'Créer un souvenir', 'Criar memória no diário'],
    'edit': ['Edit linked memory', 'Modifica ricordo collegato', 'Editar recuerdo vinculado', 'Modifier le souvenir associé', 'Editar memória ligada'],
    'reviewTitle': ['Possible existing memories', 'Possibili ricordi già presenti', 'Posibles recuerdos existentes', 'Souvenirs peut-être déjà présents', 'Possíveis memórias existentes'],
    'reviewBody': ['A diary note may already describe this event. Nothing will be merged or deleted. Review your notes before saving a separate memory.', 'Una nota del diario potrebbe già descrivere questo evento. Non verrà unito o eliminato nulla. Controlla prima di salvare un ricordo separato.', 'Una nota podría describir este evento. Nada se fusionará ni eliminará automáticamente.', 'Une note décrit peut-être cet événement. Aucune fusion ni suppression automatique.', 'Uma nota pode descrever este evento. Nada será unido ou eliminado automaticamente.'],
    'continue': ['Continue to draft', 'Continua con la bozza', 'Continuar al borrador', 'Continuer vers le brouillon', 'Continuar para rascunho'],
    'source': ['From external calendar', 'Dal calendario esterno', 'Del calendario externo', 'Depuis un calendrier externe', 'Do calendário externo'],
    'saved': ['Memory saved in your diary', 'Ricordo salvato nel diario', 'Recuerdo guardado en el diario', 'Souvenir enregistré', 'Memória guardada no diário'],
    'failed': ['Could not save. Your draft is still editable.', 'Salvataggio non riuscito. Puoi ancora modificare la bozza.', 'Error al guardar. Puedes editar el borrador.', 'Enregistrement impossible. Le brouillon reste modifiable.', 'Falha ao guardar. O rascunho continua editável.'],
    'changed': ['Diary/account changed. Your draft was not saved.', 'Diario o account cambiato. La bozza non è stata salvata.', 'Diario o cuenta cambiado. No se guardó el borrador.', 'Journal ou compte modifié. Brouillon non enregistré.', 'Diário ou conta alterado. Rascunho não guardado.'],
  };
  final index = switch (strings.languageCode) {
    'it' => 1, 'es' => 2, 'fr' => 3, 'pt' => 4, _ => 0,
  };
  return copy[key]![index];
}

String externalCalendarMemoryDraftText(
  ExternalCalendarEvent event, {
  required String locale,
  required String sourceLabel,
}) {
  final date = DateFormat.yMd(locale).format(event.date);
  final time = event.allDay ? '' : ' ${formatTime(event.startTime!)}';
  final lines = <String>[
    '$sourceLabel: ${event.title.trim()} · $date$time',
  ];
  if (event.location.trim().isNotEmpty) lines.add(event.location.trim());
  // Android B3 provenance markers are transport metadata, not diary prose.
  final description = event.description.replaceAll(
    RegExp(r'\[AnnaDiary:[^\]]*\]'), '',
  ).trim();
  if (description.isNotEmpty) lines.add(description);
  return '${lines.join('\n')}\n\n';
}

final Set<String> _externalDiaryWritesInFlight = <String>{};

/// Writes only to Anna's existing account-scoped DayJournal, after explicit
/// confirmation in the note editor. Never invokes a Google/device write API.
Future<bool> saveExternalCalendarMemoryDraft(
  AgendaStore store,
  ExternalCalendarEvent event,
  String text, {
  DateTime? now,
  String? expectedAccountId,
}) async {
  if (!store.entryScopeReady ||
      store.activeAccountId != expectedAccountId ||
      !canCaptureExternalCalendarMemory(event, now ?? DateTime.now()) ||
      text.trim().isEmpty ||
      externalCalendarMemoryHasRecoverableTrash(store, event)) {
    return false;
  }
  final id = externalCalendarMemoryBlockId(event);
  final writeKey = '${expectedAccountId ?? 'local'}:$id';
  if (!_externalDiaryWritesInFlight.add(writeKey)) return false;
  try {
    // Re-check after entering the write gate; a concurrent account switch
    // must never write into a different user's journal.
    if (!store.entryScopeReady || store.activeAccountId != expectedAccountId) {
      return false;
    }
    final day = event.date;
    final journal = store.journal(day);
    final blocks = [...journal.blocks];
    final index = blocks.indexWhere((block) => block.id == id);
    if (index >= 0) {
      blocks[index] = blocks[index].copyWith(text: text.trim());
    } else {
      blocks.add(DiaryBlock(
        id: id,
        type: DiaryBlockType.note,
        createdAt: DateTime(day.year, day.month, day.day, 12),
        text: text.trim(),
      ));
    }
    await store.saveJournal(day, journal.copyWith(blocks: blocks));
    return true;
  } finally {
    _externalDiaryWritesInFlight.remove(writeKey);
  }
}

/// The source remains read-only. Possible duplicates require an explicit
/// user review; nothing is silently imported, synchronized or removed.
Future<void> openExternalCalendarMemoryDraft(
  BuildContext context,
  AgendaStore store,
  ExternalCalendarEvent event,
) async {
  var match = externalCalendarDiaryCorrespondence(store, event);
  if (!match.canCapture) return;
  final originalAccount = store.activeAccountId;
  if (match.state == ExternalDiaryMatchState.reviewCandidates) {
    final strings = AnnaStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(externalDiaryCopy(strings, 'reviewTitle')),
        content: Text(externalDiaryCopy(strings, 'reviewBody')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            key: const ValueKey('external-diary-review-continue'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(externalDiaryCopy(strings, 'continue')),
          ),
        ],
      ),
    ) ?? false;
    if (!confirmed || !context.mounted) return;
  }
  if (store.activeAccountId != originalAccount || !store.entryScopeReady) {
    return;
  }
  final id = externalCalendarMemoryBlockId(event);
  final matches = store.journal(event.date).blocks.where(
    (block) => block.id == id,
  );
  final existing = matches.isEmpty ? null : matches.first;
  final strings = AnnaStrings.of(context);
  var draft = await showDiaryNoteEditor(
    context,
    initialText: existing?.text ?? externalCalendarMemoryDraftText(
      event,
      locale: AnnaStrings.intlLocale(context),
      sourceLabel: externalDiaryCopy(strings, 'source'),
    ),
    editing: existing != null,
  );
  while (draft != null && draft.trim().isNotEmpty) {
    if (!context.mounted) return;
    match = externalCalendarDiaryCorrespondence(store, event);
    if (store.activeAccountId != originalAccount ||
        !store.entryScopeReady ||
        !match.canCapture) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(externalDiaryCopy(AnnaStrings.of(context), 'changed')),
      ));
      return;
    }
    try {
      final saved = await saveExternalCalendarMemoryDraft(
        store, event, draft, expectedAccountId: originalAccount,
      );
      if (!context.mounted) return;
      if (saved) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(externalDiaryCopy(AnnaStrings.of(context), 'saved')),
        ));
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(externalDiaryCopy(AnnaStrings.of(context), 'failed')),
      ));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(externalDiaryCopy(AnnaStrings.of(context), 'failed')),
      ));
    }
    // Do not discard the user's draft on failed persistence.
    draft = await showDiaryNoteEditor(context, initialText: draft, editing: true);
  }
}
