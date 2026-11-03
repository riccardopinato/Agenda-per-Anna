import 'package:agenda_per_anna/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  AgendaItem appointment(
    String id, {
    required int start,
    required int end,
  }) =>
      AgendaItem(
        id: id,
        title: 'Visible appointment',
        note: '',
        date: DateTime(2026, 11, 3),
        type: ItemType.appointment,
        start: TimeOfDay(hour: start, minute: 0),
        end: TimeOfDay(hour: end, minute: 0),
      );

  test('read-only day advice uses visible appointment intervals', () {
    final view = RealisticDayAdvisor.evaluate(
      day: DateTime(2026, 11, 3),
      visibleEntries: [
        UnifiedAgendaEntry.private(
          appointment('morning', start: 9, end: 14),
        ),
        UnifiedAgendaEntry.private(
          appointment('afternoon', start: 14, end: 21),
        ),
      ],
      pendingTasks: 2,
    );
    expect(view.freeMinutes, 0);
    expect(view.hasPressure, isTrue);
    expect(view.firstFreeSlot, isNull);
  });

  test('a visible gap is only a proposal, not a saved task', () {
    final advice = RealisticDayAdvisor.evaluate(
      day: DateTime(2026, 11, 3),
      visibleEntries: [
        UnifiedAgendaEntry.private(
          appointment('midday', start: 12, end: 13),
        ),
      ],
      pendingTasks: 1,
    );
    expect(advice.freeMinutes, 660);
    expect(advice.firstFreeSlot!.start.hour, 9);
    expect(advice.reasonCode, 'VISIBLE_WINDOW_CAPACITY');
  });
}
