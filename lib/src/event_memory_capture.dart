part of '../main.dart';

bool canCaptureEventMemory(AgendaItem item, DateTime now) {
  if (item.type != ItemType.appointment || item.title.trim().isEmpty) return false;
  final eventDay = DateTime(item.date.year, item.date.month, item.date.day);
  final today = DateTime(now.year, now.month, now.day);
  return eventDay.isBefore(today);
}

String eventMemoryBlockId(AgendaItem item) {
  final digest = sha256.convert(utf8.encode(
    'anna:v107:event-memory:${item.id}:${AgendaStore.dateKey(item.date)}',
  )).toString();
  return 'event-memory-${digest.substring(0, 32)}';
}

String eventMemoryDraftText(
  AgendaItem item, {
  required String locale,
  required String sourceLabel,
}) {
  final date = DateFormat.yMd(locale).format(item.date);
  final time = item.start == null ? '' : ' ${formatTime(item.start!)}';
  final reference = '$sourceLabel: ${item.title.trim()} · $date$time';
  final note = item.note.trim();
  return note.isEmpty ? '$reference\n\n' : '$reference\n\n$note\n\n';
}


/// Protect both a deleted block and a deleted whole day. Recreating either
/// canonical identity would make the original Trash entry unrestorable.
bool eventMemoryHasRecoverableTrash(AgendaStore store, AgendaItem item) {
  final day = AgendaStore.dateKey(item.date);
  final id = eventMemoryBlockId(item);
  return store.trash.any((entry) =>
      (entry.kind == TrashEntityKind.diaryBlock &&
          entry.entityId == id && entry.parentId == day) ||
      (entry.kind == TrashEntityKind.journal && entry.entityId == day));
}

final Set<String> _eventMemoryWritesInFlight = <String>{};

Future<bool> saveEventMemoryDraft(
  AgendaStore store,
  AgendaItem item,
  String text, {
  DateTime? now,
  String? expectedAccountId,
}) async {
  if (!canCaptureEventMemory(item, now ?? DateTime.now()) ||
      store.activeAccountId != expectedAccountId || text.trim().isEmpty) {
    return false;
  }
  final exists = store.items.any((current) =>
      current.id == item.id &&
      current.type == ItemType.appointment &&
      AgendaStore.sameDay(current.date, item.date));
  if (!exists || eventMemoryHasRecoverableTrash(store, item)) return false;

  final id = eventMemoryBlockId(item);
  if (!_eventMemoryWritesInFlight.add(id)) return false;
  try {
    final day = DateTime(item.date.year, item.date.month, item.date.day);
    final journal = store.journal(day);
    final blocks = [...journal.blocks];
    final index = blocks.indexWhere((block) => block.id == id);
    if (index >= 0) {
      blocks[index] = blocks[index].copyWith(text: text.trim());
    } else {
      blocks.add(DiaryBlock(
        id: id,
        type: DiaryBlockType.note,
        createdAt: _unifiedCaptureTimestamp(day),
        text: text.trim(),
      ));
    }
    await store.saveJournal(day, journal.copyWith(blocks: blocks));
    return true;
  } finally {
    _eventMemoryWritesInFlight.remove(id);
  }
}


/// No write until the person confirms an editable note. The original
/// appointment is never altered and only private events are eligible.
Future<void> openEventMemoryDraft(
  BuildContext context,
  AgendaStore store,
  AgendaItem item,
) async {
  if (!canCaptureEventMemory(item, DateTime.now())) return;
  if (eventMemoryHasRecoverableTrash(store, item)) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(AnnaStrings.of(context).d3('v107MemoryInTrash')),
    ));
    return;
  }
  final accountAtStart = store.activeAccountId;
  final id = eventMemoryBlockId(item);
  final candidates = store.journal(item.date).blocks
      .where((block) => block.id == id);
  final existing = candidates.isEmpty ? null : candidates.first;
  final strings = AnnaStrings.of(context);
  var draft = await showDiaryNoteEditor(
    context,
    initialText: existing?.text ??
        eventMemoryDraftText(
          item,
          locale: AnnaStrings.intlLocale(context),
          sourceLabel: strings.d3('v107EventMemorySource'),
        ),
    editing: existing != null,
  );
  while (draft != null && draft.trim().isNotEmpty) {
    if (!context.mounted) return;
    if (store.activeAccountId != accountAtStart) {
      // Fail closed on account switch; never display old account content
      // in a new account's editable surface.
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AnnaStrings.of(context).d3('v107EventMemoryAccountChanged')),
      ));
      return;
    }
    try {
      final saved = await saveEventMemoryDraft(
        store, item, draft, expectedAccountId: accountAtStart,
      );
      if (!context.mounted) return;
      if (!saved) {
        final key = eventMemoryHasRecoverableTrash(store, item)
            ? 'v107MemoryInTrash'
            : 'v107EventMemorySourceChanged';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AnnaStrings.of(context).d3(key)),
        ));
        // Keep submitted text editable and copyable; do not bypass source
        // checks, silently save elsewhere or discard the user's draft.
        draft = await showDiaryNoteEditor(
          context, initialText: draft, editing: true,
        );
        continue;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AnnaStrings.of(context).d3('v107EventMemorySaved')),
      ));
      return;
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AnnaStrings.of(context).d3('v107EventMemorySaveFailed')),
      ));
      draft = await showDiaryNoteEditor(context, initialText: draft!);
    }
  }
}
