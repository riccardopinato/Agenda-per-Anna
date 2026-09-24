import 'dart:convert';

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

  test('domain revisions invalidate only the UI domain that changed', () async {
    final store = AgendaStore();
    await store.load();

    final agenda0 = store.agendaRevision.value;
    final journal0 = store.journalRevision.value;
    final settings0 = store.settingsRevision.value;

    await store.upsert(
      AgendaItem(
        id: 'v040-task',
        title: 'Task granulare',
        note: '',
        date: DateTime(2026, 9, 24),
        type: ItemType.task,
      ),
    );

    expect(store.agendaRevision.value, greaterThan(agenda0));
    expect(store.journalRevision.value, journal0);
    expect(store.settingsRevision.value, settings0);

    final agenda1 = store.agendaRevision.value;
    await store.saveJournal(
      DateTime(2026, 9, 24),
      const DayJournal(beautiful: 'Ricordo granulare'),
    );

    expect(store.agendaRevision.value, agenda1);
    expect(store.journalRevision.value, greaterThan(journal0));
    expect(store.settingsRevision.value, settings0);

    final journal1 = store.journalRevision.value;
    await store.savePreferences(
      store.preferences.copyWith(displayName: 'Anna v0.40'),
    );

    expect(store.journalRevision.value, journal1);
    expect(store.settingsRevision.value, greaterThan(settings0));

    store.dispose();
  });

  test('process-style restart reloads agenda journal planning inbox and habits',
      () async {
    final first = AgendaStore();
    await first.load();

    await first.upsert(
      AgendaItem(
        id: 'restart-task',
        title: 'Sopravvive al restart',
        note: '',
        date: DateTime(2026, 9, 25),
        type: ItemType.appointment,
        start: const TimeOfDay(hour: 9, minute: 15),
      ),
    );
    await first.saveJournal(
      DateTime(2026, 9, 25),
      const DayJournal(
        beautiful: 'Persistenza',
        note: 'Dopo process restart',
      ),
    );
    await first.saveMonth(
      2026,
      9,
      const MonthlyData(monthWord: 'Stabile'),
    );
    await first.saveWeek(
      DateTime(2026, 9, 25),
      const WeekData(focus: 'Settimana persistente'),
    );
    await first.addInboxEntry('Inbox persistente');
    await first.addHabit('Stretching');

    first.dispose();

    final second = AgendaStore();
    await second.load();

    expect(second.items.any((item) => item.id == 'restart-task'), isTrue);
    expect(
      second.journal(DateTime(2026, 9, 25)).beautiful,
      'Persistenza',
    );
    expect(second.month(2026, 9).monthWord, 'Stabile');
    expect(
      second.week(DateTime(2026, 9, 25)).focus,
      'Settimana persistente',
    );
    expect(second.inbox.map((entry) => entry.text), contains('Inbox persistente'));
    expect(second.habits.map((habit) => habit.name), contains('Stretching'));

    second.dispose();
  });

  test('offline-style pending edits remain isolated across account switches',
      () async {
    final store = AgendaStore();
    await store.load();
    await store.activateCloudAccount('user-a');

    await store.upsert(
      AgendaItem(
        id: 'offline-a',
        title: 'Offline A',
        note: '',
        date: DateTime(2026, 9, 26),
        type: ItemType.task,
      ),
    );
    final pendingA = store.pendingCloudChanges;
    expect(pendingA, greaterThan(0));

    await store.activateCloudAccount('user-b');
    expect(store.items.any((item) => item.id == 'offline-a'), isFalse);

    await store.upsert(
      AgendaItem(
        id: 'offline-b',
        title: 'Offline B',
        note: '',
        date: DateTime(2026, 9, 26),
        type: ItemType.task,
      ),
    );

    await store.activateCloudAccount('user-a');

    expect(store.items.any((item) => item.id == 'offline-a'), isTrue);
    expect(store.items.any((item) => item.id == 'offline-b'), isFalse);
    expect(store.pendingCloudChanges, pendingA);

    store.dispose();
  });

  test('legacy storage upgrades without losing private journal data', () async {
    final legacyItem = AgendaItem(
      id: 'legacy-item-v040',
      title: 'Legacy',
      note: 'Conservato',
      date: DateTime(2026, 9, 20),
      type: ItemType.task,
    );

    SharedPreferences.setMockInitialValues({
      'items_v1': jsonEncode([legacyItem.toJson()]),
      'journals_v1': jsonEncode({
        '2026-09-20': const DayJournal(
          beautiful: 'Ricordo legacy',
          note: 'Upgrade v0.40',
        ).toJson(),
      }),
      'habits_v1': '[]',
    });

    final store = AgendaStore();
    await store.load();

    expect(store.items.map((item) => item.id), contains('legacy-item-v040'));
    expect(
      store.journal(DateTime(2026, 9, 20)).beautiful,
      'Ricordo legacy',
    );

    final state = await LocalStateStore.instance.open(
      legacyPreferences: await SharedPreferences.getInstance(),
    );
    expect(state.getString('items_v1'), isNotNull);
    expect(state.getString('journals_v1'), isNotNull);

    store.dispose();
  });

  test('corrupt shared queue is quarantined and never overwritten', () async {
    final store = AgendaStore();
    await store.load();
    await store.activateCloudAccount('user-a');

    final state = await LocalStateStore.instance.open(
      legacyPreferences: await SharedPreferences.getInstance(),
    );
    final key = store.sharedPendingStorageKey('space-a');
    await state.setString(key, '{broken-queue');

    final operations = await store.loadSharedPendingOperations('space-a');

    expect(operations, isEmpty);
    expect(store.hasStorageWarnings, isTrue);
    expect(state.getString(key), '{broken-queue');

    store.dispose();
  });
}
