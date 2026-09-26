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

  test('person anniversary remains backward compatible and persistent', () {
    final legacy = PersonEntry.fromJson({
      'id': 'legacy',
      'name': 'Anna',
    });
    expect(legacy.anniversaryDate, isNull);

    final person = PersonEntry(
      id: 'anna',
      name: 'Anna',
      anniversaryDate: DateTime(2022, 2, 14),
    );
    final restored = PersonEntry.fromJson(person.toJson());
    expect(restored.anniversaryDate, DateTime(2022, 2, 14));
  });

  test('next anniversary is civil-calendar safe', () async {
    final store = AgendaStore();
    await store.load();
    final person = PersonEntry(
      id: 'leap',
      name: 'Leap',
      anniversaryDate: DateTime(2020, 2, 29),
    );

    expect(
      store.nextAnniversaryForPerson(
        person,
        from: DateTime(2027, 2, 28),
      ),
      DateTime(2027, 2, 28),
    );
    expect(
      store.nextAnniversaryForPerson(
        person,
        from: DateTime(2027, 3, 1),
      ),
      DateTime(2028, 2, 29),
    );
    store.dispose();
  });

  test('relationship snapshot combines linked memories and on-this-day', () async {
    final store = AgendaStore();
    await store.load();
    const person = PersonEntry(
      id: 'anna',
      name: 'Anna',
      relationship: 'Compagna',
    );
    await store.savePerson(person);

    await store.saveJournal(
      DateTime(2024, 9, 26),
      DayJournal(
        blocks: [
          DiaryBlock(
            id: 'old',
            type: DiaryBlockType.note,
            createdAt: DateTime(2024, 9, 26, 10),
            text: 'Giornata insieme',
            personIds: const ['anna'],
          ),
        ],
      ),
    );
    await store.saveJournal(
      DateTime(2026, 9, 20),
      DayJournal(
        blocks: [
          DiaryBlock(
            id: 'recent',
            type: DiaryBlockType.note,
            createdAt: DateTime(2026, 9, 20, 18),
            text: 'Cena',
            personIds: const ['anna'],
          ),
        ],
      ),
    );

    final snapshot = store.relationshipSnapshot(
      person,
      now: DateTime(2026, 9, 26),
    );
    expect(snapshot.memoryCount, 2);
    expect(snapshot.onThisDay.map((entry) => entry.block.id), ['old']);
    expect(snapshot.firstMemoryDate, DateTime(2024, 9, 26));
    expect(snapshot.lastMemoryDate, DateTime(2026, 9, 20));
    store.dispose();
  });

  test('archived diary blocks stay out of on-this-day relationship memories',
      () async {
    final store = AgendaStore();
    await store.load();
    await store.saveJournal(
      DateTime(2025, 9, 26),
      DayJournal(
        blocks: [
          DiaryBlock(
            id: 'archived',
            type: DiaryBlockType.note,
            createdAt: DateTime(2025, 9, 26),
            text: 'Archiviato',
            archived: true,
            personIds: const ['anna'],
          ),
        ],
      ),
    );

    expect(
      store.onThisDayMemories(
        DateTime(2026, 9, 26),
        personId: 'anna',
      ),
      isEmpty,
    );
    store.dispose();
  });
}
