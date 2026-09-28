import 'dart:io';

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

  test('legacy memory payload remains compatible with v0.70', () {
    final block = DiaryBlock.fromJson({
      'id': 'legacy',
      'type': DiaryBlockType.note.name,
      'createdAt': DateTime(2024, 1, 2).toIso8601String(),
      'text': 'Vecchio ricordo',
      'personIds': ['anna'],
      'relatedBlockIds': ['other'],
    });

    expect(block.places, isEmpty);
    expect(block.personIds, ['anna']);
    expect(block.relatedBlockIds, ['other']);
  });

  test('place metadata survives persistence restart and deterministic search',
      () async {
    final day = DateTime(2026, 9, 28);
    final first = AgendaStore();
    await first.load();
    await first.saveJournal(
      day,
      DayJournal(
        blocks: [
          DiaryBlock(
            id: 'place-memory',
            type: DiaryBlockType.note,
            createdAt: DateTime(2026, 9, 28, 12),
            text: 'Passeggiata insieme',
            places: const [
              DiaryPlaceReference(
                name: 'Lago di Braies',
                latitude: 46.6947,
                longitude: 12.0859,
              ),
            ],
          ),
        ],
      ),
    );
    first.dispose();

    final second = AgendaStore();
    await second.load();
    final restored = second.journal(day).blocks.single;
    expect(restored.places.single.name, 'Lago di Braies');
    expect(restored.places.single.latitude, closeTo(46.6947, 0.00001));

    final diaryHits = second.personalSearch(
      'Lago Braies',
      kinds: {PersonalSearchKind.diary},
    );
    expect(diaryHits.map((hit) => hit.diaryBlockId), contains('place-memory'));

    final placeHits = second.personalSearch(
      'Lago Braies',
      kinds: {PersonalSearchKind.place},
    );
    expect(placeHits, hasLength(1));
    expect(placeHits.single.placeName, 'Lago di Braies');
    second.dispose();
  });

  test('place metadata survives existing backup restore path', () async {
    final day = DateTime(2026, 8, 14);
    final source = AgendaStore();
    await source.load();
    await source.saveJournal(
      day,
      DayJournal(
        blocks: [
          DiaryBlock(
            id: 'backup-place',
            type: DiaryBlockType.photo,
            createdAt: day,
            text: 'Vacanza',
            places: const [
              DiaryPlaceReference(
                name: 'Campo Tures',
                latitude: 46.918,
                longitude: 11.955,
              ),
            ],
          ),
        ],
      ),
    );
    final backup = await source.createBackupJson();
    source.dispose();

    await LocalStateStore.instance.resetForTesting();
    SharedPreferences.setMockInitialValues({});

    final restoredStore = AgendaStore();
    await restoredStore.load();
    await restoredStore.restoreBackup(backup, merge: false);

    final place = restoredStore.journal(day).blocks.single.places.single;
    expect(place.name, 'Campo Tures');
    expect(place.longitude, closeTo(11.955, 0.00001));
    restoredStore.dispose();
  });

  test('Trash restore preserves inline place references', () async {
    final day = DateTime(2026, 9, 20);
    final store = AgendaStore();
    await store.load();
    await store.saveJournal(
      day,
      DayJournal(
        blocks: [
          DiaryBlock(
            id: 'trash-place',
            type: DiaryBlockType.note,
            createdAt: day,
            text: 'Ricordo',
            places: const [
              DiaryPlaceReference(
                name: 'Monselice',
                latitude: 45.239,
                longitude: 11.75,
              ),
            ],
          ),
        ],
      ),
    );

    expect(await store.moveDiaryBlockToTrash(day, 'trash-place'), isTrue);
    expect(store.journal(day).blocks, isEmpty);
    expect(store.trash.single.payload['places'], isNotEmpty);

    expect(await store.restoreTrashEntry(store.trash.single.id), isTrue);
    final restored = store.journal(day).blocks.single;
    expect(restored.places.single.name, 'Monselice');
    expect(restored.places.single.hasCoordinates, isTrue);
    store.dispose();
  });

  test('Places Lite remains isolated across account profiles', () async {
    final store = AgendaStore();
    await store.load();
    final day = DateTime(2026, 9, 18);

    await store.activateCloudAccount('places-a');
    await store.saveJournal(
      day,
      DayJournal(
        blocks: [
          DiaryBlock(
            id: 'a',
            type: DiaryBlockType.note,
            createdAt: day,
            places: const [DiaryPlaceReference(name: 'Luogo A')],
          ),
        ],
      ),
    );

    await store.activateCloudAccount('places-b');
    expect(store.memoryReferences(includeArchived: true), isEmpty);
    await store.saveJournal(
      day,
      DayJournal(
        blocks: [
          DiaryBlock(
            id: 'b',
            type: DiaryBlockType.note,
            createdAt: day,
            places: const [DiaryPlaceReference(name: 'Luogo B')],
          ),
        ],
      ),
    );

    await store.activateCloudAccount('places-a');
    expect(store.diaryPlaceNames, ['Luogo A']);
    expect(
      store.memoryReferences(includeArchived: true).single.block.id,
      'a',
    );
    store.dispose();
  });

  test('memory and place architecture has no parallel persistence layer', () {
    final model = File('lib/src/domain_models.dart').readAsStringSync();
    final store = File('lib/src/agenda_store.dart').readAsStringSync();
    final people = File('lib/src/people_domain.dart').readAsStringSync();
    final memories =
        File('lib/src/diary/diary_memories.dart').readAsStringSync();
    final search =
        File('lib/src/search_connections_domain.dart').readAsStringSync();

    expect(model, contains('class DiaryPlaceReference'));
    expect(model, contains('final List<DiaryPlaceReference> places;'));

    expect(search, contains('List<DiaryBlockReference> memoryReferences('));
    expect(search, contains('List<DiaryBlockReference> memoriesForPlace('));
    expect(people, contains('typedef PersonMemoryReference = DiaryBlockReference;'));
    expect(people, isNot(contains('class PersonMemoryReference')));
    expect(memories, isNot(contains('_DiaryMemoryRecord')));

    for (final forbidden in [
      '_placesKey',
      'places_v1',
      'memory_engine',
      'memories_v1',
      'life_core',
      'life_items',
    ]) {
      expect(store.toLowerCase(), isNot(contains(forbidden)));
    }
  });
}
