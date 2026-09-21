import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('items_v1'), '{not valid json');
    expect(
      jsonDecode(prefs.getString('journals_v1')!) as Map,
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
}
