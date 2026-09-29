import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agenda_per_anna/main.dart';

void main() {
  test('v0.81 exposes the five supported product locales', () {
    expect(
      AnnaStrings.supportedLocales.map((locale) => locale.languageCode),
      ['en', 'it', 'es', 'fr', 'pt'],
    );
  });

  test('unsupported device locales fall back to English', () {
    expect(
      AnnaStrings.resolveLocale(const Locale('de')).languageCode,
      'en',
    );
    expect(
      AnnaStrings.resolveLocale(const Locale('ja')).languageCode,
      'en',
    );
  });

  test('language preference round-trips and legacy payloads remain readable', () {
    final prefs = const AgendaPreferences(
      appLanguage: AppLanguage.spanish,
    );
    final restored = AgendaPreferences.fromJson(prefs.toJson());

    expect(restored.appLanguage, AppLanguage.spanish);
    expect(
      AgendaPreferences.fromJson(const {}).appLanguage,
      AppLanguage.system,
    );
  });

  test('core chrome strings resolve in all supported languages', () {
    expect(const AnnaStrings('it').navToday, 'Oggi');
    expect(const AnnaStrings('en').navToday, 'Today');
    expect(const AnnaStrings('es').navToday, 'Hoy');
    expect(const AnnaStrings('fr').navToday, 'Aujourd’hui');
    expect(const AnnaStrings('pt').navToday, 'Hoje');

    expect(const AnnaStrings('en').settings, 'Settings');
    expect(const AnnaStrings('es').language, 'Idioma');
    expect(const AnnaStrings('fr').appearance, 'Apparence');
    expect(const AnnaStrings('pt').navMonth, 'Mês');
  });

  test('localization stays inside existing preferences and app shell', () {
    final localization =
        File('lib/src/localization.dart').readAsStringSync();
    final domain =
        File('lib/src/domain_models.dart').readAsStringSync();
    final shell = File('lib/src/app_shell.dart').readAsStringSync();
    final settings =
        File('lib/src/screens/backup_settings.dart').readAsStringSync();

    expect(domain, contains('final AppLanguage appLanguage;'));
    expect(domain, contains("'appLanguage': appLanguage.name"));
    expect(shell, contains('supportedLocales: AnnaStrings.supportedLocales'));
    expect(shell, contains('locale: store.preferences.appLanguage.locale'));
    expect(settings, contains('DropdownButtonFormField<AppLanguage>'));

    for (final forbidden in [
      'localization_v1',
      '_localizationKey',
      'language_database',
      'language_sync_queue',
      'translation_cloud_table',
    ]) {
      expect(
        localization.toLowerCase(),
        isNot(contains(forbidden.toLowerCase())),
      );
    }
  });
}
