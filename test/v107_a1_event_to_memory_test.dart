import 'dart:io';

import 'package:agenda_per_anna/local_state_store.dart';
import 'package:agenda_per_anna/main.dart';
import 'package:agenda_per_anna/media_asset_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    await LocalStateStore.instance.resetForTesting();
    await MediaAssetStore.instance.resetForTesting();
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() async {
    await LocalStateStore.instance.resetForTesting();
    await MediaAssetStore.instance.resetForTesting();
  });

  AgendaItem appointment({
    String id = 'event-1',
    DateTime? date,
    ItemType type = ItemType.appointment,
  }) => AgendaItem(
        id: id,
        title: 'Dentist',
        note: 'Bring documents',
        date: date ?? DateTime(2026, 10, 18),
        type: type,
        start: const TimeOfDay(hour: 17, minute: 30),
      );

  test('Eligibility excludes same day, future and tasks', () {
    expect(canCaptureEventMemory(appointment(), DateTime(2026, 11, 1)), isTrue);
    expect(canCaptureEventMemory(appointment(), DateTime(2026, 10, 18, 23)), isFalse);
    expect(canCaptureEventMemory(appointment(date: DateTime(2026, 11, 2)), DateTime(2026, 11, 1)), isFalse);
    expect(canCaptureEventMemory(appointment(type: ItemType.task), DateTime(2026, 11, 1)), isFalse);
    expect(eventMemoryBlockId(appointment()), eventMemoryBlockId(appointment()));
    expect(eventMemoryBlockId(appointment(id: 'different')), isNot(eventMemoryBlockId(appointment())));
  });

  test('Context is editable text without automatic persistence', () {
    final draft = eventMemoryDraftText(
      appointment(), locale: 'en', sourceLabel: 'From appointment',
    );
    expect(draft, contains('Dentist'));
    expect(draft, contains('Bring documents'));
    expect(draft, contains('17:30'));
    expect(draft, contains('10/18/2026'));
  });

  test('Saves once in existing DayJournal; edit keeps ID and other notes', () async {
    final store = AgendaStore();
    await store.load();
    final item = appointment();
    await store.upsert(item);
    final initialEvent = store.items.single.toJson();
    await store.saveJournal(item.date, DayJournal(blocks: [
      DiaryBlock(
        id: 'unrelated',
        type: DiaryBlockType.note,
        createdAt: item.date,
        text: 'Personal note',
      ),
    ]));
    expect(await saveEventMemoryDraft(
      store, item, 'A happy moment',
      now: DateTime(2026, 11, 1),
      expectedAccountId: store.activeAccountId,
    ), isTrue);
    expect(await saveEventMemoryDraft(
      store, item, 'An edited memory',
      now: DateTime(2026, 11, 1),
      expectedAccountId: store.activeAccountId,
    ), isTrue);
    final blocks = store.journal(item.date).blocks;
    expect(blocks.length, 2);
    expect(blocks.first.text, 'Personal note');
    expect(blocks.last.id, eventMemoryBlockId(item));
    expect(blocks.last.text, 'An edited memory');
    expect(store.items.single.toJson(), initialEvent);
    expect(store.memoryReferences().any(
      (memory) => memory.block.id == eventMemoryBlockId(item),
    ), isTrue);
    store.dispose();
  });

  test('Invalid source, account and date never mutate journal', () async {
    final store = AgendaStore();
    await store.load();
    final item = appointment();
    expect(await saveEventMemoryDraft(store, item, 'Missing',
      now: DateTime(2026, 11, 1)), isFalse);
    await store.upsert(item);
    expect(await saveEventMemoryDraft(store, item, 'Wrong account',
      now: DateTime(2026, 11, 1),
      expectedAccountId: 'some-other-account'), isFalse);
    expect(await saveEventMemoryDraft(store, item, 'Future',
      now: DateTime(2026, 10, 17),
      expectedAccountId: store.activeAccountId), isFalse);
    expect(await saveEventMemoryDraft(store, item, '  ',
      now: DateTime(2026, 11, 1),
      expectedAccountId: store.activeAccountId), isFalse);
    expect(store.journal(item.date).blocks, isEmpty);
    store.dispose();
  });

  test('Uses common private event action sheet, not duplicate store', () {
    final planner = File('lib/src/planner_views.dart').readAsStringSync();
    final helper = File('lib/src/event_memory_capture.dart').readAsStringSync();
    final main = File('lib/main.dart').readAsStringSync();
    expect(main, contains("part 'src/event_memory_capture.dart';"));
    expect(planner, contains("'v107-event-to-memory-action'"));
    expect(planner, contains('openEventMemoryDraft(context, store, item)'));
    expect(helper, contains('showDiaryNoteEditor('));
    expect(helper, contains('store.saveJournal('));
    expect(helper, isNot(contains('CloudSyncService')));
  });

  test('A deleted memory keeps its original ID recoverable from Trash', () async {
    final store = AgendaStore();
    await store.load();
    final item = appointment();
    await store.upsert(item);
    expect(await saveEventMemoryDraft(
      store, item, 'Original memory', now: DateTime(2026, 11, 1),
      expectedAccountId: store.activeAccountId,
    ), isTrue);
    final id = eventMemoryBlockId(item);
    expect(await store.moveDiaryBlockToTrash(item.date, id), isTrue);
    expect(eventMemoryHasRecoverableTrash(store, item), isTrue);
    expect(await saveEventMemoryDraft(
      store, item, 'Replacement', now: DateTime(2026, 11, 1),
      expectedAccountId: store.activeAccountId,
    ), isFalse);
    final deleted = store.trash.firstWhere((e) => e.entityId == id);
    expect(store.trashRestoreConflictReason(deleted), isNull);
    expect(await store.restoreTrashEntry(deleted.id), isTrue);
    expect(store.journal(item.date).blocks.single.text, 'Original memory');
    store.dispose();
  });

  test('An entire trashed day cannot be shadowed by a new event memory', () async {
    final store = AgendaStore();
    await store.load();
    final item = appointment();
    await store.upsert(item);
    await store.saveJournal(item.date, DayJournal(blocks: [
      DiaryBlock(id: 'previous-day', type: DiaryBlockType.note,
        createdAt: item.date, text: 'An existing memory'),
    ]));
    expect(await store.moveJournalToTrash(item.date), isTrue);
    expect(eventMemoryHasRecoverableTrash(store, item), isTrue);
    expect(await saveEventMemoryDraft(
      store, item, 'Replacement', now: DateTime(2026, 11, 1),
      expectedAccountId: store.activeAccountId,
    ), isFalse);
    final deleted = store.trash.firstWhere(
      (e) => e.kind == TrashEntityKind.journal &&
        e.entityId == AgendaStore.dateKey(item.date),
    );
    expect(store.trashRestoreConflictReason(deleted), isNull);
    expect(await store.restoreTrashEntry(deleted.id), isTrue);
    expect(store.journal(item.date).blocks.single.text, 'An existing memory');
    store.dispose();
  });

  test('A source removed after drafting fails closed and draft recovery remains wired', () async {
    final store = AgendaStore();
    await store.load();
    final item = appointment();
    await store.upsert(item);
    await store.deleteItem(item.id);
    expect(await saveEventMemoryDraft(
      store, item, 'Draft after source deletion',
      now: DateTime(2026, 11, 1),
      expectedAccountId: store.activeAccountId,
    ), isFalse);
    expect(store.journal(item.date).blocks, isEmpty);
    final source = File('lib/src/event_memory_capture.dart').readAsStringSync();
    expect(source, contains("'v107EventMemorySourceChanged'"));
    expect(source, contains('draft = await showDiaryNoteEditor('));
    store.dispose();
  });

}
