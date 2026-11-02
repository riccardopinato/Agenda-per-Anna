import 'package:agenda_per_anna/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  AgendaItem item(String id, DateTime date, {ItemType type = ItemType.appointment,
    bool done = false, TimeOfDay? start, TimeOfDay? end,
    RecurrenceRule recurrence = RecurrenceRule.none, String? series}) =>
    AgendaItem(id: id, title: id, note: '', date: date, type: type,
      done: done, start: start, end: end,
      recurrenceRule: recurrence, recurrenceSeriesId: series);
  TimeOfDay at(int hour, [int minute = 0]) =>
    TimeOfDay(hour: hour, minute: minute);

  test('tomorrow handles year and leap day boundaries', () {
    expect(quickWinTomorrow(DateTime(2026, 12, 31)), DateTime(2027, 1, 1));
    expect(quickWinTomorrow(DateTime(2028, 2, 28)), DateTime(2028, 2, 29));
  });

  test('overdue includes unfinished previous-day private tasks only', () {
    final today = DateTime(2026, 11, 2);
    final overdue = overduePrivateTasks([
      item('old', DateTime(2026, 10, 28), type: ItemType.task),
      item('recent', DateTime(2026, 11, 1), type: ItemType.task),
      item('done', DateTime(2026, 11, 1), type: ItemType.task, done: true),
      item('today', today, type: ItemType.task),
      item('appointment', DateTime(2026, 11, 1)),
    ], today);
    expect(overdue.map((e) => e.id), ['recent', 'old']);
    expect(canPostponeTask(overdue.first, now: today), isTrue);
    expect(canPostponeTask(item('future', DateTime(2026, 11, 10),
      type: ItemType.task), now: today), isFalse);
    expect(canPostponeTask(item('recurring', today, type: ItemType.task,
      recurrence: RecurrenceRule.weekly, series: 's')), isFalse);
  });

  test('collision check skips self, tasks and adjacent endpoints', () {
    final day = DateTime(2026, 11, 2);
    final candidate = item('self', day, start: at(10), end: at(11));
    final matches = findAppointmentConflicts(
      candidate: candidate,
      visibleEntries: [
        UnifiedAgendaEntry.private(candidate),
        UnifiedAgendaEntry.private(item('before', day,
          start: at(9), end: at(10))),
        UnifiedAgendaEntry.private(item('hit', day,
          start: at(10,30), end: at(11,30))),
        UnifiedAgendaEntry.private(item('after', day,
          start: at(11), end: at(12))),
        UnifiedAgendaEntry.private(item('task', day,
          type: ItemType.task, start: at(10), end: at(12))),
      ]);
    expect(matches.map((e) => e.id), ['hit']);
  });

  test('overnight and untimed appointments are conservatively occupied', () {
    final day = DateTime(2026, 11, 2);
    final candidate = item('candidate', day, start: at(0,30), end: at(1));
    final matches = findAppointmentConflicts(
      candidate: candidate,
      visibleEntries: [
        UnifiedAgendaEntry.private(item('night',
          DateTime(2026, 11, 1), start: at(23), end: at(1))),
        UnifiedAgendaEntry.private(item('all-day', day)),
      ]);
    expect(matches.map((e) => e.id), ['all-day', 'night']);
  });

  test('all five supported languages have quick-action labels', () {
    for (final lang in ['en','it','es','fr','pt']) {
      final strings = AnnaStrings(lang);
      for (final key in ['duplicateDate','postpone','overdue',
        'tomorrow','conflictTitle','conflictSave']) {
        expect(quickWinText(strings, key).isNotEmpty, isTrue);
      }
    }
  });
}
