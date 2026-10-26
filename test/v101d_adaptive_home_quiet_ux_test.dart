import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('v1.05-A3 retires Home and preserves quiet secondary navigation', () {
    final shell =
        File('lib/src/screens/home_inbox_search.dart').readAsStringSync();
    final planner = File('lib/src/planner_views.dart').readAsStringSync();
    final more = File('lib/src/screens/more_screen.dart').readAsStringSync();

    expect(shell, isNot(contains('class HomeScreen')));
    expect(shell, isNot(contains("identifier: 'home_more_menu'")));
    expect(shell, isNot(contains("ValueKey<String>('home-more-menu')")));

    expect(planner, contains("ValueKey<String>('today-focus-card')"));
    expect(planner, contains("today-pinned-section"));
    expect(planner, contains("ValueKey<String>('today-wellbeing-card')"));

    for (final id in const <String>[
      'more-search',
      'more-inbox',
      'more-explore',
      'more-personalize',
      'more-archive',
      'more-backup',
      'more-cloud',
      'more-settings',
    ]) {
      expect(more, contains("id: '$id'"));
    }
  });

  test('healthy sync and intentional device-only use stay quiet in More', () {
    final shared =
        File('lib/src/screens/home_inbox_search.dart').readAsStringSync();
    final more = File('lib/src/screens/more_screen.dart').readAsStringSync();

    expect(shared, contains('final intentionalLocalOnly'));
    expect(shared, contains('final healthyCloud'));
    expect(
      shared,
      contains('if (intentionalLocalOnly || healthyCloud)'),
    );
    expect(shared, contains("ValueKey<String>('sync-attention')"));
    expect(shared, contains('CloudConnectionState.error'));
    expect(shared, contains('store.hasSharedSyncError'));
    expect(shared, contains('pending > 0'));
    expect(more, contains('_SyncAttentionCard(store: store)'));
  });

  test('Today presentation remains preference-aware without deleting data', () {
    final planner = File('lib/src/planner_views.dart').readAsStringSync();

    expect(planner, contains('AppModule.habits'));
    expect(planner, contains('store.preferences.hideHomeDetails'));
    expect(planner, contains('AgendaContentFilter.sharedOnly'));
    expect(planner, isNot(contains('removeWhere((module)')));
    expect(planner, isNot(contains('deleteModule')));
  });

  test('secondary operational journeys use the stable More destination', () {
    final smoke = File('.maestro/applab-smoke.yaml').readAsStringSync();
    final account = File('.maestro/journey/account.yaml').readAsStringSync();
    final archive = File('.maestro/journey/archive.yaml').readAsStringSync();
    final backup = File('.maestro/journey/backup.yaml').readAsStringSync();
    final shared = File('.maestro/journey/shared.yaml').readAsStringSync();
    final trash = File('.maestro/journey/trash.yaml').readAsStringSync();
    final regression =
        File('.maestro/journey/d6-functional-navigation.yaml')
            .readAsStringSync();

    expect(smoke, contains("id: 'more-settings'"));
    expect(account, contains("id: 'more-cloud'"));
    expect(archive, contains("id: 'more-archive'"));
    expect(backup, contains("id: 'more-backup'"));
    expect(shared, contains("id: 'more-shared'"));
    expect(trash, contains("id: 'more-archive'"));
    expect(regression, contains("id: 'more-search'"));
    expect(regression, contains("id: 'more-inbox'"));
    expect(regression, contains("id: 'more-explore'"));
    expect(regression, contains("id: 'more-cloud'"));
  });

  test('v1.01 navigation copy stays in the canonical five-language catalog', () {
    final localization =
        File('lib/src/localization_d3.dart').readAsStringSync();

    for (final key in const ['homeMore', 'homeExploreAreasCount']) {
      final start = localization.indexOf('"$key": <String, String>');
      expect(start, greaterThanOrEqualTo(0), reason: 'missing $key');
      final end = localization.indexOf('},', start);
      final entry = localization.substring(start, end);
      for (final locale in const ['"en"', '"it"', '"es"', '"fr"', '"pt"']) {
        expect(entry, contains(locale), reason: '$key missing $locale');
      }
    }
  });
}
