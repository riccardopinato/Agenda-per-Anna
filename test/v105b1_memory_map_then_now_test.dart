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

  test('v1.05-B1 derives place clusters and Then & Now deterministically',
      () async {
    final store = AgendaStore();
    await store.load();

    Future<void> add(
      DateTime day,
      String id,
      DiaryPlaceReference place,
    ) async {
      await store.saveJournal(
        day,
        DayJournal(
          blocks: [
            DiaryBlock(
              id: id,
              type: DiaryBlockType.note,
              createdAt: day.add(const Duration(hours: 12)),
              text: id,
              places: [place],
            ),
          ],
        ),
      );
    }

    await add(
      DateTime(2022, 8, 10),
      'old-braies',
      const DiaryPlaceReference(
        name: 'Lago di Braies',
        latitude: 46.6947,
        longitude: 12.0859,
      ),
    );
    await add(
      DateTime(2026, 8, 10),
      'new-braies',
      const DiaryPlaceReference(name: 'Lago di Braies'),
    );
    await add(
      DateTime(2025, 5, 4),
      'roma',
      const DiaryPlaceReference(name: 'Roma'),
    );

    final snapshot = store.memoryMapSnapshot();

    expect(snapshot.places, hasLength(2));
    final braies =
        snapshot.places.firstWhere((place) => place.key == 'lago di braies');
    expect(braies.count, 2);
    expect(braies.hasCoordinates, isTrue);
    expect(braies.firstMemory.block.id, 'old-braies');
    expect(braies.latestMemory.block.id, 'new-braies');

    expect(snapshot.thenNow, hasLength(1));
    expect(snapshot.thenNow.single.place.key, 'lago di braies');
    expect(snapshot.thenNow.single.thenMemory.block.id, 'old-braies');
    expect(snapshot.thenNow.single.nowMemory.block.id, 'new-braies');
    expect(snapshot.thenNow.single.yearsApart, 4);

    store.dispose();
  });

  test('v1.05-B1 remains derived with no parallel Memory or Places store', () {
    final domain =
        File('lib/src/search_connections_domain.dart').readAsStringSync();
    final store = File('lib/src/agenda_store.dart').readAsStringSync();
    final models = File('lib/src/domain_models.dart').readAsStringSync();

    expect(domain, contains('MemoryMapSnapshot memoryMapSnapshot('));
    expect(domain, contains('class MemoryPlaceCluster'));
    expect(domain, contains('class MemoryThenNowPair'));
    expect(models, contains('class DiaryPlaceReference'));

    for (final forbidden in const [
      'MemoryMapDatabase',
      'MemoryMapRepository',
      'then_now_store',
      'places_map_v1',
    ]) {
      expect(domain, isNot(contains(forbidden)));
      expect(store, isNot(contains(forbidden)));
    }
  });

  test('v1.05-B1 exposes stable map and temporal semantics', () {
    final source =
        File('lib/src/diary/diary_memories.dart').readAsStringSync();

    for (final id in const [
      'memories-memory-map-entry',
      'memory-map-surface',
      'memory-map-canvas',
      'memories-then-now-entry',
      'memories-then-now-surface',
    ]) {
      expect(source, contains("identifier: '$id'"));
    }
  });

  test('v1.05-B1 labels resolve in all supported languages', () {
    for (final code in const ['en', 'it', 'es', 'fr', 'pt']) {
      final strings = AnnaStrings(code);
      for (final key in const [
        'memoryMapTitle',
        'memoryMapIntro',
        'memoryMapSummary',
        'memoryMapNoPlaces',
        'memoryMapNoCoordinates',
        'thenNowTitle',
        'thenNowIntro',
        'thenNowEmpty',
        'thenNowThen',
        'thenNowNow',
        'thenNowYears',
      ]) {
        expect(strings.d3(key), isNotEmpty);
      }
    }
  });

  test('v1.05-B1 trusted journey reaches both new surfaces', () {
    final flow = File('.maestro/journey/memories.yaml').readAsStringSync();
    expect(flow, contains("id: 'memories-memory-map-entry'"));
    expect(flow, contains("id: 'memory-map-surface'"));
    expect(flow, contains("id: 'memories-then-now-entry'"));
    expect(flow, contains("id: 'memories-then-now-surface'"));
  });
}
