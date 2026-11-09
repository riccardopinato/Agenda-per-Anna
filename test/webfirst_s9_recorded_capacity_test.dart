import 'package:agenda_per_anna/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// S9: synthetic, authorized in-memory entries only. These tests verify
/// derived time arithmetic, NOT real-device calendars or a saved schedule.
void main() {
  final day = DateTime(2026, 11, 9);

  UnifiedAgendaEntry item(
    String id, {
    ItemType type = ItemType.task,
    DateTime? date,
    TimeOfDay? start,
    TimeOfDay? end,
    bool done = false,
  }) {
    return UnifiedAgendaEntry.private(
      AgendaItem(
        id: id,
        title: 'Synthetic entry',
        note: '',
        date: date ?? day,
        type: type,
        start: start,
        end: end,
        done: done,
      ),
    );
  }

  TimeOfDay at(int hour, [int minute = 0]) =>
      TimeOfDay(hour: hour, minute: minute);

  test('S9 subtracts timed tasks only in calendar-free gaps, once', () {
    final appointment = item('meeting',
        type: ItemType.appointment, start: at(10), end: at(11));
    final taskA = item('A', start: at(10, 30), end: at(11, 30));
    final taskB = item('B', start: at(11, 15), end: at(12));
    final advice = RealisticDayAdvisor.evaluate(
      day: day,
      visibleEntries: [appointment, taskA, taskB, taskB],
      pendingTasks: 2,
      bufferMinutes: 30,
    );
    expect(advice.freeMinutes, 660); // One actual appointment hour.
    expect(advice.recordedTaskMinutes, 105); // Provenance, not a deduction.
    expect(advice.tasksWithRecordedTime, 2);
    expect(advice.bookedTaskMinutes, 60); // 11:00–12:00 union only.
    expect(advice.usableMinutes, 570); // 660 - 60 - 30.
    expect(advice.firstFreeSlot?.start.hour, 9);
  });

  test('S9 suggests first actual gap after timed task', () {
    final advice = RealisticDayAdvisor.evaluate(
      day: day,
      visibleEntries: [
        item('morning', start: at(9), end: at(11)),
      ],
      pendingTasks: 1,
    );
    expect(advice.freeMinutes, 720);
    expect(advice.bookedTaskMinutes, 120);
    expect(advice.firstFreeSlot?.start.hour, 11);
    expect(advice.usableMinutes, 600);
  });

  test('S9 overnight task from previous date consumes only overlap', () {
    final advice = RealisticDayAdvisor.evaluate(
      day: day,
      visibleEntries: [
        item('night', date: DateTime(2026, 11, 8),
            start: at(23, 30), end: at(9, 30)),
      ],
      pendingTasks: 0,
    );
    expect(advice.freeMinutes, 720);
    expect(advice.bookedTaskMinutes, 30);
    expect(advice.recordedTaskMinutes, 0); // Source day is yesterday.
    expect(advice.firstFreeSlot?.start, DateTime(2026, 11, 9, 9, 30));
  });

  test('S9 unknown, ambiguous, done or hidden entries cannot consume time', () {
    final visible = [
      item('unknown'),
      item('partial', start: at(10)),
      item('ambiguous', start: at(13), end: at(13)),
      item('done', start: at(14), end: at(16), done: true),
    ];
    final advice = RealisticDayAdvisor.evaluate(
      day: day, visibleEntries: visible, pendingTasks: 3,
      bufferMinutes: 15,
    );
    expect(advice.bookedTaskMinutes, 0);
    expect(advice.tasksWithoutRecordedTime, 3);
    expect(advice.usableMinutes, 705);
    // Privacy rule: the projection cannot inspect a task that the caller
    // excluded from its authorized visibleEntries list.
    final hidden = item('hidden', start: at(9), end: at(21));
    final onlyVisible = RealisticDayAdvisor.evaluate(
      day: day, visibleEntries: visible, pendingTasks: 3,
    );
    final explicitlyIncluded = RealisticDayAdvisor.evaluate(
      day: day, visibleEntries: [...visible, hidden], pendingTasks: 4,
    );
    expect(onlyVisible.bookedTaskMinutes, 0);
    expect(explicitlyIncluded.bookedTaskMinutes, 720);
  });

  test('S9 now clips task time and after-window is elapsed, not congested', () {
    final ongoing = item('ongoing', start: at(11), end: at(13));
    final during = RealisticDayAdvisor.evaluate(
      day: day,
      visibleEntries: [ongoing],
      pendingTasks: 1,
      now: DateTime(2026, 11, 9, 12, 15),
      bufferMinutes: 15,
    );
    expect(during.freeMinutes, 525); // 12:15–21:00.
    expect(during.bookedTaskMinutes, 45); // Only 12:15–13:00.
    expect(during.usableMinutes, 465);
    final after = RealisticDayAdvisor.evaluate(
      day: day,
      visibleEntries: [ongoing],
      pendingTasks: 1,
      now: DateTime(2026, 11, 9, 22),
    );
    expect(after.freeMinutes, 0);
    expect(after.bookedTaskMinutes, 0);
    expect(after.reasonCode, 'VISIBLE_WINDOW_ELAPSED');
    expect(after.hasPressure, false);
    expect(after.firstFreeSlot, isNull);
  });

  test('S9 overlapping events and task never create negative time', () {
    final advice = RealisticDayAdvisor.evaluate(
      day: day,
      visibleEntries: [
        item('first-meeting', type: ItemType.appointment,
            start: at(9), end: at(15)),
        item('second-meeting', type: ItemType.appointment,
            start: at(14), end: at(20)),
        item('task-overlap', start: at(18), end: at(20, 30)),
        item('task-tail', start: at(20), end: at(21)),
      ],
      pendingTasks: 2,
      bufferMinutes: 120,
    );
    expect(advice.freeMinutes, 60);
    expect(advice.bookedTaskMinutes, 60); // 20:00–21:00 union.
    expect(advice.usableMinutes, 0);
    expect(advice.firstFreeSlot, isNull);
    expect(advice.hasPressure, true);
  });

  test('S9 is read-only and never schedules or mutates original entries', () {
    final source = item('original', start: at(10), end: at(11));
    final beforeStart = source.start;
    final beforeEnd = source.end;
    final values = <UnifiedAgendaEntry>[source];
    final result = RealisticDayAdvisor.evaluate(
        day: day, visibleEntries: values, pendingTasks: 1);
    expect(result.bookedTaskMinutes, 60);
    expect(values.single, same(source));
    expect(source.start, beforeStart);
    expect(source.end, beforeEnd);
  });
}
