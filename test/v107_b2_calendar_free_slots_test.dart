import 'dart:io';

import 'package:agenda_per_anna/external_calendar_service.dart';
import 'package:agenda_per_anna/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final day = DateTime(2026, 11, 17);
  UnifiedAgendaEntry event(String id, int? from, int? to, {
    DateTime? date, ItemType type = ItemType.appointment,
  }) => UnifiedAgendaEntry.private(AgendaItem(
    id: id,
    title: id,
    note: '',
    date: date ?? day,
    type: type,
    start: from == null ? null
        : TimeOfDay(hour: from ~/ 60, minute: from % 60),
    end: to == null ? null
        : TimeOfDay(hour: to ~/ 60, minute: to % 60),
  ));

  List<CalendarFreeSlot> search(
    Iterable<UnifiedAgendaEntry> entries, {
    int from = 9, int to = 18, int minimum = 30, DateTime? date,
  }) => findCalendarFreeSlots(
    day: date ?? day, visibleEntries: entries, startHour: from,
    endHour: to, minimumMinutes: minimum,
  );

  test('B2 merges overlaps, adjacent events and filters short gaps', () {
    final slots = search([
      event('a', 10 * 60, 11 * 60),
      event('b', 10 * 60 + 30, 12 * 60),
      event('c', 12 * 60, 13 * 60),
      event('d', 13 * 60 + 10, 14 * 60),
    ], minimum: 30);
    expect(slots.length, 2);
    expect(slots.first.start.hour, 9);
    expect(slots.first.end.hour, 10);
    expect(slots.last.start.hour, 14);
    expect(slots.last.end.hour, 18);
  });

  test('B2 empty agenda stays usable offline, tasks never block', () {
    expect(search([]).single.duration, const Duration(hours: 9));
    expect(search([
      event('task', 9 * 60, 18 * 60, type: ItemType.task),
    ]).single.duration, const Duration(hours: 9));
  });

  test('B2 untimed appointments are conservatively all-day', () {
    expect(search([event('no-time', null, null)]), isEmpty);
    expect(search([event('no-end', 12 * 60, null)]).single.end.hour, 12);
  });

  test('B2 handles overnight window and prior-day appointment', () {
    final slots = search([
      event('overnight', 23 * 60, 60,
        date: DateTime(2026, 11, 16)),
      event('morning', 30, 90, date: DateTime(2026, 11, 18)),
    ], from: 22, to: 2);
    expect(slots.length, 2);
    expect(slots.first.start, DateTime(2026, 11, 17, 22));
    expect(slots.first.end, DateTime(2026, 11, 18, 0, 30));
    expect(slots.last.start, DateTime(2026, 11, 18, 1, 30));
    expect(slots.last.end, DateTime(2026, 11, 18, 2));
  });

  test('B2 external timed multi-day and all-day use provider instants', () {
    final holiday = ExternalCalendarEvent(
      id: 'holiday', calendarId: 'selected', calendarName: 'Local calendar',
      title: 'Away', description: '', location: '',
      start: DateTime(2026, 11, 17),
      end: DateTime(2026, 11, 18),
      allDay: true,
    );
    expect(search([UnifiedAgendaEntry.external(holiday)]), isEmpty);

    final overnight = ExternalCalendarEvent(
      id: 'external-night', calendarId: 'selected',
      calendarName: 'Local calendar', title: 'Night',
      description: '', location: '',
      start: DateTime(2026, 11, 16, 23),
      end: DateTime(2026, 11, 17, 10),
      allDay: false,
    );
    final slots = search([
      UnifiedAgendaEntry.external(overnight),
      UnifiedAgendaEntry.external(overnight), // Repeated on two day indices.
    ]);
    expect(slots.single.start, DateTime(2026, 11, 17, 10));
    expect(slots.single.end.hour, 18);
  });

  test('B2 uses absolute local DateTime on DST boundaries', () {
    final spring = search([], date: DateTime(2026, 3, 29), from: 1, to: 4);
    expect(spring.single.start, DateTime(2026, 3, 29, 1));
    expect(spring.single.end, DateTime(2026, 3, 29, 4));
    expect(spring.single.duration, spring.single.end.difference(spring.single.start));
    final autumn = search([], date: DateTime(2026, 10, 25), from: 1, to: 4);
    expect(autumn.single.duration,
        autumn.single.end.difference(autumn.single.start));
  });

  test('B2 no mutation path: reuses filtered unified agenda + consent', () {
    final main = File('lib/main.dart').readAsStringSync();
    final view = File('lib/src/planner_views.dart').readAsStringSync();
    final source = File('lib/src/calendar_free_slots.dart').readAsStringSync();
    final provider = File('lib/external_calendar_service.dart').readAsStringSync();
    expect(main, contains("part 'src/calendar_free_slots.dart';"));
    expect(view, contains("ValueKey('b2-calendar-free-slots')"));
    expect(view, contains('showCalendarFreeSlots('));
    expect(source, contains('store.unifiedForDay(target)'));
    expect(source, contains('externalReady && store.agendaContentFilter'));
    expect(source, contains('external.coversRange('));
    expect(source, contains('openUnifiedItemComposer('));
    expect(source, isNot(contains('store.upsert(')));
    expect(source, isNot(contains('store.createRecurringSeries(')));
    expect(source, isNot(contains('VaultService')));
    expect(provider, contains('bool coversRange('));
  });
}
