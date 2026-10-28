import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Memories B shows true-media hero before exploration shortcuts', () {
    final source =
        File('lib/src/diary/diary_memories.dart').readAsStringSync();
    final screen = source.split('class _DiaryMemoriesScreenState')[1];
    final forYou = screen.split('Widget _forYouView(')[1]
        .split('Widget _timelineMemoryCard(')[0];
    final featured = forYou.indexOf('_forYouHero(context, hero)');
    final map = forYou.indexOf("identifier: 'memories-memory-map-entry'");
    expect(featured, greaterThan(0));
    expect(map, greaterThan(featured));
    expect(forYou, contains('AnnaJournalPageHeader('));
    expect(forYou, contains('editorial: true'));
  });

  test('Text/voice hero cannot become fabricated photo or blank gradient', () {
    final source =
        File('lib/src/diary/diary_memories.dart').readAsStringSync();
    final hero = source.split('Widget _forYouHero(')[1]
        .split('Future<void> _showMemoryMap(')[0];
    expect(hero, contains('DiaryBlockType.photo'));
    expect(hero, contains('DiaryBlockType.sketch'));
    expect(hero, contains('if (!visual)'));
    expect(hero, contains("'memories-editorial-hero'"));
    expect(hero, contains('AnnaJournalCard('));
    expect(hero, contains('MaterialType.transparency'));
    expect(hero, contains('child: InkWell('));
    expect(hero, contains('AnnaJournalTypography.editorial('));
    expect(hero, contains('_coverPreview(context, record)'));
    expect(hero, contains('onTap: () => _openRecord(record)'));
  });

  test('Search, filters, map, collections and timeline remain available', () {
    final source =
        File('lib/src/diary/diary_memories.dart').readAsStringSync();
    for (final id in [
      'memories-for-you',
      'memories-timeline',
      'memories-browse',
      'memories-for-you-hero',
      'memories-memory-map-entry',
      'memories-collections-entry',
      'memories-timeline-surface',
    ]) {
      expect(source, contains(id));
    }
    expect(source, contains('searchController'));
    expect(source, contains('_showFilterSheet'));
  });
}
