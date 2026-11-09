import 'dart:io';

import 'package:agenda_per_anna/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final date = DateTime(2026, 11, 4);

  UnifiedAgendaEntry task(
    String id, {
    TimeOfDay? start,
    TimeOfDay? end,
    bool done = false,
  }) {
    return UnifiedAgendaEntry.private(
      AgendaItem(
        id: id,
        title: 'Synthetic task',
        note: '',
        date: date,
        type: ItemType.task,
        start: start,
        end: end,
        done: done,
      ),
    );
  }

  test('only explicit start/end contributes to recorded task time', () {
    final observed = RecordedTaskTime.fromVisible([
      task('scheduled',
          start: const TimeOfDay(hour: 10, minute: 0),
          end: const TimeOfDay(hour: 11, minute: 45)),
      task('unknown'),
      task('partial', start: const TimeOfDay(hour: 12, minute: 0)),
      task('same',
          start: const TimeOfDay(hour: 9, minute: 0),
          end: const TimeOfDay(hour: 9, minute: 0)),
      task('done',
          start: const TimeOfDay(hour: 15, minute: 0),
          end: const TimeOfDay(hour: 16, minute: 0),
          done: true),
    ], day: date);
    expect(observed.minutes, 105);
    expect(observed.withTime, 1);
    expect(observed.withoutTime, 3);
  });

  test('overnight real start/end is preserved without guessing', () {
    final result = RecordedTaskTime.fromVisible([
      task('night',
          start: const TimeOfDay(hour: 23, minute: 15),
          end: const TimeOfDay(hour: 0, minute: 30)),
    ], day: date);
    expect(result.minutes, 75);
    expect(result.withTime, 1);
    expect(result.withoutTime, 0);
  });

  test('adjacent-day task is excluded from current-day duration provenance', () {
    final adjacent = UnifiedAgendaEntry.private(
      AgendaItem(
        id: 'yesterday-task',
        title: 'Adjacent source busy slot',
        note: '',
        date: date.subtract(const Duration(days: 1)),
        type: ItemType.task,
        start: const TimeOfDay(hour: 23, minute: 0),
        end: const TimeOfDay(hour: 1, minute: 0),
      ),
    );
    final today = RecordedTaskTime.fromVisible(
      [adjacent, task('today-unknown')], day: date);
    expect(today.minutes, 0);
    expect(today.withTime, 0);
    expect(today.withoutTime, 1);
  });

  test('visible duplicate task is counted once, never silently subtracted', () {
    final item = task('same',
        start: const TimeOfDay(hour: 10, minute: 0),
        end: const TimeOfDay(hour: 10, minute: 30));
    final advice = RealisticDayAdvisor.evaluate(
      day: date,
      visibleEntries: [item, item],
      pendingTasks: 1,
      bufferMinutes: 60,
    );
    expect(advice.tasksWithRecordedTime, 1);
    expect(advice.recordedTaskMinutes, 30);
    // The calendar-only total is unchanged; explicit task time within
    // otherwise free slots now reduces usable capacity exactly once.
    expect(advice.freeMinutes, 720);
    expect(advice.bookedTaskMinutes, 30);
    expect(advice.usableMinutes, 720 - 30 - 60);
  });

  test('no visible task timestamps means no fabricated duration', () {
    final advice = RealisticDayAdvisor.evaluate(
      day: date,
      visibleEntries: [task('not-timed')],
      pendingTasks: 8,
    );
    expect(advice.recordedTaskMinutes, 0);
    expect(advice.tasksWithRecordedTime, 0);
    expect(advice.tasksWithoutRecordedTime, 1);
  });

  test('voluntary nudges are off by default and explicitly reversible', () {
    final source = File('lib/src/realistic_day_advice.dart').readAsStringSync();
    expect(source, contains('bool _nudgesEnabled = false;'));
    expect(source, contains("prefs.getBool('\${key}_nudges') ?? false"));
    expect(source, contains("prefs.setBool('\${key}_nudges', enabled)"));
    expect(source, contains("prefs.setInt('\${key}_snoozed_through', next)"));
    expect(source, contains('DateTime(now.year, now.month, now.day + 7)'));
    expect(source, contains("key: const ValueKey('realistic-day-nudge-snooze')"));
    expect(source, contains('advisePressure'));
    expect(source, contains('snoozedThrough > todayKey'));
  });
}
