import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agenda_per_anna/local_state_store.dart';
import 'package:agenda_per_anna/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('account working sets stay isolated on the same device', () async {
    final store = AgendaStore();
    await store.load();

    await store.addInboxEntry('Dato ospite');
    await store.activateCloudAccount('user-a');

    expect(store.activeAccountId, 'user-a');
    expect(store.inbox.map((e) => e.text), contains('Dato ospite'));

    await store.addInboxEntry('Solo A');
    await store.activateCloudAccount('user-b');

    expect(store.activeAccountId, 'user-b');
    expect(store.inbox, isEmpty);

    await store.addInboxEntry('Solo B');
    await store.activateCloudAccount('user-a');

    expect(store.inbox.map((e) => e.text), contains('Dato ospite'));
    expect(store.inbox.map((e) => e.text), contains('Solo A'));
    expect(store.inbox.map((e) => e.text), isNot(contains('Solo B')));

    await store.activateCloudAccount('user-b');
    expect(store.inbox.map((e) => e.text), contains('Solo B'));
    expect(store.inbox.map((e) => e.text), isNot(contains('Solo A')));
  });

  test('corrupt section does not block healthy sections or get overwritten',
      () async {
    SharedPreferences.setMockInitialValues({
      'items_v1': '{not valid json',
      'journals_v1': jsonEncode({
        '2026-09-21': const DayJournal(
          beautiful: 'Una bella giornata',
        ).toJson(),
      }),
      'habits_v1': jsonEncode(<Object>[]),
    });

    final store = AgendaStore();
    await store.load();

    expect(store.hasStorageWarnings, isTrue);
    expect(store.items, isEmpty);
    expect(
      store.journal(DateTime(2026, 9, 21)).beautiful,
      'Una bella giornata',
    );
    expect(store.habits, isEmpty);

    await store.saveJournal(
      DateTime(2026, 9, 22),
      const DayJournal(beautiful: 'Secondo giorno'),
    );

    final state = await LocalStateStore.instance.open(
      legacyPreferences: await SharedPreferences.getInstance(),
    );
    expect(state.getString('items_v1'), '{not valid json');
    expect(
      jsonDecode(state.getString('journals_v1')!) as Map,
      contains('2026-09-22'),
    );
  });

  test('explicitly empty habits remain empty after reload', () async {
    SharedPreferences.setMockInitialValues({
      'habits_v1': '[]',
    });

    final store = AgendaStore();
    await store.load();

    expect(store.habits, isEmpty);
  });

  test('civil date helper preserves calendar-day navigation', () {
    final start = DateTime(2026, 10, 24);
    final next = addCivilDays(start, 2);
    final previous = addCivilDays(next, -2);

    expect(next, DateTime(2026, 10, 26));
    expect(previous, DateTime(2026, 10, 24));
  });

  test('pinned state survives ordinary item edits', () {
    final item = AgendaItem(
      id: 'pinned-1',
      title: 'Titolo',
      note: '',
      date: DateTime(2026, 9, 21),
      type: ItemType.task,
      pinned: true,
    );

    final edited = item.copyWith(title: 'Titolo aggiornato');

    expect(edited.pinned, isTrue);
  });

  test('PIN accepts only 4 to 8 numeric digits', () async {
    final store = AgendaStore();

    await expectLater(
      store.setPin('12ab'),
      throwsA(isA<FormatException>()),
    );
    await expectLater(
      store.setPin('123456789'),
      throwsA(isA<FormatException>()),
    );

    await store.setPin('123456');
    expect(store.verifyPin('123456'), isTrue);
  });

  test('restore preserves intentionally empty habits', () async {
    final source = AgendaStore();
    await source.load();

    while (source.habits.isNotEmpty) {
      await source.removeHabit(source.habits.first.id);
    }

    final backup = await source.createBackupJson();

    final restored = AgendaStore();
    await restored.load();
    await restored.restoreBackup(backup, merge: false);

    expect(restored.habits, isEmpty);
  });

  test('privacy guard survives a corrupt preferences payload', () async {
    final seed = AgendaStore();
    await seed.load();
    await seed.setPin('2468');

    final state = await LocalStateStore.instance.open(
      legacyPreferences: await SharedPreferences.getInstance(),
    );
    await state.setString('agenda_preferences_v1', '{corrupt');

    final restored = AgendaStore();
    await restored.load();

    expect(restored.hasStorageWarnings, isTrue);
    expect(restored.preferences.privacyLockEnabled, isTrue);
    expect(restored.verifyPin('2468'), isTrue);
  });

  test('completed task remains serializable with its pinned state', () {
    final item = AgendaItem(
      id: 'done-1',
      title: 'Fatto',
      note: '',
      date: DateTime(2026, 9, 21),
      type: ItemType.task,
      done: true,
      pinned: true,
      start: const TimeOfDay(hour: 8, minute: 0),
    );

    final restored = AgendaItem.fromJson(item.toJson());

    expect(restored.done, isTrue);
    expect(restored.pinned, isTrue);
  });
  test('journal edits persist as entity deltas without rewriting aggregate',
      () async {
    final original = jsonEncode({
      '2026-09-20': const DayJournal(
        beautiful: 'Baseline',
      ).toLocalJson(),
    });
    SharedPreferences.setMockInitialValues({
      'journals_v1': original,
      'habits_v1': '[]',
    });

    final store = AgendaStore();
    await store.load();

    final state = await LocalStateStore.instance.open(
      legacyPreferences: await SharedPreferences.getInstance(),
    );
    final aggregateBefore = state.getString('journals_v1');

    await store.saveJournal(
      DateTime(2026, 9, 23),
      const DayJournal(
        beautiful: 'Delta',
        note: 'Salvataggio granulare',
      ),
    );

    expect(state.getString('journals_v1'), aggregateBefore);
    expect(
      state.getKeys().where(
            (key) => key.startsWith('entity_delta_v2_'),
          ),
      isNotEmpty,
    );

    final reloaded = AgendaStore();
    await reloaded.load();

    expect(
      reloaded.journal(DateTime(2026, 9, 20)).beautiful,
      'Baseline',
    );
    expect(
      reloaded.journal(DateTime(2026, 9, 23)).beautiful,
      'Delta',
    );
    expect(
      reloaded.journal(DateTime(2026, 9, 23)).note,
      'Salvataggio granulare',
    );

    store.dispose();
    reloaded.dispose();
  });

  test('item delta deletion survives reload without aggregate rewrite',
      () async {
    final baselineItem = AgendaItem(
      id: 'baseline',
      title: 'Baseline',
      note: '',
      date: DateTime(2026, 9, 23),
      type: ItemType.task,
    );
    final original = jsonEncode([baselineItem.toJson()]);
    SharedPreferences.setMockInitialValues({
      'items_v1': original,
      'habits_v1': '[]',
    });

    final store = AgendaStore();
    await store.load();
    final state = await LocalStateStore.instance.open(
      legacyPreferences: await SharedPreferences.getInstance(),
    );
    final aggregateBefore = state.getString('items_v1');

    await store.upsert(
      AgendaItem(
        id: 'delta',
        title: 'Granulare',
        note: '',
        date: DateTime(2026, 9, 24),
        type: ItemType.appointment,
      ),
    );
    await store.deleteItem('baseline');

    expect(state.getString('items_v1'), aggregateBefore);

    final reloaded = AgendaStore();
    await reloaded.load();

    expect(reloaded.items.any((item) => item.id == 'baseline'), isFalse);
    expect(reloaded.items.any((item) => item.id == 'delta'), isTrue);

    store.dispose();
    reloaded.dispose();
  });

  test('unified counters invalidate after granular agenda mutations',
      () async {
    final store = AgendaStore();
    await store.load();

    expect(store.pendingUnifiedTaskCount, 0);
    expect(store.unifiedMonthCount(2026, 9), 0);

    await store.upsert(
      AgendaItem(
        id: 'cached-task',
        title: 'Task',
        note: '',
        date: DateTime(2026, 9, 23),
        type: ItemType.task,
      ),
    );

    expect(store.pendingUnifiedTaskCount, 1);
    expect(store.unifiedMonthCount(2026, 9), 1);

    await store.toggle('cached-task');

    expect(store.pendingUnifiedTaskCount, 0);
    expect(store.unifiedMonthCount(2026, 9), 1);

    store.dispose();
  });

}
