import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:agenda_per_anna/main.dart';

void main() {
  test('v1.05-B4 keeps recall projections bounded and canonical', () {
    final search =
        File('lib/src/search_connections_domain.dart').readAsStringSync();
    final collections =
        File('lib/src/memory_collections_domain.dart').readAsStringSync();
    final year = File('lib/src/year_review_domain.dart').readAsStringSync();

    expect(search, contains('if (forYou.length >= 8'));
    expect(search, contains('MemoryMapSnapshot memoryMapSnapshot('));
    expect(collections, contains('return List.unmodifiable(threads.take(24))'));
    expect(collections, contains('memoryReferences()'));
    expect(year, contains('memoryReferences()'));
    expect(year, contains('lifeArchiveEntries('));
    expect(
      year,
      contains('entry.diaryReference!.date'),
      reason: 'Diary annual bucketing must use the canonical journal day.',
    );

    for (final forbidden in const [
      'MemoryDatabase',
      'MemoryRepository',
      'YearDatabase',
      'YearRepository',
      'LifeThreadDatabase',
      'MemoryCollectionDatabase',
      'embedding_index',
      'generativeNarrator',
    ]) {
      expect(search, isNot(contains(forbidden)));
      expect(collections, isNot(contains(forbidden)));
      expect(year, isNot(contains(forbidden)));
    }
  });

  test('v1.05-B4 accessibility keeps every recall destination selectable', () {
    final memories =
        File('lib/src/diary/diary_memories.dart').readAsStringSync();
    final collections = File(
      'lib/src/screens/memory_collections_screen.dart',
    ).readAsStringSync();
    final planner = File('lib/src/planner_views.dart').readAsStringSync();

    for (final id in const [
      'memories-for-you',
      'memories-timeline',
      'memories-browse',
      'memories-for-you-surface',
      'memories-timeline-surface',
      'memories-memory-map-entry',
      'memories-then-now-entry',
      'memories-collections-entry',
      'memory-map-located-list',
    ]) {
      expect(memories, contains("'$id'"));
    }

    expect(
      collections,
      contains("identifier: 'memory-collections-surface'"),
    );
    expect(planner, contains("identifier: 'year-review-surface'"));
  });

  test('v1.05-B4 localization resolves B2 and B3 copy in five languages', () {
    for (final code in const ['en', 'it', 'es', 'fr', 'pt']) {
      final strings = AnnaStrings(code);

      expect(strings.v105YearReview, isNotEmpty);
      expect(strings.v105YearReviewSubtitle, isNotEmpty);
      expect(strings.v105Highlights, isNotEmpty);
      expect(strings.v105RecurringPeople, isNotEmpty);
      expect(strings.v105RecurringPlaces, isNotEmpty);
      expect(strings.v105ActiveMonths, isNotEmpty);
      expect(strings.v105LifeMoments, isNotEmpty);

      expect(strings.v105Collections, isNotEmpty);
      expect(strings.v105LifeThreads, isNotEmpty);
      expect(strings.v105CollectionsIntro, isNotEmpty);
      expect(strings.v105LifeThreadsIntro, isNotEmpty);
      expect(strings.v105NewCollection, isNotEmpty);
      expect(strings.v105CollectionName, isNotEmpty);
      expect(strings.v105AnyPerson, isNotEmpty);
      expect(strings.v105AnyPlace, isNotEmpty);
      expect(strings.v105AnyType, isNotEmpty);
      expect(strings.v105OptionalTag, isNotEmpty);
      expect(strings.v105OptionalYear, isNotEmpty);
      expect(strings.v105ChooseFilter, isNotEmpty);
      expect(strings.v105InvalidYear, isNotEmpty);
      expect(strings.v105NoCollections, isNotEmpty);
      expect(strings.v105NoThreads, isNotEmpty);
    }
  });

  test('v1.05-B4 trusted journeys cover Memories and Year in Review', () {
    final memoriesFlow =
        File('.maestro/journey/memories.yaml').readAsStringSync();
    final calendarFlow =
        File('.maestro/journey/calendar.yaml').readAsStringSync();

    for (final id in const [
      'memories-for-you-surface',
      'memories-timeline-surface',
      'memory-map-surface',
      'memories-then-now-entry',
      'memory-collections-surface',
    ]) {
      expect(memoriesFlow, contains("id: '$id'"));
    }

    expect(calendarFlow, contains("id: 'calendar-open-year-overview'"));
    expect(calendarFlow, contains("id: 'year-review-surface'"));
  });

  test('v1.05-B4 collections stay live and inside existing sync ownership', () {
    final screen = File(
      'lib/src/screens/memory_collections_screen.dart',
    ).readAsStringSync();
    final store = File('lib/src/agenda_store.dart').readAsStringSync();
    final preferences = File('lib/src/domain_models.dart').readAsStringSync();

    expect(screen, contains('recordsBuilder: ()'));
    expect(screen, contains('animation: Listenable.merge(['));
    expect(screen, contains('widget.store.settingsRevision'));
    expect(screen, contains('widget.store.journalRevision'));
    expect(screen, contains('if (mounted) setState(() {})'));
    expect(screen, contains('invalidYear'));
    expect(store, contains("payload.containsKey('memoryCollections')"));
    expect(preferences, contains('memoryCollections'));

    for (final forbidden in const [
      'MemoryCollectionDatabase',
      'MemoryCollectionRepository',
      'LifeThreadDatabase',
      'collectionMemoryCopies',
      'persistLifeThread',
    ]) {
      expect(screen, isNot(contains(forbidden)));
      expect(store, isNot(contains(forbidden)));
    }
  });

  test('v1.05-B4 documentation and Factory baseline are coherent', () {
    final agents = File('AGENTS.md').readAsStringSync();
    final roadmap = File('docs/ROADMAP.md').readAsStringSync();
    final architecture = File('docs/ARCHITECTURE.md').readAsStringSync();
    final readme = File('README.md').readAsStringSync();
    final bible = File('docs/PRODUCT_BIBLE.md').readAsStringSync();

    expect(
      agents,
      contains('ed6466e774a28e95f9f371cd56bbf7278428776a'),
    );
    expect(agents, contains('Master v26.6'));
    expect(roadmap, contains('v1.05-B4'));
    expect(roadmap, contains('integration PR #132'));
    expect(architecture, contains('No Memory DB, Year DB, Collections DB'));
    expect(
      architecture,
      isNot(contains(
        'Memory Map, Then & Now, Year in Review 2.0, Collections and Life Threads are\n  explicitly deferred',
      )),
    );
    expect(readme, contains('## v1.05 — Memories & Recall 3.0'));
    expect(bible, contains('v1.05 Memories & Recall 3.0'));
  });
}
