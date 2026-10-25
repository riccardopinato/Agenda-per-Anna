import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:agenda_per_anna/main.dart';

void main() {
  test('v1.05-A2 uses the four new canonical start destinations', () {
    expect(StartTab.values, <StartTab>[
      StartTab.today,
      StartTab.calendar,
      StartTab.memories,
      StartTab.more,
    ]);

    expect(startTabFromStoredValue('home'), StartTab.today);
    expect(startTabFromStoredValue('month'), StartTab.calendar);
    expect(startTabFromStoredValue('week'), StartTab.calendar);
    expect(startTabFromStoredValue('today'), StartTab.today);
    expect(startTabFromStoredValue('calendar'), StartTab.calendar);
    expect(startTabFromStoredValue('memories'), StartTab.memories);
    expect(startTabFromStoredValue('more'), StartTab.more);
  });

  test('v1.05-A2 primary shell is Today Calendar Memories More', () {
    final shell =
        File('lib/src/screens/home_inbox_search.dart').readAsStringSync();

    for (final page in const <String>[
      'PlannerScreen(store: widget.store)',
      'CalendarHubScreen(store: widget.store)',
      'DiaryMemoriesScreen(store: widget.store)',
      'MoreScreen(store: widget.store)',
    ]) {
      expect(shell, contains(page));
    }

    for (final id in const <String>[
      'main-nav-today',
      'main-nav-calendar',
      'main-nav-memories',
      'main-nav-more',
      'main-rail-today',
      'main-rail-calendar',
      'main-rail-memories',
      'main-rail-more',
    ]) {
      expect(shell, contains(id));
    }

    for (final legacy in const <String>[
      'main-nav-home',
      'main-nav-month',
      'main-nav-week',
      'main-rail-home',
      'main-rail-month',
      'main-rail-week',
    ]) {
      expect(shell, isNot(contains(legacy)));
    }
  });

  test('v1.05-A2 Calendar owns both month and week modes', () {
    final planner = File('lib/src/planner_views.dart').readAsStringSync();

    expect(planner, contains('class CalendarHubScreen'));
    expect(planner, contains('SegmentedButton<_CalendarHubView>'));
    expect(planner, contains('_CalendarHubView.month'));
    expect(planner, contains('_CalendarHubView.week'));
    expect(planner, contains('CalendarScreen('));
    expect(planner, contains('WeekScreen('));
    expect(planner, contains('embedded: true'));
    expect(planner, contains("identifier: 'calendar-open-month-notebook'"));
    expect(planner, contains("identifier: 'calendar-open-year-overview'"));
    expect(planner, contains("'calendar-open-month-notebook'"));
    expect(planner, contains("'calendar-open-year-overview'"));
    expect(planner, contains('MonthScreen(store: widget.store)'));
    expect(planner, contains('YearScreen(store: widget.store)'));
  });

  test('v1.05-A2 More owns all former Home secondary routes', () {
    final more = File('lib/src/screens/more_screen.dart').readAsStringSync();

    for (final id in const <String>[
      'more-search',
      'more-inbox',
      'more-explore',
      'more-personalize',
      'more-shared',
      'more-archive',
      'more-backup',
      'more-cloud',
      'more-settings',
    ]) {
      expect(more, contains("identifier: id"));
      expect(more, contains("id: '$id'"));
    }

    expect(more, contains('_HomeSyncStatusCard(store: store)'));
    expect(more, contains('store.hasStorageWarnings'));
    expect(more, contains('strings.v100StorageWarning'));

    for (final route in const <String>[
      'PersonalSearchConnectionsScreen(store: store)',
      'InboxScreen(store: store)',
      'ExploreScreen(store: store)',
      'PersonalizationScreen(store: store)',
      'SharedSpaceHubScreen(store: store)',
      'ArchiveScreen(store: store)',
      'BackupScreen(store: store)',
      'CloudAccountScreen(store: store)',
      'SettingsScreen(store: store)',
    ]) {
      expect(more, contains(route));
    }
  });

  test('v1.05-A2 Memories is core rather than an optional Explore module', () {
    final explore =
        File('lib/src/screens/explore_screen.dart').readAsStringSync();
    final personalization =
        File('lib/src/screens/personalization_screen.dart').readAsStringSync();

    expect(explore, isNot(contains('addModule(\n            AppModule.memories')));
    expect(
      personalization,
      contains('(module) => module != AppModule.memories'),
    );
  });

  test('v1.05-A2 AppLab follows More instead of the legacy Home hub', () {
    final journey =
        File('.maestro/applab-journey.json').readAsStringSync();
    final smoke = File('.maestro/applab-smoke.yaml').readAsStringSync();

    expect(journey, contains('"name": "more"'));
    expect(journey, contains('.maestro/journey/more.yaml'));
    expect(journey, isNot(contains('"name": "home"')));
    expect(smoke, contains("id: 'more-settings'"));
    expect(smoke, isNot(contains("id: 'home_more_menu'")));

    final people = File('.maestro/journey/people.yaml').readAsStringSync();
    expect(people, contains("id: 'more-explore'"));
    expect(people, contains('direction: UP'));
    expect(
      people,
      isNot(contains("text: '(Altro|More|Más|Plus|Mais)[\\s\\S]*'")),
    );

    final routeJourneys = <String, String>{
      '.maestro/journey/backup.yaml': 'more-backup',
      '.maestro/journey/archive.yaml': 'more-archive',
      '.maestro/journey/shared.yaml': 'more-shared',
      '.maestro/journey/account.yaml': 'more-cloud',
      '.maestro/journey/trash.yaml': 'more-archive',
      '.maestro/journey/personalization.yaml': 'more-personalize',
    };
    for (final entry in routeJourneys.entries) {
      final source = File(entry.key).readAsStringSync();
      expect(source, contains('scrollUntilVisible:'));
      expect(source, contains("id: '${entry.value}'"));
    }
  });
}
