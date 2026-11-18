import 'dart:io';

import 'package:agenda_per_anna/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Nov 18 approved mock-up 9/10: Journal search/Inbox filters reuse the
/// existing canonical query/tag/archival callbacks. This is source/widget
/// evidence; live screenshots and device acceptance remain separate.
void main() {
  testWidgets('Journal filter uses native editorial styling, semantics and tap',
      (tester) async {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;

      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.teal,
              brightness: brightness,
            ),
          ),
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                height: 95,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    MediaQuery(
                      data: const MediaQueryData(
                        size: Size(320, 640),
                        textScaler: TextScaler.linear(2),
                      ),
                      child: AnnaOrganicJournalFilterPill(
                        semanticsId: 'n18-journal-filter-test',
                        label: 'Una categoria molto lunga per i ricordi',
                        icon: Icons.bookmark_outline,
                        selected: true,
                        onTap: () => taps++,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      final filter =
          find.byKey(const ValueKey<String>('n18-journal-filter-test'));
      expect(filter, findsOneWidget);
      expect(find.byType(ChoiceChip), findsNothing);
      expect(find.byType(FilterChip), findsNothing);
      expect(tester.getSize(filter).height, greaterThanOrEqualTo(48));
      expect(tester.getSize(filter).width, lessThanOrEqualTo(320));
      expect(tester.takeException(), isNull);

      await tester.tap(filter);
      expect(taps, 1);
      expect(tester.takeException(), isNull);
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  test('Journal-only replacement keeps Classic chips and original owners', () {
    final chrome =
        File('lib/src/organic_journal_chrome.dart').readAsStringSync();
    final search =
        File('lib/src/search_connections_domain.dart').readAsStringSync();
    final inbox =
        File('lib/src/screens/home_inbox_search.dart').readAsStringSync();

    expect(chrome, contains('class AnnaOrganicJournalFilterPill'));
    expect(chrome, contains('AnnaDesignTokens.animationsEnabled(context)'));

    expect(search, contains("'approved-search-journal-all'"));
    expect(search, contains("'approved-search-journal-archived'"));
    expect(search, contains('AnnaOrganicJournalFilterPill('));
    expect(search, contains('ChoiceChip('));
    expect(search, contains('FilterChip('));
    expect(search, contains('widget.store.approvedPersonalSearch('));

    final start = inbox.indexOf('class _InboxScreenState');
    final end = inbox.indexOf('class ArchiveScreen ', start);
    expect(start, greaterThanOrEqualTo(0));
    expect(end, greaterThan(start));
    final inboxScope = inbox.substring(start, end);
    expect(inboxScope, contains("'inbox-journal-category-all'"));
    expect(inboxScope, contains("'inbox-journal-create-category'"));
    expect(inboxScope, contains("'inbox-journal-choose-tag'"));
    expect(inboxScope, contains('AnnaOrganicJournalFilterPill('));
    expect(inboxScope, contains('ChoiceChip('));
    expect(inboxScope, contains('ActionChip('));
    expect(inboxScope, contains('store.inboxEntriesInCategory('));
    expect(inboxScope, contains('store.toggleInboxArchived('));
  });
}
