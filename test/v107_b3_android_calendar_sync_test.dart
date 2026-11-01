import 'dart:io';
import 'package:agenda_per_anna/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  AgendaItem appointment({
    String title = 'Dentist',
    DateTime? date,
    TimeOfDay? start,
    TimeOfDay? end,
    ItemType type = ItemType.appointment,
  }) => AgendaItem(
    id: 'event-1', title: title, note: 'PRIVATE NOTE - NEVER EXPORT',
    date: date ?? DateTime(2026, 11, 7),
    type: type, start: start, end: end,
  );

  test('B3 exports only event summary and account-qualified identity', () {
    final payload = androidCalendarEventPayload(
      appointment(start: const TimeOfDay(hour: 10, minute: 30),
        end: const TimeOfDay(hour: 11, minute: 45)),
      scope: 'user:account-a', calendarId: 'cal-9',
    )!;
    expect(payload['calendarId'], 'cal-9');
    expect(payload['ownerKey'], 'user:account-a:event-1');
    expect(payload['title'], 'Dentist');
    expect(payload['allDay'], false);
    expect(payload['startMs'], DateTime(2026, 11, 7, 10, 30).millisecondsSinceEpoch);
    expect(payload['endMs'], DateTime(2026, 11, 7, 11, 45).millisecondsSinceEpoch);
    expect(payload.toString(), isNot(contains('PRIVATE NOTE')));
    expect(payload.keys.toSet(), {
      'calendarId', 'ownerKey', 'title', 'startMs', 'endMs', 'allDay',
    });
  });

  test('B3 untimed appointment is full day in UTC', () {
    final payload = androidCalendarEventPayload(
      appointment(), scope: 'guest', calendarId: '4')!;
    expect(payload['allDay'], true);
    expect(payload['startMs'],
        DateTime.utc(2026, 11, 7).millisecondsSinceEpoch);
    expect(payload['endMs'],
        DateTime.utc(2026, 11, 8).millisecondsSinceEpoch);
  });

  test('B3 midnight crossover uses next civil day', () {
    final payload = androidCalendarEventPayload(
      appointment(
        start: const TimeOfDay(hour: 23, minute: 30),
        end: const TimeOfDay(hour: 1, minute: 0),
      ),
      scope: 'guest', calendarId: '4')!;
    expect(payload['startMs'],
        DateTime(2026, 11, 7, 23, 30).millisecondsSinceEpoch);
    expect(payload['endMs'],
        DateTime(2026, 11, 8, 1).millisecondsSinceEpoch);
  });

  test('B3 fails closed for ambiguous missing end and non-appointments', () {
    expect(androidCalendarEventPayload(
      appointment(start: const TimeOfDay(hour: 9, minute: 0)),
      scope: 'guest', calendarId: '4'), isNull);
    expect(androidCalendarEventPayload(
      appointment(type: ItemType.task),
      scope: 'guest', calendarId: '4'), isNull);
    expect(androidCalendarEventPayload(
      appointment(title: ''),
      scope: 'guest', calendarId: '4'), isNull);
  });

  test('B3 DST semantics use native civil-date construction', () {
    final spring = androidCalendarEventPayload(
      appointment(
        date: DateTime(2026, 3, 29),
        start: const TimeOfDay(hour: 1, minute: 0),
        end: const TimeOfDay(hour: 4, minute: 0),
      ),
      scope: 'guest', calendarId: '4')!;
    expect(spring['startMs'], DateTime(2026, 3, 29, 1).millisecondsSinceEpoch);
    expect(spring['endMs'], DateTime(2026, 3, 29, 4).millisecondsSinceEpoch);
  });

  test('B3 Android provider contract and disabled by default', () {
    final sync = File('lib/src/android_calendar_sync.dart').readAsStringSync();
    final ui = File('lib/src/screens/android_calendar_sync_settings.dart').readAsStringSync();
    final native = File('tool/prepare_android_platform.py').readAsStringSync();
    final main = File('lib/main.dart').readAsStringSync();
    expect(sync, contains('prefs.getBool('));
    expect(sync, contains('store.agendaRevision.addListener(_schedule)'));
    expect(sync, contains('store.accountRevision.addListener(_onAccountChanged)'));
    expect(sync, contains('!item.date.isBefore(from)'));
    expect(sync, contains('items.take(200)'));
    expect(sync, isNot(contains('VaultService.instance')));
    expect(sync, isNot(contains('store.upsert(')));
    expect(ui, contains("ValueKey('b3-android-calendar-enabled')"));
    expect(ui, contains('requestWriteAccess()'));
    expect(native, contains('android.permission.WRITE_CALENDAR'));
    expect(native, contains('"upsertOwnedEvent"'));
    expect(native, contains('external_event_missing_or_moved'));
    expect(native, contains('duplicate_external_event_marker'));
    expect(main, contains("part 'src/android_calendar_sync.dart';"));
  });
}
