import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agenda_per_anna/local_state_store.dart';
import 'package:agenda_per_anna/main.dart';
import 'package:agenda_per_anna/media_asset_store.dart';

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

  test('agenda delete is recoverable and restore preserves the original item',
      () async {
    final store = AgendaStore();
    await store.load();
    final item = AgendaItem(
      id: 'trash-item',
      title: 'Visita',
      note: 'Da recuperare',
      date: DateTime(2026, 10, 2),
      type: ItemType.task,
      start: const TimeOfDay(hour: 9, minute: 30),
      reminderMinutesBefore: 30,
    );
    await store.upsert(item);

    await store.deleteItem(item.id);

    expect(store.items.any((value) => value.id == item.id), isFalse);
    expect(store.trash, hasLength(1));
    expect(store.trash.single.kind, TrashEntityKind.item);
    expect(store.trash.single.payload['title'], 'Visita');

    expect(await store.restoreTrashEntry(store.trash.single.id), isTrue);
    expect(store.trash, isEmpty);
    expect(
      store.items.singleWhere((value) => value.id == item.id).note,
      'Da recuperare',
    );

    store.dispose();
  });

  test('diary block Trash keeps media references and restores in place',
      () async {
    final store = AgendaStore();
    await store.load();
    final date = DateTime(2026, 10, 3);
    final block = DiaryBlock(
      id: 'photo-block',
      type: DiaryBlockType.photo,
      createdAt: DateTime(2026, 10, 3, 18),
      text: 'Foto',
      mediaAssetId: 'sha256_fake_full',
      mediaThumbnailAssetId: 'sha256_fake_thumb',
    );
    await store.saveJournal(date, DayJournal(blocks: [block]));

    expect(await store.moveDiaryBlockToTrash(date, block.id), isTrue);
    expect(store.journal(date).blocks, isEmpty);
    expect(store.trash.single.payload['mediaAssetId'], 'sha256_fake_full');

    expect(await store.restoreTrashEntry(store.trash.single.id), isTrue);
    expect(store.journal(date).blocks.single.id, block.id);
    expect(
      store.journal(date).blocks.single.mediaThumbnailAssetId,
      'sha256_fake_thumb',
    );

    store.dispose();
  });

  test('habit lifecycle restores historical completion links', () async {
    final store = AgendaStore();
    await store.load();
    await store.addHabit('Camminare');
    final habit = store.habits.last;
    final date = DateTime(2026, 10, 4);
    await store.toggleHabit(date, habit.id);
    expect(store.journal(date).completedHabitIds, contains(habit.id));

    await store.removeHabit(habit.id);

    expect(store.habits.any((value) => value.id == habit.id), isFalse);
    expect(store.journal(date).completedHabitIds, isNot(contains(habit.id)));
    final trashed = store.trash.singleWhere(
      (entry) => entry.kind == TrashEntityKind.habit,
    );

    expect(await store.restoreTrashEntry(trashed.id), isTrue);
    expect(store.habits.any((value) => value.id == habit.id), isTrue);
    expect(store.journal(date).completedHabitIds, contains(habit.id));

    store.dispose();
  });

  test('Trash survives process-style restart', () async {
    final first = AgendaStore();
    await first.load();
    await first.addInboxEntry('Da recuperare');
    final id = first.inbox.single.id;
    await first.deleteInboxEntry(id);
    expect(first.trash, hasLength(1));
    first.dispose();

    final second = AgendaStore();
    await second.load();
    expect(second.inbox, isEmpty);
    expect(second.trash, hasLength(1));
    expect(second.trash.single.kind, TrashEntityKind.inbox);
    expect(second.trash.single.payload['text'], 'Da recuperare');
    second.dispose();
  });

  test('backup reports Trash and permanent purge creates safety snapshot',
      () async {
    final store = AgendaStore();
    await store.load();
    await store.addInboxEntry('Definitivo');
    await store.deleteInboxEntry(store.inbox.single.id);

    final summary = store.inspectBackup(await store.createBackupJson());
    expect(summary.trashCount, 1);

    final trashId = store.trash.single.id;
    expect(await store.purgeTrashEntry(trashId), isTrue);
    expect(store.trash, isEmpty);
    expect(store.localSnapshots, isNotEmpty);
    expect(store.localSnapshots.first.label, contains('Cestino'));

    store.dispose();
  });
}
