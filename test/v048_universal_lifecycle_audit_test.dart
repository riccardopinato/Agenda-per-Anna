import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agenda_per_anna/local_state_store.dart';
import 'package:agenda_per_anna/main.dart';
import 'package:agenda_per_anna/media_asset_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await initializeDateFormatting('it_IT', null);
    await LocalStateStore.instance.resetForTesting();
    await MediaAssetStore.instance.resetForTesting();
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    await LocalStateStore.instance.resetForTesting();
    await MediaAssetStore.instance.resetForTesting();
  });

  test('Trash preserves multiple historical versions of singleton pages',
      () async {
    final store = AgendaStore();
    await store.load();
    final date = DateTime(2026, 10, 10);

    await store.saveJournal(date, const DayJournal(note: 'Versione uno'));
    expect(await store.moveJournalToTrash(date), isTrue);

    await store.saveJournal(date, const DayJournal(note: 'Versione due'));
    expect(await store.moveJournalToTrash(date), isTrue);

    final journalTrash = store.trash
        .where((entry) => entry.kind == TrashEntityKind.journal)
        .toList();
    expect(journalTrash, hasLength(2));

    final firstVersion = journalTrash.singleWhere(
      (entry) => entry.payload['note'] == 'Versione uno',
    );
    final secondVersion = journalTrash.singleWhere(
      (entry) => entry.payload['note'] == 'Versione due',
    );

    expect(await store.restoreTrashEntry(firstVersion.id), isTrue);
    expect(store.journal(date).note, 'Versione uno');

    expect(await store.restoreTrashEntry(secondVersion.id), isFalse);
    expect(store.journal(date).note, 'Versione uno');
    expect(store.trash.any((entry) => entry.id == secondVersion.id), isTrue);

    expect(await store.moveJournalToTrash(date), isTrue);
    expect(await store.restoreTrashEntry(secondVersion.id), isTrue);
    expect(store.journal(date).note, 'Versione due');

    store.dispose();
  });

  test('restore never overwrites a recreated diary block with the same id',
      () async {
    final store = AgendaStore();
    await store.load();
    final date = DateTime(2026, 10, 11);

    await store.saveJournal(
      date,
      DayJournal(
        blocks: [
          DiaryBlock(
            id: 'same-block',
            type: DiaryBlockType.note,
            createdAt: date,
            text: 'Vecchia versione',
          ),
        ],
      ),
    );

    expect(await store.moveDiaryBlockToTrash(date, 'same-block'), isTrue);
    final trashId = store.trash.single.id;

    await store.saveJournal(
      date,
      DayJournal(
        blocks: [
          DiaryBlock(
            id: 'same-block',
            type: DiaryBlockType.note,
            createdAt: date.add(const Duration(hours: 1)),
            text: 'Nuova versione',
          ),
        ],
      ),
    );

    expect(await store.restoreTrashEntry(trashId), isFalse);
    expect(store.journal(date).blocks.single.text, 'Nuova versione');
    expect(store.trash.single.id, trashId);

    store.dispose();
  });

  test('permanent habit purge scrubs links from journals already in Trash',
      () async {
    final store = AgendaStore();
    await store.load();
    await store.addHabit('Bere acqua');
    final habit = store.habits.singleWhere(
      (value) => value.name == 'Bere acqua',
    );
    final date = DateTime(2026, 10, 12);

    await store.toggleHabit(date, habit.id);
    expect(store.journal(date).completedHabitIds, contains(habit.id));

    expect(await store.moveJournalToTrash(date), isTrue);
    expect(await store.moveHabitToTrash(habit.id), isTrue);

    final habitTrash = store.trash.singleWhere(
      (entry) => entry.kind == TrashEntityKind.habit,
    );
    expect(
      await store.purgeTrashEntry(
        habitTrash.id,
        createSafetySnapshot: false,
      ),
      isTrue,
    );

    final journalTrash = store.trash.singleWhere(
      (entry) => entry.kind == TrashEntityKind.journal,
    );
    final payload = DayJournal.fromJson(journalTrash.payload);
    expect(payload.completedHabitIds, isNot(contains(habit.id)));

    expect(await store.restoreTrashEntry(journalTrash.id), isTrue);
    expect(store.journal(date).completedHabitIds, isNot(contains(habit.id)));

    store.dispose();
  });

  test('purging an old person version keeps links when that person is live',
      () async {
    final store = AgendaStore();
    await store.load();
    const personId = 'person-still-live';
    final date = DateTime(2026, 10, 13);

    await store.savePerson(
      const PersonEntry(id: personId, name: 'Versione uno'),
    );
    await store.saveJournal(
      date,
      DayJournal(
        blocks: [
          DiaryBlock(
            id: 'linked-memory',
            type: DiaryBlockType.note,
            createdAt: date,
            text: 'Ricordo',
            personIds: const [personId],
          ),
        ],
      ),
    );

    expect(await store.movePersonToTrash(personId), isTrue);
    final oldTrashId = store.trash.single.id;

    await store.savePerson(
      const PersonEntry(id: personId, name: 'Versione nuova'),
    );
    expect(
      await store.purgeTrashEntry(
        oldTrashId,
        createSafetySnapshot: false,
      ),
      isTrue,
    );

    expect(store.people.single.id, personId);
    expect(store.journal(date).blocks.single.personIds, [personId]);

    store.dispose();
  });

  test('private Trash contract covers every first-class private content kind',
      () {
    expect(
      TrashEntityKind.values.toSet(),
      {
        TrashEntityKind.item,
        TrashEntityKind.diaryBlock,
        TrashEntityKind.journal,
        TrashEntityKind.month,
        TrashEntityKind.week,
        TrashEntityKind.habit,
        TrashEntityKind.birthday,
        TrashEntityKind.person,
        TrashEntityKind.template,
        TrashEntityKind.inbox,
      },
    );
  });
}
