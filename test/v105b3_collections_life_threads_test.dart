import 'dart:convert';
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

  test('v1.05-B3 saved collections persist criteria but derive live results',
      () async {
    final store = AgendaStore();
    await store.load();
    store.people.add(
      const PersonEntry(
        id: 'anna',
        name: 'Anna',
      ),
    );

    Future<void> add(DateTime day, String id, String place) async {
      await store.saveJournal(
        day,
        DayJournal(
          blocks: [
            DiaryBlock(
              id: id,
              type: DiaryBlockType.note,
              createdAt: day.add(const Duration(hours: 12)),
              text: 'memory $id',
              personIds: const ['anna'],
              places: [DiaryPlaceReference(name: place)],
              tags: const ['viaggio'],
            ),
          ],
        ),
      );
    }

    await add(DateTime(2026, 1, 10), 'one', 'Padova');
    await add(DateTime(2026, 2, 10), 'two', 'Padova');
    await add(DateTime(2025, 2, 10), 'old', 'Venezia');

    const definition = MemoryCollectionDefinition(
      id: 'collection-anna-2026',
      name: 'Anna 2026',
      personId: 'anna',
      year: 2026,
    );
    await store.saveMemoryCollection(definition);

    final results = store.memoryCollectionReferences(definition);
    expect(results.map((entry) => entry.block.id), ['two', 'one']);

    final encoded = jsonEncode(store.preferences.toJson());
    expect(encoded, contains('collection-anna-2026'));
    expect(encoded, contains('Anna 2026'));
    expect(encoded, isNot(contains('memory one')));
    expect(encoded, isNot(contains('memory two')));

    await store.saveJournal(
      DateTime(2026, 3, 10),
      DayJournal(
        blocks: [
          DiaryBlock(
            id: 'three',
            type: DiaryBlockType.photo,
            createdAt: DateTime(2026, 3, 10, 12),
            text: 'new canonical memory',
            personIds: const ['anna'],
          ),
        ],
      ),
    );
    expect(
      store
          .memoryCollectionReferences(definition)
          .map((entry) => entry.block.id),
      ['three', 'two', 'one'],
    );

    store.dispose();
  });

  test('v1.05-B3 Life Threads derive recurring people places and tags', () async {
    final store = AgendaStore();
    await store.load();
    store.people.add(const PersonEntry(id: 'anna', name: 'Anna'));

    Future<void> add(DateTime day, String id) async {
      await store.saveJournal(
        day,
        DayJournal(
          blocks: [
            DiaryBlock(
              id: id,
              type: DiaryBlockType.note,
              createdAt: day.add(const Duration(hours: 12)),
              personIds: const ['anna'],
              places: const [DiaryPlaceReference(name: 'Torino')],
              tags: const ['weekend'],
            ),
          ],
        ),
      );
    }

    await add(DateTime(2026, 4, 1), 'a');
    await add(DateTime(2026, 5, 1), 'b');

    final threads = store.memoryLifeThreads();

    expect(
      threads.where((thread) => thread.kind == MemoryLifeThreadKind.person)
          .single
          .count,
      2,
    );
    expect(
      threads.where((thread) => thread.kind == MemoryLifeThreadKind.place)
          .single
          .label,
      'Torino',
    );
    expect(
      threads.where((thread) => thread.kind == MemoryLifeThreadKind.tag)
          .single
          .label,
      '#weekend',
    );

    store.dispose();
  });

  test('v1.05-B3 preference roundtrip is backward-compatible and bounded', () {
    const definition = MemoryCollectionDefinition(
      id: 'c1',
      name: 'Trips',
      place: 'Torino',
      type: DiaryBlockType.photo,
      year: 2026,
    );
    final encoded = const AgendaPreferences(
      memoryCollections: [definition],
    ).toJson();
    final decoded = AgendaPreferences.fromJson(encoded);

    expect(decoded.memoryCollections, hasLength(1));
    expect(decoded.memoryCollections.single.id, 'c1');
    expect(decoded.memoryCollections.single.place, 'Torino');
    expect(decoded.memoryCollections.single.type, DiaryBlockType.photo);
    expect(decoded.memoryCollections.single.year, 2026);

    final legacy = AgendaPreferences.fromJson(const {});
    expect(legacy.memoryCollections, isEmpty);
  });

  test('v1.05-B3 keeps canonical diary ownership and trusted entry points', () {
    final domain =
        File('lib/src/memory_collections_domain.dart').readAsStringSync();
    final screen =
        File('lib/src/screens/memory_collections_screen.dart').readAsStringSync();
    final memories =
        File('lib/src/diary/diary_memories.dart').readAsStringSync();
    final agendaStore = File('lib/src/agenda_store.dart').readAsStringSync();
    final flow = File('.maestro/journey/memories.yaml').readAsStringSync();

    expect(domain, contains('memoryReferences()'));
    expect(domain, contains('preferences.memoryCollections'));
    expect(domain, contains('savePreferences('));
    expect(memories, contains("identifier: 'memories-collections-entry'"));
    expect(screen, contains("identifier: 'memory-collections-surface'"));
    expect(screen, contains('recordsBuilder: ()'));
    expect(screen, contains('animation: store.journalRevision'));
    expect(screen, contains('invalidYear'));
    expect(
      agendaStore,
      contains("payload.containsKey('memoryCollections')"),
    );
    expect(flow, contains("id: 'memories-collections-entry'"));
    expect(flow, contains("id: 'memory-collections-surface'"));

    for (final forbidden in const [
      'MemoryCollectionDatabase',
      'MemoryCollectionRepository',
      'LifeThreadDatabase',
      'collectionMemoryCopies',
      'persistLifeThread',
    ]) {
      expect(domain, isNot(contains(forbidden)));
      expect(screen, isNot(contains(forbidden)));
    }
  });

  test('v1.05-B3 labels resolve in every supported language', () {
    for (final code in const ['en', 'it', 'es', 'fr', 'pt']) {
      final strings = AnnaStrings(code);
      expect(strings.v105Collections, isNotEmpty);
      expect(strings.v105LifeThreads, isNotEmpty);
      expect(strings.v105CollectionsIntro, isNotEmpty);
      expect(strings.v105LifeThreadsIntro, isNotEmpty);
      expect(strings.v105NewCollection, isNotEmpty);
      expect(strings.v105ChooseFilter, isNotEmpty);
      expect(strings.v105InvalidYear, isNotEmpty);
      expect(strings.v105MemoryCount(2), isNotEmpty);
    }
  });
}
