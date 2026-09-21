import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agenda_per_anna/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
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

    final backup = source.createBackupJson();

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

    await target.restoreBackup(source.createBackupJson(), merge: true);

    expect(target.preferences.palette, AgendaPalette.peach);
  });
}
