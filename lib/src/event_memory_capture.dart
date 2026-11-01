part of '../main.dart';

bool canCaptureEventMemory(AgendaItem item, DateTime now) {
  if (item.type != ItemType.appointment || item.title.trim().isEmpty) return false;
  final eventDay = DateTime(item.date.year, item.date.month, item.date.day);
  final today = DateTime(now.year, now.month, now.day);
  return eventDay.isBefore(today);
}

String eventMemoryBlockId(AgendaItem item) {
  final digest = sha256.convert(utf8.encode(
    'anna:v107:event-memory:' + item.id + ':' + AgendaStore.dateKey(item.date),
  )).toString();
  return 'event-memory-' + digest.substring(0, 32);
}

String eventMemoryDraftText(
  AgendaItem item, {
  required String locale,
  required String sourceLabel,
}) {
  final date = DateFormat.yMd(locale).format(item.date);
  final time = item.start == null ? '' : ' ' + formatTime(item.start!);
  final reference = sourceLabel + ': ' + item.title.trim() + ' · ' + date + time;
  final note = item.note.trim();
  return note.isEmpty ? reference + '\n\n' : reference + '\n\n' + note + '\n\n';
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
  if (!exists) return false;

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
