import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:agenda_per_anna/main.dart';

void main() {
  test('v0.82 localizes daily planner and capture vocabulary', () {
    expect(const AnnaStrings('en').calendar, 'Calendar');
    expect(const AnnaStrings('it').myDay, 'La mia giornata');
    expect(const AnnaStrings('es').capture, 'Capturar');
    expect(const AnnaStrings('fr').voiceNote, 'Note vocale');
    expect(const AnnaStrings('pt').importantPerson, 'Pessoa importante');
  });

  test('v0.82 localizes Inbox and archive vocabulary', () {
    expect(const AnnaStrings('en').inboxEmpty, contains('Ideas and notes'));
    expect(const AnnaStrings('es').convertToTask, 'Convertir en tarea');
    expect(const AnnaStrings('fr').lifeArchive, 'Archives de vie');
    expect(const AnnaStrings('pt').trash, 'Lixo');
    expect(const AnnaStrings('it').archiveStillEmpty, 'L’archivio è ancora vuoto.');
  });

  test('localized count helpers preserve live counts', () {
    expect(const AnnaStrings('en').monthsWithContent(3), '3 months with content');
    expect(const AnnaStrings('it').commitmentsCount(2), '2 impegni');
    expect(const AnnaStrings('es').workoutsCount(4), '4 entrenamientos');
    expect(const AnnaStrings('fr').goalsCount(5), '5 objectifs');
  });

  test('high-frequency surfaces use AnnaStrings rather than a second system', () {
    final planner = File('lib/src/planner_views.dart').readAsStringSync();
    final capture = File('lib/src/unified_capture.dart').readAsStringSync();
    final home =
        File('lib/src/screens/home_inbox_search.dart').readAsStringSync();

    expect(planner, contains('final strings = AnnaStrings.of(context);'));
    expect(planner, contains('strings.myDay'));
    expect(planner, contains('strings.hourlyTimeline'));
    expect(capture, contains('strings.captureDayDescription'));
    expect(capture, contains('strings.writeMoment'));
    expect(home, contains('strings.inboxEmpty'));
    expect(home, contains('strings.lifeArchive'));
    expect(home, contains('strings.searchWholeStory'));

    for (final source in [planner, capture, home]) {
      expect(source.toLowerCase(), isNot(contains('easy_localization')));
      expect(source.toLowerCase(), isNot(contains('translation_service')));
    }
  });

  test('localized date chrome no longer hardcodes Italian locale in target flows', () {
    final planner = File('lib/src/planner_views.dart').readAsStringSync();
    final capture = File('lib/src/unified_capture.dart').readAsStringSync();
    final home =
        File('lib/src/screens/home_inbox_search.dart').readAsStringSync();

    expect(planner, contains('AnnaStrings.intlLocale(context)'));
    expect(capture, contains('strings.dayWord(targetDay)'));
    expect(home, contains('AnnaStrings.intlLocale(context)'));
  });
}
