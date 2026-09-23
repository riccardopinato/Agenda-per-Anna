import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agenda_per_anna/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('backup document contains and restores core agenda data', () async {
    final source = AgendaStore();
    source.items.add(
      AgendaItem(
        id: 'event-1',
        title: 'Cena',
        note: 'Ricordo',
        date: DateTime(2026, 9, 21),
        type: ItemType.appointment,
        category: AgendaCategory.couple,
        start: const TimeOfDay(hour: 20, minute: 0),
      ),
    );
    source.journals['2026-09-21'] = const DayJournal(
      beautiful: 'Una bella serata',
      mood: DayMood.great,
      gratitude: ['Tempo insieme'],
    );
    source.months['2026-09'] = const MonthlyData(
      intention: 'Stare bene',
      goals: ['Leggere'],
      films: ['Un film'],
    );
    source.habits.add(
      const HabitDefinition(id: 'read', name: 'Leggere'),
    );

    final raw = await source.createBackupJson();
    final summary = source.inspectBackup(raw);

    expect(summary.itemCount, 1);
    expect(summary.journalCount, 1);
    expect(summary.monthCount, 1);
    expect(summary.habitCount, 1);

    final restored = AgendaStore();
    await restored.restoreBackup(raw, merge: false);

    expect(restored.items.single.title, 'Cena');
    expect(restored.journal(DateTime(2026, 9, 21)).mood, DayMood.great);
    expect(restored.month(2026, 9).films, ['Un film']);
    expect(restored.habits.single.name, 'Leggere');
    expect(restored.localSnapshots, hasLength(1));
  });

  test('invalid backup is rejected before restore', () {
    final store = AgendaStore();

    expect(
      () => store.inspectBackup('{"format":"something_else"}'),
      throwsA(isA<FormatException>()),
    );
  });
}
