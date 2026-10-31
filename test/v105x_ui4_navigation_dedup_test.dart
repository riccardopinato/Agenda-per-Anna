import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('UI4 highlights private/shared routes without exposing hidden modules', () {
    final more = File('lib/src/screens/more_screen.dart').readAsStringSync();
    final shell = File('lib/src/screens/home_inbox_search.dart').readAsStringSync();
    expect(shell, contains("'main-nav-messages'"));
    expect(more, isNot(contains("id: 'more-shared'")));
    expect(more, contains("id: 'more-private-vault'"));
    expect(more, contains('prefs.isModuleEnabled(AppModule.privateVault)'));
    expect(more, contains('PrivateVaultScreen(store: store)'));
    expect(more, isNot(contains("id: 'more-personalize'")));
    for (final id in const [
      'more-search', 'more-inbox', 'more-explore', 'more-archive',
      'more-backup', 'more-cloud', 'more-settings',
    ]) {
      expect(more, contains("id: '$id'"));
    }
  });

  test('UI4 keeps one contextual Explore personalization action', () {
    final explore = File('lib/src/screens/explore_screen.dart').readAsStringSync();
    final appBar = explore.split('appBar: AppBar(')[1].split('body: AnimatedBuilder(')[0];
    expect(appBar, isNot(contains('PersonalizationScreen(')));
    expect(explore.split('PersonalizationScreen(store: store)').length - 1, 1);
    expect(explore, contains("title: strings.d3('sharedSpace')"));
    final settings = File('lib/src/screens/settings_hub.dart').readAsStringSync();
    expect(settings, contains("id: 'settings-hub-personalization'"));
    expect(settings, contains('PersonalizationScreen(store: store)'));
    final preferences = File('lib/src/screens/personalization_screen.dart').readAsStringSync();
    expect(preferences, contains("AppModule.sharedSpace => strings.d3('sharedSpace')"));
  });

  test('UI4 removes duplicate Today life preview but preserves full stream', () {
    final planner = File('lib/src/planner_views.dart').readAsStringSync();
    expect(planner, contains('_DayLifeOverviewCard('));
    expect(planner, contains('_DayLifeStream('));
    expect(planner, contains('snapshot.lifeEntries'));
    expect(planner, isNot(contains('_DayLifePreviewRow')));
    expect(planner, isNot(contains('snapshot.lifeEntries.take(3)')));
    expect(planner, contains('JournalEditor(store: widget.store, date: day)'));
  });

  test('UI4 uses existing en/it/es/fr/pt Shared Space localization', () {
    final catalog = File('lib/src/localization_d3.dart').readAsStringSync();
    final entry = catalog.split('"sharedSpace": <String, String>')[1].split('},')[0];
    for (final locale in const ['en', 'it', 'es', 'fr', 'pt']) {
      expect(entry, contains('"$locale":'), reason: 'missing Shared Space $locale');
    }
    final flow = File('.maestro/journey/personalization.yaml').readAsStringSync();
    expect(flow, contains("id: 'more-settings'"));
    expect(flow, contains("id: 'settings-hub-personalization'"));
  });
}
