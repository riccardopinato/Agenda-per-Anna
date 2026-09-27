import 'dart:io';

import 'package:agenda_per_anna/app_version.dart';
import 'package:agenda_per_anna/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DiaryBlock memory({
    required String id,
    required DateTime createdAt,
    bool archived = false,
    List<String> people = const [],
    List<String> related = const [],
  }) =>
      DiaryBlock(
        id: id,
        type: DiaryBlockType.note,
        createdAt: createdAt,
        text: id,
        archived: archived,
        personIds: people,
        relatedBlockIds: related,
      );

  test('v0.67 Memory Engine is a derived projection over DayJournal', () {
    final store = AgendaStore();
    store.journals['2024-09-27'] = DayJournal(
      blocks: [
        memory(
          id: 'old',
          createdAt: DateTime(2024, 9, 27, 8),
          people: const ['anna'],
        ),
        memory(
          id: 'archived',
          createdAt: DateTime(2024, 9, 27, 9),
          archived: true,
          people: const ['anna'],
        ),
      ],
    );
    store.journals['2026-09-27'] = DayJournal(
      blocks: [
        memory(
          id: 'new',
          createdAt: DateTime(2026, 9, 27, 10),
          related: const ['old'],
        ),
      ],
    );

    expect(
      store.memoryRecords().map((record) => record.block.id),
      ['new', 'old'],
    );
    expect(
      store.memoryRecords(
        includeArchived: true,
        personId: 'anna',
      ).map((record) => record.block.id),
      ['archived', 'old'],
    );

    final snapshot = store.memoryEngineSnapshot(
      anchor: DateTime(2026, 9, 27),
    );
    expect(snapshot.count, 2);
    expect(snapshot.firstMemoryDate, DateTime(2024, 9, 27));
    expect(snapshot.lastMemoryDate, DateTime(2026, 9, 27));
    expect(snapshot.onThisDay.map((record) => record.block.id), ['old']);
  });

  test('v0.67 links and backlinks reuse the same memory projection', () {
    final store = AgendaStore();
    final linked = memory(
      id: 'linked',
      createdAt: DateTime(2025, 1, 2),
    );
    final source = memory(
      id: 'source',
      createdAt: DateTime(2026, 1, 2),
      related: const ['linked'],
    );
    store.journals['2025-01-02'] = DayJournal(blocks: [linked]);
    store.journals['2026-01-02'] = DayJournal(blocks: [source]);

    expect(
      store.relatedMemoryRecords(source).single.block.id,
      'linked',
    );
    expect(
      store.memoryBacklinks('linked').single.block.id,
      'source',
    );

    // Compatibility API is intentionally retained for existing UI/callers.
    expect(
      store.relatedDiaryBlocks(source).single.block.id,
      'linked',
    );
    expect(
      store.backlinksForDiaryBlock('linked').single.block.id,
      'source',
    );
  });

  test('v0.67 existing People memory API delegates to Memory Engine', () {
    final store = AgendaStore();
    store.journals['2023-09-27'] = DayJournal(
      blocks: [
        memory(
          id: 'person-memory',
          createdAt: DateTime(2023, 9, 27, 12),
          people: const ['p1'],
        ),
      ],
    );

    expect(store.memoriesForPerson('p1').single.block.id, 'person-memory');
    expect(
      store.onThisDayMemories(
        DateTime(2026, 9, 27),
        personId: 'p1',
      ).single.block.id,
      'person-memory',
    );
  });

  test('v0.67 Memory Engine introduces no persistence silo', () {
    final source = File('lib/src/memory_engine.dart').readAsStringSync();

    expect(source, contains('Derived, read-only memory layer'));
    expect(source, contains('memoryRecords('));
    expect(source, contains('memoriesOnThisDay('));
    expect(source, contains('relatedMemoryRecords('));
    expect(source, isNot(contains('_persistEntityMutation')));
    expect(source, isNot(contains('LocalStateStore')));
    expect(source, isNot(contains('Supabase')));
  });

  test('v0.67 release metadata is aligned', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(appReleaseVersion, '0.67.0');
    expect(pubspec, contains('version: 0.67.0+77'));
  });
}
