import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:agenda_per_anna/main.dart';

void main() {
  test('v1.00-B removes the superseded legacy SearchScreen', () {
    final home =
        File('lib/src/screens/home_inbox_search.dart').readAsStringSync();
    expect(home, isNot(contains('class SearchScreen')));
    expect(home, isNot(contains('enum _SearchHitType')));
    expect(home, contains('PersonalSearchConnectionsScreen(store: store)'));
  });

  test('v1.00-B keeps Home focused and moves secondary areas to Explore', () {
    final home =
        File('lib/src/screens/home_inbox_search.dart').readAsStringSync();
    final explore =
        File('lib/src/screens/explore_screen.dart').readAsStringSync();

    expect(home, contains('ExploreScreen(store: store)'));
    expect(home, contains('strings.v100Explore'));
    expect(explore, contains('ShoppingListScreen(store: store)'));
    expect(explore, contains('WorkoutScreen(store: store)'));
    expect(explore, contains('DiaryMemoriesScreen(store: store)'));
    expect(explore, contains('PeopleScreen(store: store)'));
    expect(explore, contains('LifeEcosystemScreen(store: store)'));
  });

  test('v1.00-B core surfaces use the shared localization path', () {
    final home =
        File('lib/src/screens/home_inbox_search.dart').readAsStringSync();
    final memories =
        File('lib/src/diary/diary_memories.dart').readAsStringSync();
    final search =
        File('lib/src/search_connections_domain.dart').readAsStringSync();
    final backup =
        File('lib/src/screens/backup_settings.dart').readAsStringSync();

    expect(home, contains('v100MyAgendaSection'));
    expect(home, contains('v100SharedPhotoTitle'));
    expect(memories, contains('AnnaStrings.intlLocale(context)'));
    expect(memories, isNot(contains("'it_IT'")));
    expect(search, contains('languageCode: strings.languageCode'));
    expect(search, contains('strings.v100SearchKind(kind)'));
    expect(backup, contains('v100BackupData'));
    expect(backup, contains('v100OpenExportDescription'));
  });

  test('v1.00-B localization exposes all supported languages', () {
    for (final code in const ['en', 'it', 'es', 'fr', 'pt']) {
      final strings = AnnaStrings(code);
      expect(strings.v100Explore, isNotEmpty);
      expect(strings.v100SearchConnectTitle, isNotEmpty);
      expect(strings.v100RediscoverTitle, isNotEmpty);
      expect(strings.v100BackupData, isNotEmpty);
      expect(strings.v100OpenExportDescription, isNotEmpty);
    }
    expect(const AnnaStrings('en').v100Explore, 'Explore');
    expect(const AnnaStrings('it').v100Explore, 'Esplora');
  });

  test('long-history projections remain interactive at 10000 memories', () {
    final store = AgendaStore();
    const total = 10000;
    var created = 0;

    for (var dayIndex = 0; created < total; dayIndex++) {
      final day = DateTime(2000, 1, 1).add(Duration(days: dayIndex));
      final blocks = <DiaryBlock>[];
      for (var i = 0; i < 10 && created < total; i++, created++) {
        blocks.add(
          DiaryBlock(
            id: 'memory-$created',
            type: DiaryBlockType.note,
            createdAt: day.add(Duration(minutes: i)),
            text: created == total - 1
                ? 'needle long history target'
                : 'ordinary memory $created',
            tags: [if (created % 20 == 0) 'history'],
          ),
        );
      }
      store.journals[AgendaStore.dateKey(day)] = DayJournal(blocks: blocks);
    }

    final watch = Stopwatch()..start();
    final references = store.memoryReferences();
    final hits = store.personalSearch(
      'needle long history',
      languageCode: 'en',
    );
    final archive = store.lifeArchiveEntries(
      through: DateTime(2100, 1, 1),
      query: 'needle',
    );
    watch.stop();

    expect(references, hasLength(total));
    expect(hits.where((hit) => hit.diaryBlockId != null), hasLength(1));
    expect(archive.where((entry) => entry.kind == LifeArchiveKind.diary),
        hasLength(1));
    expect(
      watch.elapsed,
      lessThan(const Duration(seconds: 10)),
      reason:
          'A 10k-memory personal archive should remain usable without a parallel search database.',
    );
    store.dispose();
  });
}
