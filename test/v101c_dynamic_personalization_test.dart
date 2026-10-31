import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:agenda_per_anna/main.dart';

void main() {
  test('manual personalization remains reversible and dependency-safe', () {
    var prefs = const AgendaPreferences().applyPersonalizationPreset(
      PersonalizationPreset.essential,
    );

    expect(prefs.enabledModules, isEmpty);

    prefs = prefs.withModuleEnabled(AppModule.shopping, true);
    expect(prefs.personalizationPreset, PersonalizationPreset.custom);
    expect(prefs.isModuleEnabled(AppModule.shopping), isTrue);

    prefs = prefs.withModuleEnabled(AppModule.cycleTracker, true);
    expect(prefs.isModuleEnabled(AppModule.cycleTracker), isTrue);
    expect(prefs.isModuleEnabled(AppModule.privateVault), isTrue);

    prefs = prefs.withModuleEnabled(AppModule.privateVault, false);
    expect(prefs.isModuleEnabled(AppModule.privateVault), isFalse);
    expect(prefs.isModuleEnabled(AppModule.cycleTracker), isFalse);

    prefs = prefs.applyPersonalizationPreset(PersonalizationPreset.complete);
    expect(prefs.enabledModules, completeAppModules);
  });

  test('Explore and optional shell entry points honor module visibility', () {
    final explore =
        File('lib/src/screens/explore_screen.dart').readAsStringSync();
    final shell =
        File('lib/src/screens/home_inbox_search.dart').readAsStringSync();
    final more = File('lib/src/screens/more_screen.dart').readAsStringSync();
    final planner = File('lib/src/planner_views.dart').readAsStringSync();
    final editors = File('lib/src/widgets_editors.dart').readAsStringSync();
    final vault =
        File('lib/src/screens/private_vault.dart').readAsStringSync();

    for (final module in const [
      'shopping',
      'workout',
      'people',
      'habits',
      'sharedSpace',
      'privateVault',
      'ecosystem',
    ]) {
      expect(
        explore,
        contains('AppModule.$module'),
        reason: 'Explore missing visibility contract for $module',
      );
    }

    expect(explore, isNot(contains('AppModule.memories')));
    expect(
      shell,
      contains('DiaryMemoriesScreen(store: widget.store)'),
      reason: 'Memories is now a core shell destination',
    );
    expect(shell, contains('AppModule.sharedSpace'));
    expect(planner, contains('AppModule.habits'));
    expect(editors, contains('AppModule.habits'));
    expect(vault, contains('AppModule.cycleTracker'));
  });

  test('Personalize reuses AgendaPreferences instead of adding an owner', () {
    final screen =
        File('lib/src/screens/personalization_screen.dart').readAsStringSync();
    final settings =
        File('lib/src/screens/backup_settings.dart').readAsStringSync();

    expect(screen, contains('store.applyPersonalizationPreset'));
    expect(screen, contains('store.setModuleEnabled'));
    expect(screen, contains('PersonalizationPreset.custom'));
    expect(screen, isNot(contains('SharedPreferences')));
    expect(screen, isNot(contains('LocalStateStore')));
    expect(settings, contains('PersonalizationScreen('));
    expect(settings, contains("ValueKey('settings-personalization')"));
  });

  test('v1.01-C copy stays in the canonical five-language catalog', () {
    final localization =
        File('lib/src/localization_d3.dart').readAsStringSync();
    const keys = <String>[
      'personalizationTitle',
      'personalizationIntro',
      'personalizationSettingsSubtitle',
      'personalizationPresetTitle',
      'personalizationCurrentPreset',
      'personalizationCustomTitle',
      'personalizationHiddenDataSafe',
      'personalizationModulesTitle',
      'personalizationHabits',
      'personalizationCycleDependency',
      'personalizationRestoreComplete',
      'personalizationExploreEmpty',
    ];

    for (final key in keys) {
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
