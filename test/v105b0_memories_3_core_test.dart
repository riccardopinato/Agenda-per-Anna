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

  test('v1.05-B0 For You is deterministic, bounded and deduplicated', () async {
    final store = AgendaStore();
    await store.load();

    Future<void> add(
      DateTime day,
      String id, {
      DiaryBlockType type = DiaryBlockType.note,
      bool archived = false,
    }) async {
      await store.saveJournal(
        day,
        DayJournal(
          blocks: [
            DiaryBlock(
              id: id,
              type: type,
              createdAt: day.add(const Duration(hours: 12)),
              text: id,
              archived: archived,
            ),
          ],
        ),
      );
    }

    await add(
      DateTime(2025, 10, 26),
      'same-day',
      type: DiaryBlockType.photo,
    );
    await add(DateTime(2024, 10, 10), 'same-month');
    await add(DateTime(2023, 5, 1), 'year-highlight');
    await add(DateTime(2022, 10, 26), 'archived', archived: true);
    await add(DateTime(2026, 10, 26), 'anchor-day');

    final recall = store.memoryRecallSnapshot(DateTime(2026, 10, 26));

    expect(
      recall.forYou.map((entry) => entry.block.id),
      ['same-day', 'same-month', 'year-highlight'],
    );
    expect(
      recall.forYou.map((entry) => entry.block.id).toSet().length,
      recall.forYou.length,
    );
    expect(recall.forYou.length, lessThanOrEqualTo(8));
    expect(recall.forYou.map((entry) => entry.block.id), isNot(contains('archived')));
    expect(recall.forYou.map((entry) => entry.block.id), isNot(contains('anchor-day')));

    store.dispose();
  });

  test('v1.05-B0 keeps one derived memory projection with no Memory DB', () {
    final domain =
        File('lib/src/search_connections_domain.dart').readAsStringSync();
    final store = File('lib/src/agenda_store.dart').readAsStringSync();

    expect(domain, contains('final List<DiaryBlockReference> forYou'));
    expect(domain, contains('void addForYou('));
    expect(domain, contains('addForYou(onThisDay, 3)'));
    expect(domain, contains('addForYou(sameMonthPastYears, 3)'));
    expect(domain, contains('addForYou(yearHighlights, 6)'));

    for (final forbidden in const [
      'MemoryDatabase',
      'MemoryRepository',
      'memory_db',
      'memory_engine_v3',
      'embedding_index',
    ]) {
      expect(store, isNot(contains(forbidden)));
      expect(domain, isNot(contains(forbidden)));
    }
  });

  test('v1.05-B0 promotes For You and Timeline, with filters secondary', () {
    final memories =
        File('lib/src/diary/diary_memories.dart').readAsStringSync();
    final components =
        File('lib/src/diary/diary_components.dart').readAsStringSync();

    expect(
      components,
      contains(
        'enum _DiaryMemoriesView { forYou, timeline, days, months, years }',
      ),
    );
    expect(memories, contains("identifier: 'memories-for-you'"));
    expect(memories, contains("identifier: 'memories-timeline'"));
    expect(memories, contains("identifier: 'memories-browse'"));
    expect(memories, contains("identifier: 'memories-for-you-surface'"));
    expect(memories, contains("identifier: 'memories-timeline-surface'"));
    expect(memories, contains('Future<void> _showBrowseSheet()'));
    expect(memories, contains('Future<void> _showFilterSheet()'));
    expect(memories, contains('bool searchExpanded = false'));
    expect(memories, isNot(contains('_DiaryMemoriesView.rediscover')));
    expect(memories, isNot(contains('_DiaryMemoriesView.memories')));
  });

  test('v1.05-B0 labels resolve in all supported languages', () {
    for (final code in const ['en', 'it', 'es', 'fr', 'pt']) {
      final strings = AnnaStrings(code);
      for (final key in const [
        'memoriesForYou',
        'memoriesTimeline',
        'memoriesBrowse',
        'memoriesForYouIntro',
        'memoriesTimelineIntro',
        'memoriesFeatured',
        'memoriesBrowseBy',
        'memoriesSearchAction',
        'memoriesFilters',
        'memoriesClearFilters',
      ]) {
        expect(strings.d3(key), isNotEmpty);
      }
    }
  });

  test('v1.05-B0 trusted journey covers both primary memory modes', () {
    final flow = File('.maestro/journey/memories.yaml').readAsStringSync();

    for (final id in const [
      'main-nav-memories',
      'memories-for-you',
      'memories-timeline',
      'memories-browse',
      'memories-for-you-surface',
      'memories-timeline-surface',
    ]) {
      expect(flow, contains("id: '$id'"));
    }
  });
}
