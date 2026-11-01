import 'dart:io';

import 'package:agenda_per_anna/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 12, 31, 12);
  final valid = <(String, String, String, int, int, int)>[
    ('it', 'Dentista domani alle 17:30, ricordami il giorno prima',
        'Dentista', 2027, 1, 1),
    ('en', 'Meeting tomorrow at 5:30 pm', 'Meeting', 2027, 1, 1),
    ('es', 'Cita mañana a las 17:30', 'Cita', 2027, 1, 1),
    ('fr', 'Dentiste demain à 17h30', 'Dentiste', 2027, 1, 1),
    ('pt', 'Dentista amanhã às 17:30', 'Dentista', 2027, 1, 1),
  ];

  for (final (language, sentence, title, year, month, day) in valid) {
    test('B1 parses $language offline without a writer', () {
      final draft = parseNaturalEvent(
        sentence, languageCode: language, now: now);
      expect(draft, isNotNull);
      expect(draft!.title, title);
      expect(draft.date.year, year);
      expect(draft.date.month, month);
      expect(draft.date.day, day);
      expect(draft.start.hour, language == 'en' ? 17 : 17);
      expect(draft.start.minute, 30);
      expect(draft.recurrence, RecurrenceRule.none);
      expect(draft.reminderMinutesBefore, language == 'it' ? 1440 : null);
    });
  }

  test('B1 absolute ISO/date-first, leap day and local today', () {
    final dateFirst = parseNaturalEvent('Analisi 29/02/2028 alle 09:15',
        languageCode: 'it', now: now);
    expect(dateFirst!.date, DateTime(2028, 2, 29));
    expect(dateFirst.start.minute, 15);
    final iso = parseNaturalEvent('Visit 2027-01-15 at 08:00',
        languageCode: 'en', now: now);
    expect(iso!.date, DateTime(2027, 1, 15));
    final today = parseNaturalEvent('Riunione oggi alle 18',
        languageCode: 'it', now: now);
    expect(today!.date, DateTime(2026, 12, 31));
  });

  test('B1 explicitly supported recurrence only, user reviews count', () {
    final daily = parseNaturalEvent('Yoga ogni giorno 12/11/2027 alle 08:00',
        languageCode: 'it', now: now);
    expect(daily!.recurrence, RecurrenceRule.daily);
    final weekly = parseNaturalEvent('Study every week 2027-11-12 at 9 am',
        languageCode: 'en', now: now);
    expect(weekly!.recurrence, RecurrenceRule.weekly);
    expect(parseNaturalEvent('Yoga ogni giovedì alle 08',
        languageCode: 'it', now: now), isNull);
  });

  test('B1 refuses ambiguous, invalid and unsupported expressions', () {
    final invalid = [
      'Dentista giovedì alle 17:30',
      'Dentista domani',
      'Dentista alle 17:30',
      'Dentista 29/02/2027 alle 17:30',
      'Dentista 31/04/2028 alle 17:30',
      'Dentista domani alle 25:61',
      'Dentista oggi domani alle 17:30',
      'Dentista domani alle 17:30 e alle 19:00',
      'Dentista domani alle 17:30 ricordami tra due giorni',
      'Dentista domani alle 17:30 ogni giovedì',
      'Dentista 2027-02-05 08:30 UTC',
    ];
    for (final phrase in invalid) {
      expect(parseNaturalEvent(phrase,
        languageCode: 'it', now: now), isNull, reason: phrase);
    }
    expect(parseNaturalEvent('Meeting tomorrow at 17:00',
        languageCode: 'de', now: now), isNull);
  });

  test('B1 accepts local civil day boundaries without elapsed-day drift', () {
    final day = parseNaturalEvent('Viaggio domani alle 06:45',
      languageCode: 'it', now: DateTime(2026, 3, 28, 23));
    expect(day!.date, DateTime(2026, 3, 29));
    // If the test host uses a DST zone, the clock time remains 06:45.
    expect(day.start, const TimeOfDay(hour: 6, minute: 45));
    final lastDay = parseNaturalEvent('Viaggio domani alle 06:45',
      languageCode: 'it', now: DateTime(2028, 2, 28, 23));
    expect(lastDay!.date, DateTime(2028, 2, 29));
  });

  test('B1 wiring stays on the existing editor and canonical writer', () {
    final main = File('lib/main.dart').readAsStringSync();
    final editor = File('lib/src/widgets_editors.dart').readAsStringSync();
    final parser = File('lib/src/natural_event_parser.dart').readAsStringSync();
    expect(main, contains("part 'src/natural_event_parser.dart';"));
    expect(editor, contains("ValueKey('b1-natural-open')"));
    expect(editor, contains('showNaturalEventParser(context)'));
    expect(editor, contains('naturalDraftApplied = true'));
    expect(editor, contains('accountAtOpen'));
    expect(editor, contains('store.upsert('));
    expect(editor, contains('store.createRecurringSeries('));
    expect(parser, contains("ValueKey('b1-use-draft')"));
    expect(parser, contains('showDialog<NaturalEventDraft>'));
    expect(parser, isNot(contains('CloudSyncService')));
    expect(parser, isNot(contains('SharedPreferences')));
    expect(parser, isNot(contains('NotificationService')));
  });
}
