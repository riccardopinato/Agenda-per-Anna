import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:agenda_per_anna/main.dart';

void main() {
  test('Oggi R3 arrows use civil dates across DST and year boundaries', () {
    expect(addCivilDays(DateTime(2026, 3, 29), 1),
        DateTime(2026, 3, 30));
    expect(addCivilDays(DateTime(2026, 12, 31), 1),
        DateTime(2027, 1, 1));
    expect(addCivilDays(DateTime(2027, 1, 1), -1),
        DateTime(2026, 12, 31));
    final today = File('lib/src/planner_views.dart').readAsStringSync();
    expect(today, contains("identifier: 'today-date-prev'"));
    expect(today, contains("identifier: 'today-date-next'"));
    expect(today, contains('if (!widget.embedded) _DayOpeningCard(date: day)'));
    expect(today, contains('_dailyQuote(day, strings).$2'));
  });

  test('pinned Inbox headings do not skip, duplicate or reorder entries', () {
    expect(List.generate(3, (i) => inboxPinnedListEntryIndex(i, 0, 3)),
        [0, 1, 2]);
    expect(List.generate(4, (i) => inboxPinnedListEntryIndex(i, 3, 3)),
        [-1, 0, 1, 2]);
    expect(List.generate(6, (i) => inboxPinnedListEntryIndex(i, 2, 4)),
        [-1, 0, 1, -2, 2, 3]);
    for (final code in ['it','en','es','fr','pt']) {
      expect(approvedInboxSectionTitle(code, true), isNotEmpty);
      expect(approvedInboxSectionTitle(code, false), isNotEmpty);
      for (final key in ['try','help','detail','reset']) {
        expect(approvedSearchExampleCopy(code, key), isNotEmpty);
      }
      expect(approvedSearchExampleTerms(code), hasLength(3));
    }
  });

  test('R1 search sample and reset operate on the real canonical state', () {
    final source =
        File('lib/src/search_connections_domain.dart').readAsStringSync();
    expect(source, contains("key: const ValueKey('approved-search-query')"));
    expect(source, contains("_queryController.text = text"));
    expect(source, contains("onPressed: () => _trySearchExample(term)"));
    expect(source, contains("key: const ValueKey('search-reset-filters')"));
    expect(source, contains('selectedKinds.clear();'));
    expect(source, contains('includeArchived = false;'));
    expect(source, contains('sortOrder = ApprovedSearchSort.newest;'));
    expect(source, contains('widget.store.approvedPersonalSearch('));
  });

  test('pinned headings and favorites preserve existing action owners', () {
    final source =
        File('lib/src/screens/home_inbox_search.dart').readAsStringSync();
    final favorites = File('lib/src/quick_wins2.dart').readAsStringSync();
    expect(source, contains("inboxPinnedListEntryIndex("));
    expect(source, contains("'inbox-section-pinned'"));
    expect(source, contains("'inbox-section-other'"));
    expect(source, contains('final proposals = Cap0160TagSuggester.forInbox('));
    expect(source, contains('await store.toggleInboxPinned(entry.id);'));
    expect(favorites, contains('AppModule.sharedSpace => Icons.groups_outlined'));
    expect(favorites, contains('AppModule.sharedSpace,'));
  });
}
