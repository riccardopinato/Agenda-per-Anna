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

  test('people persist and are included in backup metadata', () async {
    final first = AgendaStore();
    await first.load();
    await first.saveBirthday(
      const BirthdayEntry(
        id: 'birthday-anna',
        name: 'Anna',
        day: 12,
        month: 6,
        reminderDaysBefore: null,
      ),
    );
    await first.savePerson(
      const PersonEntry(
        id: 'person-anna',
        name: 'Anna',
        relationship: 'Persona importante',
        note: 'Ricordare il regalo',
        birthdayId: 'birthday-anna',
        favorite: true,
      ),
    );

    final backup = await first.createBackupJson();
    final summary = first.inspectBackup(backup);
    expect(summary.personCount, 1);
    first.dispose();

    final second = AgendaStore();
    await second.load();
    expect(second.people, hasLength(1));
    expect(second.people.single.name, 'Anna');
    expect(second.people.single.favorite, isTrue);
    expect(second.birthdayForPerson(second.people.single)?.id, 'birthday-anna');
    second.dispose();
  });

  test('diary blocks can link multiple people without duplicating memories',
      () async {
    final store = AgendaStore();
    await store.load();
    await store.savePerson(
      const PersonEntry(id: 'person-a', name: 'Anna'),
    );
    await store.savePerson(
      const PersonEntry(id: 'person-b', name: 'Luca'),
    );
    final date = DateTime(2026, 9, 25);
    await store.saveJournal(
      date,
      DayJournal(
        blocks: [
          DiaryBlock(
            id: 'memory-1',
            type: DiaryBlockType.note,
            createdAt: date,
            text: 'Serata insieme',
          ),
        ],
      ),
    );

    await store.tagDiaryBlockPeople(
      date,
      'memory-1',
      ['person-a', 'person-b', 'person-a'],
    );

    final block = store.journal(date).blocks.single;
    expect(block.personIds, ['person-a', 'person-b']);
    expect(store.personMemoryCount('person-a'), 1);
    expect(store.personMemoryCount('person-b'), 1);
    expect(store.memoriesForPerson('person-a').single.block.id, 'memory-1');
    store.dispose();
  });

  test('person Trash restores links; permanent purge removes orphan tags',
      () async {
    final store = AgendaStore();
    await store.load();
    await store.savePerson(
      const PersonEntry(id: 'person-trash', name: 'Marta'),
    );
    final date = DateTime(2026, 9, 24);
    await store.saveJournal(
      date,
      DayJournal(
        blocks: [
          DiaryBlock(
            id: 'memory-trash',
            type: DiaryBlockType.note,
            createdAt: date,
            text: 'Ricordo',
            personIds: const ['person-trash'],
          ),
        ],
      ),
    );

    expect(await store.movePersonToTrash('person-trash'), isTrue);
    expect(store.people, isEmpty);
    expect(store.journal(date).blocks.single.personIds, ['person-trash']);
    final trashId = store.trash.single.id;

    expect(await store.restoreTrashEntry(trashId), isTrue);
    expect(store.people.single.id, 'person-trash');
    expect(store.personMemoryCount('person-trash'), 1);

    expect(await store.movePersonToTrash('person-trash'), isTrue);
    final secondTrashId = store.trash.single.id;
    expect(
      await store.purgeTrashEntry(
        secondTrashId,
        createSafetySnapshot: false,
      ),
      isTrue,
    );
    expect(store.journal(date).blocks.single.personIds, isEmpty);
    store.dispose();
  });

  test('permanently purged birthday is unlinked without deleting the person',
      () async {
    final store = AgendaStore();
    await store.load();
    await store.saveBirthday(
      const BirthdayEntry(
        id: 'birthday-linked',
        name: 'Luca',
        day: 1,
        month: 4,
        reminderDaysBefore: null,
      ),
    );
    await store.savePerson(
      const PersonEntry(
        id: 'person-linked',
        name: 'Luca',
        birthdayId: 'birthday-linked',
      ),
    );

    expect(await store.moveBirthdayToTrash('birthday-linked'), isTrue);
    final trashId = store.trash.single.id;
    expect(
      await store.purgeTrashEntry(trashId, createSafetySnapshot: false),
      isTrue,
    );
    expect(store.people.single.id, 'person-linked');
    expect(store.people.single.birthdayId, isNull);
    store.dispose();
  });

  test('people remain isolated across account profiles', () async {
    final store = AgendaStore();
    await store.load();
    await store.activateCloudAccount('people-a');
    await store.savePerson(
      const PersonEntry(id: 'person-a', name: 'Profilo A'),
    );

    await store.activateCloudAccount('people-b');
    expect(store.people, isEmpty);
    await store.savePerson(
      const PersonEntry(id: 'person-b', name: 'Profilo B'),
    );

    await store.activateCloudAccount('people-a');
    expect(store.people.map((person) => person.id), ['person-a']);
    store.dispose();
  });
}
