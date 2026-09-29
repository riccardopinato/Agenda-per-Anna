import 'dart:io';

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

  test('Day Hub projects agenda birthday workout and diary into one life stream',
      () async {
    final store = AgendaStore();
    await store.load();

    final day = DateTime(2026, 9, 29);

    await store.upsert(
      AgendaItem(
        id: 'meeting',
        title: 'Dentista',
        note: '',
        date: day,
        type: ItemType.appointment,
        start: const TimeOfDay(hour: 9, minute: 30),
      ),
    );

    await store.saveBirthday(
      const BirthdayEntry(
        id: 'birthday',
        name: 'Marta',
        day: 29,
        month: 9,
        reminderDaysBefore: null,
      ),
    );

    await store.saveWorkoutSession(
      WorkoutSession(
        id: 'run',
        sport: WorkoutSport.running,
        date: day,
        title: '15 km',
        durationSeconds: 3900,
        distanceKm: 15,
        createdAt: DateTime(2026, 9, 29, 18, 0),
      ),
    );

    await store.saveJournal(
      day,
      DayJournal(
        beautiful: 'Una buona giornata',
        blocks: [
          DiaryBlock(
            id: 'voice',
            type: DiaryBlockType.voice,
            createdAt: DateTime(2026, 9, 29, 20, 15),
            text: 'Pensiero serale',
          ),
        ],
      ),
    );

    final snapshot = store.dayHubSnapshot(day);

    expect(snapshot.birthdays, hasLength(1));
    expect(snapshot.workouts, hasLength(1));
    expect(snapshot.hasJournalContent, isTrue);
    expect(
      snapshot.lifeEntries.map((entry) => entry.kind).toList(),
      [
        DayLifeEntryKind.birthday,
        DayLifeEntryKind.agenda,
        DayLifeEntryKind.workout,
        DayLifeEntryKind.diaryBlock,
      ],
    );
    expect(snapshot.lifeEntries.map((entry) => entry.id), [
      'birthday:birthday',
      'agenda:meeting',
      'workout:run',
      'diary:voice',
    ]);

    store.dispose();
  });

  test('archived diary blocks do not reappear in the day life stream', () async {
    final store = AgendaStore();
    await store.load();
    final day = DateTime(2026, 9, 29);

    await store.saveJournal(
      day,
      DayJournal(
        blocks: [
          DiaryBlock(
            id: 'visible',
            type: DiaryBlockType.note,
            createdAt: DateTime(2026, 9, 29, 12),
            text: 'Visibile',
          ),
          DiaryBlock(
            id: 'archived',
            type: DiaryBlockType.photo,
            createdAt: DateTime(2026, 9, 29, 13),
            text: 'Archiviata',
            archived: true,
          ),
        ],
      ),
    );

    final snapshot = store.dayHubSnapshot(day);

    expect(
      snapshot.lifeEntries
          .where((entry) => entry.kind == DayLifeEntryKind.diaryBlock)
          .map((entry) => entry.diaryBlock!.id),
      ['visible'],
    );
    store.dispose();
  });

  test('new profiles open on La mia giornata by default', () {
    expect(const AgendaPreferences().startTab, StartTab.today);
  });

  test('onboarding completion invalidates the root shell', () {
    final shell = File('lib/src/app_shell.dart').readAsStringSync();
    expect(shell, contains('store.shellRevision,'));
    expect(
      shell,
      contains('store.preferences.copyWith(onboardingDone: true)'),
    );
  });

  test('Home and Planner share the same day overview projection', () {
    final home =
        File('lib/src/screens/home_inbox_search.dart').readAsStringSync();
    final planner = File('lib/src/planner_views.dart').readAsStringSync();

    expect(home, contains('_DayLifeOverviewCard('));
    expect(planner, contains('_DayLifeOverviewCard('));
    expect(planner, contains('_DayLifeStream('));
    expect(planner, contains("const SectionTitle('Diario')"));
    expect(planner, contains("label: const Text('Cattura')"));
  });
}
