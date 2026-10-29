import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('More C keeps all stable destinations and attention warnings', () {
    final more = File('lib/src/screens/more_screen.dart').readAsStringSync();
    expect(more, contains('AnnaJournalSectionHeading('));
    expect(more, contains('AnnaJournalCard('));
    final cards = File('lib/src/ios_journal_design.dart').readAsStringSync();
    expect(cards, contains('return Material('));
    expect(cards, contains('clipBehavior: Clip.antiAlias'));

    expect(more, contains('journalPageGutter'));
    for (final id in [
      'more-search',
      'more-inbox',
      'more-explore',
      'more-shared',
      'more-private-vault',
      'more-archive',
      'more-backup',
      'more-cloud',
      'more-settings',
    ]) {
      expect(more, contains("id: '$id'"));
    }
    expect(more, contains('_SyncAttentionCard(store: store)'));
    expect(more, contains('store.hasStorageWarnings'));
    expect(more, contains('prefs.isModuleEnabled(AppModule.sharedSpace)'));
  });

  test('Settings A keeps all routes and exposes a direct HSV editor', () {
    final settings =
        File('lib/src/screens/settings_hub.dart').readAsStringSync();
    expect(settings, contains('AnnaJournalSectionHeading('));
    expect(settings, contains('AnnaJournalCard('));
    for (final id in [
      'settings-hub-appearance',
      'settings-hub-personalization',
      'settings-hub-preferences-privacy',
      'settings-hub-premium',
      'settings-hub-account',
      'settings-hub-backup',
    ]) {
      expect(settings, contains("id: '$id'"));
    }
    for (final route in [
      'AppearanceColorsScreen(store: store)',
      'PersonalizationScreen(store: store)',
      'SettingsScreen(store: store)',
      'CloudAccountScreen(store: store)',
      'BackupScreen(store: store)',
    ]) {
      expect(settings, contains(route));
    }
  });
}
