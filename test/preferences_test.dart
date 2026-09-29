import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agenda_per_anna/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('new profiles start without a prefilled personal name', () {
    const defaults = AgendaPreferences();
    final legacyMissingName = AgendaPreferences.fromJson(const {});

    expect(defaults.displayName, isEmpty);
    expect(legacyMissingName.displayName, isEmpty);
  });

  test('settings exposes a neutral localized name field', () {
    final settings =
        File('lib/src/screens/backup_settings.dart').readAsStringSync();
    final localization =
        File('lib/src/localization.dart').readAsStringSync();

    expect(settings, contains('hintText: strings.enterName'));
    expect(localization, contains("it: 'Inserisci il tuo nome'"));
    expect(
      settings,
      isNot(contains('prefixIcon: Icon(Icons.favorite_outline)')),
    );
    expect(settings, contains('displayName: value,'));
  });

  test('preferences round-trip preserves personalization', () {
    const prefs = AgendaPreferences(
      displayName: 'Anna',
      themeMode: AgendaThemeMode.dark,
      palette: AgendaPalette.lilac,
      showDailyQuote: false,
      startTab: StartTab.today,
      defaultCategory: AgendaCategory.couple,
      defaultEventMinutes: 90,
      defaultPrimaryReminder: 60,
      defaultSecondaryReminder: 10,
      appLanguage: AppLanguage.french,
    );

    final restored = AgendaPreferences.fromJson(prefs.toJson());

    expect(restored.displayName, 'Anna');
    expect(restored.themeMode, AgendaThemeMode.dark);
    expect(restored.palette, AgendaPalette.lilac);
    expect(restored.showDailyQuote, isFalse);
    expect(restored.startTab, StartTab.today);
    expect(restored.defaultCategory, AgendaCategory.couple);
    expect(restored.defaultEventMinutes, 90);
    expect(restored.defaultPrimaryReminder, 60);
    expect(restored.defaultSecondaryReminder, 10);
    expect(restored.appLanguage, AppLanguage.french);
  });

  test('preferences are included in backup restore', () async {
    final source = AgendaStore();
    await source.savePreferences(
      const AgendaPreferences(
        displayName: 'Anna',
        palette: AgendaPalette.sage,
        themeMode: AgendaThemeMode.light,
        startTab: StartTab.week,
        defaultCategory: AgendaCategory.study,
        defaultEventMinutes: 45,
        defaultPrimaryReminder: 30,
      ),
    );

    final backup = await source.createBackupJson();

    final restored = AgendaStore();
    await restored.restoreBackup(backup, merge: false);

    expect(restored.preferences.palette, AgendaPalette.sage);
    expect(restored.preferences.startTab, StartTab.week);
    expect(restored.preferences.defaultCategory, AgendaCategory.study);
    expect(restored.preferences.defaultEventMinutes, 45);
    expect(restored.preferences.defaultPrimaryReminder, 30);
  });

  test('merge backup keeps current device preferences', () async {
    final source = AgendaStore();
    await source.savePreferences(
      const AgendaPreferences(palette: AgendaPalette.sky),
    );

    final target = AgendaStore();
    await target.savePreferences(
      const AgendaPreferences(palette: AgendaPalette.peach),
    );

    await target.restoreBackup(await source.createBackupJson(), merge: true);

    expect(target.preferences.palette, AgendaPalette.peach);
  });
}
