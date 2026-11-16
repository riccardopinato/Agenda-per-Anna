import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('v138 Organic More groups personal rows without changing routes', () {
    final source = File('lib/src/screens/more_screen.dart').readAsStringSync();
    expect(source, contains('more-organic-your-space-group'));
    expect(source, contains('_yourSpaceSection(context, strings, editorial)'));
    expect(source, contains('if (editorial)'));
    expect(source, contains('if (prefs.isModuleEnabled(AppModule.privateVault))'));
    expect(source, contains('if (prefs.isModuleEnabled(AppModule.memories))'));
    expect(source, contains('AnnaOrganicJournalRule()'));
    for (final id in [
      'more-search',
      'more-inbox',
      'more-private-vault',
      'more-future-letters',
      'more-explore',
      'more-archive',
      'more-backup',
      'more-cloud',
      'more-settings',
    ]) {
      expect(source, contains("id: '$id'"));
    }
    for (final route in [
      'PrivateVaultScreen(store: store)',
      'PersonalFutureLettersScreen(store: store)',
      'ExploreScreen(store: store)',
      'BackupScreen(store: store)',
      'SettingsHubScreen(store: store)',
    ]) {
      expect(source, contains(route));
    }
  });

  test('v138 Settings preview derives from live theme, search stays intact', () {
    final source =
        File('lib/src/screens/settings_hub.dart').readAsStringSync();
    expect(source, contains('settings-hub-live-palette-preview'));
    for (final value in [
      'colorScheme.primaryContainer',
      'colorScheme.primary',
      'colorScheme.secondary',
      'colorScheme.tertiary',
      'colorScheme.surface',
      'focusedBorder:',
      '_query = value.trim().toLowerCase()',
      'qw2-settings-search',
      'settings-hub-edit-name',
      'settings-hub-appearance',
      'settings-hub-personalization',
      'settings-hub-preferences-privacy',
      'settings-hub-account',
      'settings-hub-backup',
    ]) {
      expect(source, contains(value));
    }
    expect(source, contains('AppearanceColorsScreen(store: store)'));
    expect(source, contains('CloudAccountScreen(store: store)'));
    expect(source, contains('BackupScreen(store: store)'));
  });
}
