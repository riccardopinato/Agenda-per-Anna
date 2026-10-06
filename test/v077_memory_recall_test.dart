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

  test('Memory Recall derives deterministic historical resurfacing', () async {
    final store = AgendaStore();
    await store.load();
    await store.savePerson(const PersonEntry(id: 'anna', name: 'Anna'));
    await store.savePerson(const PersonEntry(id: 'luca', name: 'Luca'));

    Future<void> add(DateTime day, DiaryBlock block) async {
      await store.saveJournal(day, DayJournal(blocks: [block]));
    }

    await add(
      DateTime(2026, 9, 29),
      DiaryBlock(
        id: 'today',
        type: DiaryBlockType.note,
        createdAt: DateTime(2026, 9, 29, 12),
        text: 'Oggi',
        personIds: const ['anna'],
      ),
    );
    await add(
      DateTime(2025, 9, 29),
      DiaryBlock(
        id: 'anniversary',
        type: DiaryBlockType.photo,
        createdAt: DateTime(2025, 9, 29, 12),
        text: 'Foto insieme',
        personIds: const ['anna'],
        places: const [DiaryPlaceReference(name: 'Campo Tures')],
      ),
    );
    await add(
      DateTime(2024, 9, 15),
      DiaryBlock(
        id: 'same-month',
        type: DiaryBlockType.note,
        createdAt: DateTime(2024, 9, 15, 12),
        text: 'Settembre insieme',
        personIds: const ['anna'],
        places: const [DiaryPlaceReference(name: 'Campo Tures')],
      ),
    );
    await add(
      DateTime(2023, 2, 3),
      DiaryBlock(
        id: 'older',
        type: DiaryBlockType.note,
        createdAt: DateTime(2023, 2, 3, 12),
        text: 'Roma',
        personIds: const ['luca'],
        places: const [DiaryPlaceReference(name: 'Roma')],
      ),
    );
    await add(
      DateTime(2022, 9, 29),
      DiaryBlock(
        id: 'archived',
        type: DiaryBlockType.note,
        createdAt: DateTime(2022, 9, 29, 12),
        text: 'Archiviato',
        archived: true,
      ),
    );

    final recall = store.memoryRecallSnapshot(DateTime(2026, 9, 29));

    expect(recall.onThisDay.map((entry) => entry.block.id), ['anniversary']);
    expect(
      recall.sameMonthPastYears.map((entry) => entry.block.id),
      ['same-month'],
    );
    expect(
      recall.yearHighlights.map((entry) => entry.block.id),
      ['anniversary', 'same-month', 'older'],
    );
    expect(recall.people.first.label, 'Anna');
    expect(recall.people.first.count, 2);
    expect(recall.places.first.label, 'Campo Tures');
    expect(recall.places.first.count, 2);
    expect(
      recall.yearHighlights.map((entry) => entry.block.id),
      isNot(contains('archived')),
    );
    expect(
      recall.yearHighlights.map((entry) => entry.block.id),
      isNot(contains('today')),
    );

    store.dispose();
  });

  test('filtered Ricordi can feed the same recall projection', () async {
    final store = AgendaStore();
    await store.load();

    await store.saveJournal(
      DateTime(2025, 9, 29),
      DayJournal(
        blocks: [
          DiaryBlock(
            id: 'photo',
            type: DiaryBlockType.photo,
            createdAt: DateTime(2025, 9, 29, 10),
          ),
          DiaryBlock(
            id: 'note',
            type: DiaryBlockType.note,
            createdAt: DateTime(2025, 9, 29, 11),
          ),
        ],
      ),
    );

    final photos = store
        .memoryReferences()
        .where((reference) => reference.block.type == DiaryBlockType.photo);
    final recall = store.memoryRecallSnapshot(
      DateTime(2026, 9, 29),
      references: photos,
    );

    expect(recall.onThisDay.map((entry) => entry.block.id), ['photo']);
    expect(recall.yearHighlights.map((entry) => entry.block.id), ['photo']);

    store.dispose();
  });

  test('v0.77 remains derived with no parallel Memory persistence', () {
    final search =
        File('lib/src/search_connections_domain.dart').readAsStringSync();
    final memories =
        File('lib/src/diary/diary_memories.dart').readAsStringSync();
    final planner = File('lib/src/planner_views.dart').readAsStringSync();
    final store = File('lib/src/agenda_store.dart').readAsStringSync();

    expect(search, contains('MemoryRecallSnapshot memoryRecallSnapshot('));
    expect(search, contains('List<DiaryBlockReference> yearHighlights'));
    expect(memories, contains('v100Rediscover'));
    expect(memories, contains('memoryRecallSnapshot('));
    expect(planner, contains('memoryRecallSnapshot(day)'));
    expect(planner, contains('strings.onThisDay'));

    for (final forbidden in [
      'memory_engine',
      'memories_v2',
      'memory_recall_v1',
      'life_core',
      'embedding_index',
    ]) {
      expect(store.toLowerCase(), isNot(contains(forbidden)));
    }
  });
}
