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

  test('birthday occurrence is annual and leap-day safe', () async {
    final store = AgendaStore();
    await store.load();
    const birthday = BirthdayEntry(
      id: 'leap',
      name: 'Anna',
      day: 29,
      month: 2,
      year: 2000,
      reminderDaysBefore: null,
    );

    final nonLeap = store.birthdayOccurrence(birthday, 2027);
    expect(nonLeap.date, DateTime(2027, 2, 28));
    expect(nonLeap.age, 27);

    final leap = store.birthdayOccurrence(birthday, 2028);
    expect(leap.date, DateTime(2028, 2, 29));
    expect(leap.age, 28);
    store.dispose();
  });

  test('birthday survives restart and backup reports it', () async {
    final first = AgendaStore();
    await first.load();
    await first.saveBirthday(
      const BirthdayEntry(
        id: 'anna-birthday',
        name: 'Anna',
        day: 12,
        month: 6,
        year: 2001,
        note: 'Torta',
        reminderDaysBefore: null,
      ),
    );

    final backup = await first.createBackupJson();
    expect(first.inspectBackup(backup).birthdayCount, 1);
    first.dispose();

    final second = AgendaStore();
    await second.load();
    expect(second.birthdays, hasLength(1));
    expect(second.birthdays.single.name, 'Anna');
    expect(second.birthdays.single.note, 'Torta');
    second.dispose();
  });

  test('Day Hub combines agenda birthday and diary without duplicate models',
      () async {
    final store = AgendaStore();
    await store.load();
    final day = DateTime(2026, 10, 10);

    await store.upsert(
      AgendaItem(
        id: 'day-task',
        title: 'Preparare regalo',
        note: '',
        date: day,
        type: ItemType.task,
      ),
    );
    await store.upsert(
      AgendaItem(
        id: 'day-event',
        title: 'Cena',
        note: '',
        date: day,
        type: ItemType.appointment,
        start: const TimeOfDay(hour: 20, minute: 0),
      ),
    );
    await store.saveBirthday(
      const BirthdayEntry(
        id: 'birthday',
        name: 'Marta',
        day: 10,
        month: 10,
        year: 2000,
        reminderDaysBefore: null,
      ),
    );
    await store.saveJournal(
      day,
      const DayJournal(beautiful: 'Una bella giornata'),
    );

    final snapshot = store.dayHubSnapshot(day);
    expect(snapshot.agenda, hasLength(2));
    expect(snapshot.pendingTaskCount, 1);
    expect(snapshot.appointmentCount, 1);
    expect(snapshot.birthdays.single.birthday.name, 'Marta');
    expect(snapshot.hasJournalContent, isTrue);
    store.dispose();
  });

  test('birthday lifecycle uses the same Trash and restore contract', () async {
    final store = AgendaStore();
    await store.load();
    await store.saveBirthday(
      const BirthdayEntry(
        id: 'trash-birthday',
        name: 'Luca',
        day: 4,
        month: 11,
        reminderDaysBefore: null,
      ),
    );

    expect(await store.moveBirthdayToTrash('trash-birthday'), isTrue);
    expect(store.birthdays, isEmpty);
    expect(store.trash.single.kind, TrashEntityKind.birthday);

    expect(await store.restoreTrashEntry(store.trash.single.id), isTrue);
    expect(store.trash, isEmpty);
    expect(store.birthdays.single.name, 'Luca');
    store.dispose();
  });

  test('birthdays remain isolated across account profiles', () async {
    final store = AgendaStore();
    await store.load();
    await store.activateCloudAccount('day-hub-a');
    await store.saveBirthday(
      const BirthdayEntry(
        id: 'birthday-a',
        name: 'Profilo A',
        day: 1,
        month: 5,
        reminderDaysBefore: null,
      ),
    );

    await store.activateCloudAccount('day-hub-b');
    expect(store.birthdays, isEmpty);
    await store.saveBirthday(
      const BirthdayEntry(
        id: 'birthday-b',
        name: 'Profilo B',
        day: 2,
        month: 5,
        reminderDaysBefore: null,
      ),
    );

    await store.activateCloudAccount('day-hub-a');
    expect(store.birthdays.map((value) => value.id), ['birthday-a']);
    store.dispose();
  });
}
