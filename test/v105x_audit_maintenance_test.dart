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

  testWidgets('Modelli opens a draft; cancel does not create an entry',
      (tester) async {
    final store = AgendaStore();
    await store.load();
    final day = DateTime(2026, 10, 27);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DiaryMemoryCard(store: store, date: day),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Templates'));
    await tester.pumpAndSettle();
    expect(find.text('Diary templates'), findsOneWidget);
    await tester.tap(find.text('Morning').last);
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(store.journal(day).blocks, isEmpty);

    await tester.tap(find.text('Cancel').last);
    await tester.pumpAndSettle();
    expect(store.journal(day).blocks, isEmpty);

    await tester.tap(find.text('Templates'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Morning').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save').last);
    await tester.pumpAndSettle();
    expect(store.journal(day).blocks, hasLength(1));

    await tester.pumpWidget(const SizedBox.shrink());
    store.dispose();
  });

  test('failed local journal batch rolls back RAM and the next save succeeds',
      () async {
    final store = AgendaStore();
    await store.load();
    final day = DateTime(2026, 10, 27);
    await store.saveJournal(day, const DayJournal(note: 'Previously saved'));

    LocalStateStore.instance.failNextBatchForTesting();
    await expectLater(
      store.saveJournal(day, const DayJournal(note: 'Failed edit')),
      throwsStateError,
    );
    expect(store.journal(day).note, 'Previously saved');

    await store.saveJournal(day, const DayJournal(note: 'Recovered edit'));
    expect(store.journal(day).note, 'Recovered edit');
    store.dispose();

    final reloaded = AgendaStore();
    await reloaded.load();
    expect(reloaded.journal(day).note, 'Recovered edit');
    reloaded.dispose();
  });

  test('concurrent writes do not lose the successful sync operation',
      () async {
    final store = AgendaStore();
    await store.load();
    final firstDay = DateTime(2026, 10, 25);
    final secondDay = DateTime(2026, 10, 26);

    LocalStateStore.instance.failNextBatchForTesting();
    final failed = store.saveJournal(
      firstDay,
      const DayJournal(note: 'Must roll back'),
    );
    final successful = store.saveJournal(
      secondDay,
      const DayJournal(note: 'Must persist'),
    );

    await expectLater(failed, throwsStateError);
    await successful;
    expect(store.journal(firstDay).note, isEmpty);
    expect(store.journal(secondDay).note, 'Must persist');
    store.dispose();

    final reloaded = AgendaStore();
    await reloaded.load();
    expect(reloaded.journal(firstDay).note, isEmpty);
    expect(reloaded.journal(secondDay).note, 'Must persist');
    reloaded.dispose();
  });

  test('nonconflicting journal fields are merged with fresh remote data', () {
    const baseline = DayJournal(
      beautiful: 'Before',
      note: 'Original',
      gratitude: ['old'],
      completedHabitIds: ['h1'],
    );
    final current = baseline.copyWith(
      note: 'Remote text',
      completedHabitIds: const ['h1', 'h2'],
    );

    final result = reconcileDailyJournalDraft(
      baseline: baseline,
      current: current,
      beautiful: 'My updated highlight',
      note: 'Original',
      mood: null,
      gratitude: const ['old'],
    );
    expect(result.hasConflicts, isFalse);
    expect(result.merged.beautiful, 'My updated highlight');
    expect(result.merged.note, 'Remote text');
    expect(result.merged.completedHabitIds, ['h1', 'h2']);
  });

  test('same-field changes require an explicit conflict decision', () {
    const baseline = DayJournal(note: 'Original');
    const remote = DayJournal(note: 'Saved on second device');
    final result = reconcileDailyJournalDraft(
      baseline: baseline,
      current: remote,
      beautiful: '',
      note: 'Edited on first device',
      mood: null,
      gratitude: const [],
    );
    expect(result.hasConflicts, isTrue);
    expect(result.merged.note, 'Edited on first device');
  });

  test('collection ID resolves newly saved filters without stale captures', () async {
    final store = AgendaStore();
    await store.load();
    final day = DateTime(2026, 10, 27);
    await store.saveJournal(
      day,
      DayJournal(
        blocks: [
          DiaryBlock(
            id: 'one',
            type: DiaryBlockType.note,
            createdAt: day,
            tags: const ['one'],
          ),
          DiaryBlock(
            id: 'two',
            type: DiaryBlockType.note,
            createdAt: day,
            tags: const ['two'],
          ),
        ],
      ),
    );
    await store.saveMemoryCollection(
      const MemoryCollectionDefinition(id: 'col', name: 'First', tag: 'one'),
    );
    expect(
      store.memoryCollectionReferencesById('col').single.block.id,
      'one',
    );

    await store.saveMemoryCollection(
      const MemoryCollectionDefinition(id: 'col', name: 'Second', tag: 'two'),
    );
    expect(
      store.memoryCollectionReferencesById('col').single.block.id,
      'two',
    );

    await store.deleteMemoryCollection('col');
    expect(store.memoryCollectionReferencesById('col'), isEmpty);
    store.dispose();
  });

  test('Life Threads deduplicates repeated tags on each note', () async {
    final store = AgendaStore();
    await store.load();
    for (var i = 0; i < 2; i++) {
      final day = DateTime(2026, 10, i + 1);
      await store.saveJournal(
        day,
        DayJournal(
          blocks: [
            DiaryBlock(
              id: 'note-$i',
              type: DiaryBlockType.note,
              createdAt: day,
              tags: const ['trip', 'trip'],
            ),
          ],
        ),
      );
    }
    final thread = store.memoryLifeThreads()
        .singleWhere((item) => item.id == 'tag:trip');
    expect(thread.count, 2);
    store.dispose();
  });
}
