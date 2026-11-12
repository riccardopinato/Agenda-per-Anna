import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:factory_profile_kit/factory_profile_kit.dart' as kit;
import 'package:agenda_per_anna/main.dart' as anna;

/// X10-026: consumer source test only. NEVER writes existing Anna preferences.
void main() {
  test('pinned shared profile model imports without changing Anna data', () {
    const original = anna.AgendaPreferences(
      displayName: 'Anna',
      themeMode: anna.AgendaThemeMode.dark,
      appLanguage: anna.AppLanguage.italian,
    );
    final before = jsonEncode(original.toJson());
    const proposed = kit.ProfilePreferences(
      displayName: 'Anna',
      locale: 'it',
      theme: kit.ProfileTheme.dark,
    );
    expect(proposed.analyticsOptIn, isFalse);
    expect(proposed.toJson()['schema_version'], 1);
    expect(proposed.displayName, original.displayName);
    expect(jsonEncode(original.toJson()), before);
  });

  test('AgendaStore runtime projection consumes pinned profile kit without writing', () {
    const prefs = anna.AgendaPreferences(
      displayName: 'Anna',
      themeMode: anna.AgendaThemeMode.dark,
      appLanguage: anna.AppLanguage.italian,
      defaultEventMinutes: 45,
    );
    final store = anna.AgendaStore()..preferences = prefs;
    final before = jsonEncode(store.preferences.toJson());
    final snapshot = store.factoryProfileSnapshot;
    expect(snapshot.displayName, 'Anna');
    expect(snapshot.locale, 'it');
    expect(snapshot.theme, kit.ProfileTheme.dark);
    expect(snapshot.analyticsOptIn, isFalse);
    expect(store.preferences.defaultEventMinutes, 45);
    expect(jsonEncode(store.preferences.toJson()), before);
    store.dispose();
  });

  test('system language remains explicit and private by default', () {
    final store = anna.AgendaStore();
    expect(store.factoryProfileSnapshot.locale, 'system');
    expect(store.factoryProfileSnapshot.analyticsOptIn, isFalse);
    store.dispose();
  });

  test('shared kit has no implicit auth, cloud, backup or consent', () {
    const defaults = kit.ProfilePreferences();
    expect(defaults.analyticsOptIn, isFalse);
    expect(defaults.locale, 'system');
    expect(defaults.displayName, isEmpty);
    expect(defaults.theme, kit.ProfileTheme.system);
  });
}
