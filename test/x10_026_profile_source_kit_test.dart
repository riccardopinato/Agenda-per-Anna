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

  test('shared kit has no implicit auth, cloud, backup or consent', () {
    const defaults = kit.ProfilePreferences();
    expect(defaults.analyticsOptIn, isFalse);
    expect(defaults.locale, 'system');
    expect(defaults.displayName, isEmpty);
    expect(defaults.theme, kit.ProfileTheme.system);
  });
}
