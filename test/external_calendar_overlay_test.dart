import 'package:agenda_per_anna/external_calendar_service.dart';
import 'package:agenda_per_anna/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('external calendar event projects as a read-only agenda appointment', () {
    final event = ExternalCalendarEvent(
      id: 'calendar:event:instance',
      calendarId: 'calendar',
      calendarName: 'Google',
      title: 'Visita',
      description: 'Controllo',
      location: 'Padova',
      start: DateTime(2026, 10, 5, 9, 30),
      end: DateTime(2026, 10, 5, 10, 15),
      allDay: false,
    );

    final entry = UnifiedAgendaEntry.external(event);

    expect(entry.isExternal, isTrue);
    expect(entry.isPrivate, isFalse);
    expect(entry.isShared, isFalse);
    expect(entry.title, 'Visita');
    expect(entry.note, 'Controllo');
    expect(entry.type, ItemType.appointment);
    expect(entry.done, isFalse);
    expect(entry.start, const TimeOfDay(hour: 9, minute: 30));
    expect(entry.end, const TimeOfDay(hour: 10, minute: 15));
    expect(entry.visibilityLabel(const AnnaStrings('en')), 'Google');
  });

  test('all-day platform events preserve the civil date', () {
    final event = ExternalCalendarEvent.fromPlatform({
      'calendarId': '1',
      'eventId': '2',
      'calendarName': 'Personale',
      'title': 'Festa',
      'startMs': DateTime.utc(2026, 10, 11).millisecondsSinceEpoch,
      'endMs': DateTime.utc(2026, 10, 12).millisecondsSinceEpoch,
      'allDay': true,
    });

    expect(event.start, DateTime(2026, 10, 11));
    expect(event.end, DateTime(2026, 10, 12));
    expect(event.occursOn(DateTime(2026, 10, 11)), isTrue);
    expect(event.occursOn(DateTime(2026, 10, 12)), isFalse);
  });

  test('timed event ending at midnight does not spill into the next day', () {
    final event = ExternalCalendarEvent(
      id: 'midnight',
      calendarId: '1',
      calendarName: 'Lavoro',
      title: 'Turno',
      description: '',
      location: '',
      start: DateTime(2026, 10, 11, 22),
      end: DateTime(2026, 10, 12),
      allDay: false,
    );

    expect(event.occursOn(DateTime(2026, 10, 11)), isTrue);
    expect(event.occursOn(DateTime(2026, 10, 12)), isFalse);
  });
}
