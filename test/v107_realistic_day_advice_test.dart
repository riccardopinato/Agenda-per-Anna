import 'package:agenda_per_anna/main.dart';
import 'package:agenda_per_anna/local_state_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  test("adjacent-day appointment blocks today's overlapping time", () async {
    SharedPreferences.setMockInitialValues({});
    await LocalStateStore.instance.resetForTesting();
    final store = AgendaStore();
    await store.load();
    await store.upsert(
      AgendaItem(
        id: 'overnight',
        title: 'Overnight meeting',
        note: '',
        date: DateTime(2026, 11, 2),
        type: ItemType.appointment,
        start: const TimeOfDay(hour: 22, minute: 0),
        end: const TimeOfDay(hour: 10, minute: 0),
      ),
    );
    final entries = visibleEntriesForCalendarFreeSlots(
      store,
      DateTime(2026, 11, 3),
      externalReady: false,
    );
    final advice = RealisticDayAdvisor.evaluate(
      day: DateTime(2026, 11, 3),
      visibleEntries: entries,
      pendingTasks: 1,
    );
    expect(entries.any((entry) => entry.id == 'overnight'), isTrue);
    expect(advice.freeMinutes, 660);
    store.dispose();
    await LocalStateStore.instance.resetForTesting();
  });

  test('untimed upcoming appointment is eligible for preparation', () async {
    SharedPreferences.setMockInitialValues({});
    await LocalStateStore.instance.resetForTesting();
    final store = AgendaStore();
    await store.load();
    await store.upsert(
      AgendaItem(
        id: 'untimed',
        title: 'Buy travel tickets',
        note: '',
        date: DateTime(2026, 11, 4),
        type: ItemType.appointment,
      ),
    );
    final candidates = upcomingPreparationItems(
      store,
      DateTime(2026, 11, 3, 16),
    );
    expect(candidates.map((item) => item.id), contains('untimed'));
    store.dispose();
    await LocalStateStore.instance.resetForTesting();
  });

  test('expired slots do not count as remaining day capacity', () {
    final advice = RealisticDayAdvisor.evaluate(
      day: DateTime(2026, 11, 3),
      visibleEntries: const [],
      pendingTasks: 1,
      now: DateTime(2026, 11, 3, 20, 30),
    );
    expect(advice.freeMinutes, 30);
  });

  testWidgets('hide-details never displays contextual day card', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await LocalStateStore.instance.resetForTesting();
    final store = AgendaStore();
    await store.load();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RealisticDayCard(
            store: store,
            snapshot: store.dayHubSnapshot(DateTime(2026, 11, 3)),
            hideDetails: true,
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('realistic-day-advice')), findsNothing);
    store.dispose();
    await LocalStateStore.instance.resetForTesting();
  });

  test('preparation skips completed-time appointments but keeps untimed', () async {
    SharedPreferences.setMockInitialValues({});
    await LocalStateStore.instance.resetForTesting();
    final store = AgendaStore();
    await store.load();
    for (final item in [
      AgendaItem(
        id: 'passed',
        title: 'Morning appointment',
        note: '',
        date: DateTime(2026, 11, 3),
        type: ItemType.appointment,
        start: const TimeOfDay(hour: 9, minute: 0),
        end: const TimeOfDay(hour: 10, minute: 0),
      ),
      AgendaItem(
        id: 'next',
        title: 'Afternoon appointment',
        note: '',
        date: DateTime(2026, 11, 3),
        type: ItemType.appointment,
        start: const TimeOfDay(hour: 17, minute: 0),
        end: const TimeOfDay(hour: 18, minute: 0),
      ),
      AgendaItem(
        id: 'without-time',
        title: 'Tomorrow appointment',
        note: '',
        date: DateTime(2026, 11, 4),
        type: ItemType.appointment,
      ),
    ]) {
      await store.upsert(item);
    }
    final result = upcomingPreparationItems(
      store,
      DateTime(2026, 11, 3, 12),
    );
    expect(result.map((item) => item.id), ['next', 'without-time']);
    store.dispose();
    await LocalStateStore.instance.resetForTesting();
  });
}
