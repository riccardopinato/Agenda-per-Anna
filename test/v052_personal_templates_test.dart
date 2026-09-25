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

  test('day template clones agenda items without copying completion state',
      () async {
    final store = AgendaStore();
    await store.load();
    final source = DateTime(2026, 10, 1);
    final target = DateTime(2026, 10, 8);

    await store.upsert(
      AgendaItem(
        id: 'source-task',
        title: 'Allenamento',
        note: 'Routine',
        date: source,
        type: ItemType.task,
        category: AgendaCategory.personal,
        start: const TimeOfDay(hour: 18, minute: 30),
        reminderMinutesBefore: 30,
        done: true,
      ),
    );

    final template = await store.createDayTemplate('Giornata sport', source);
    final result = await store.applyTemplate(template, target);

    expect(result.createdAgendaItems, 1);
    final cloned = store.items.singleWhere(
      (item) =>
          item.id != 'source-task' &&
          AgendaStore.sameDay(item.date, target),
    );
    expect(cloned.title, 'Allenamento');
    expect(cloned.start, const TimeOfDay(hour: 18, minute: 30));
    expect(cloned.reminderMinutesBefore, 30);
    expect(cloned.done, isFalse);
    expect(cloned.id, isNot('source-task'));

    store.dispose();
  });

  test('week and month templates preserve outcome data while reusing plans',
      () async {
    final store = AgendaStore();
    await store.load();

    final sourceWeek = DateTime(2026, 10, 5);
    await store.saveWeek(
      sourceWeek,
      const WeekData(
        focus: 'Energia',
        priorities: ['Sport', 'Famiglia'],
        bestThing: 'Non va copiato',
        reflection: 'Non va copiata',
      ),
    );
    final weekTemplate =
        await store.createWeekTemplate('Settimana equilibrata', sourceWeek);

    final targetWeek = DateTime(2026, 10, 12);
    await store.saveWeek(
      targetWeek,
      const WeekData(
        focus: 'Focus esistente',
        bestThing: 'Ricordo target',
        reflection: 'Riflessione target',
      ),
    );

    await store.applyTemplate(weekTemplate, targetWeek, overwrite: false);
    var week = store.week(targetWeek);
    expect(week.focus, 'Focus esistente');
    expect(week.priorities, ['Sport', 'Famiglia']);
    expect(week.bestThing, 'Ricordo target');
    expect(week.reflection, 'Riflessione target');

    await store.applyTemplate(weekTemplate, targetWeek, overwrite: true);
    week = store.week(targetWeek);
    expect(week.focus, 'Energia');
    expect(week.priorities, ['Sport', 'Famiglia']);
    expect(week.bestThing, 'Ricordo target');
    expect(week.reflection, 'Riflessione target');

    final sourceMonth = DateTime(2026, 9, 1);
    await store.saveMonth(
      2026,
      9,
      MonthlyData(
        intention: 'Calma',
        goals: const ['Leggere'],
        budgetCents: 25000,
        expenses: [
          ExpenseEntry(
            id: 'source-expense',
            cents: 1200,
            category: 'Altro',
            note: 'Non va copiato',
            date: sourceMonth,
          ),
        ],
        reflection: 'Non va copiata',
      ),
    );
    final monthTemplate =
        await store.createMonthTemplate('Mese semplice', sourceMonth);

    final targetMonth = DateTime(2026, 11, 1);
    await store.saveMonth(
      2026,
      11,
      MonthlyData(
        goals: const ['Esistente'],
        expenses: [
          ExpenseEntry(
            id: 'target-expense',
            cents: 500,
            category: 'Altro',
            note: 'Target',
            date: targetMonth,
          ),
        ],
        reflection: 'Riflessione target',
      ),
    );

    await store.applyTemplate(monthTemplate, targetMonth, overwrite: false);
    var month = store.month(2026, 11);
    expect(month.intention, 'Calma');
    expect(month.goals, ['Esistente']);
    expect(month.budgetCents, 25000);
    expect(month.expenses.single.id, 'target-expense');
    expect(month.reflection, 'Riflessione target');

    await store.applyTemplate(monthTemplate, targetMonth, overwrite: true);
    month = store.month(2026, 11);
    expect(month.goals, ['Leggere']);
    expect(month.expenses.single.id, 'target-expense');
    expect(month.reflection, 'Riflessione target');

    store.dispose();
  });

  test('templates persist, backup, trash and restore without account leakage',
      () async {
    final store = AgendaStore();
    await store.load();
    await store.activateCloudAccount('templates-a');

    final now = DateTime(2026, 10, 1);
    await store.saveTemplate(
      PersonalTemplate(
        id: 'template-a',
        name: 'Routine A',
        kind: PersonalTemplateKind.week,
        createdAt: now,
        updatedAt: now,
        payload: const {
          'focus': 'Focus A',
          'priorities': ['Uno'],
        },
      ),
    );

    final backup = await store.createBackupJson();
    final summary = store.inspectBackup(backup);
    expect(summary.templateCount, 1);

    expect(await store.moveTemplateToTrash('template-a'), isTrue);
    expect(store.templates, isEmpty);
    final trashEntry = store.trash.singleWhere(
      (entry) => entry.kind == TrashEntityKind.template,
    );
    expect(await store.restoreTrashEntry(trashEntry.id), isTrue);
    expect(store.templates.single.id, 'template-a');

    await store.activateCloudAccount('templates-b');
    expect(store.templates, isEmpty);

    await store.activateCloudAccount('templates-a');
    expect(store.templates.single.name, 'Routine A');

    store.dispose();

    final reloaded = AgendaStore();
    await reloaded.load();
    await reloaded.activateCloudAccount('templates-a');
    expect(reloaded.templates.single.id, 'template-a');
    reloaded.dispose();
  });
}
