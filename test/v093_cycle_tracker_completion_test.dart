import 'dart:io';

import 'package:agenda_per_anna/cycle_tracker_domain.dart';
import 'package:flutter_test/flutter_test.dart';

CycleDayLog _periodDay(DateTime date, {CycleFlow flow = CycleFlow.medium}) {
  return CycleDayLog(
    date: date,
    flow: flow,
    createdAt: date,
    updatedAt: date,
  );
}

void main() {
  test('v0.93 settings remain backward compatible with older payloads', () {
    final state = CycleTrackerState.fromJson({
      'v': 2,
      'settings': {
        'averageCycleLength': 28,
        'averagePeriodLength': 5,
        'regularityMode': 'unknown',
      },
      'dayLogs': const [],
    });

    expect(state.settings.onboardingComplete, isFalse);
    expect(state.settings.contraceptiveReminderEnabled, isFalse);
    expect(state.settings.contraceptiveReminderHour, 21);
    expect(state.settings.dailyLogReminderHour, 20);
  });

  test('recent cycles receive more weight in prediction v2', () {
    var state = const CycleTrackerState(
      settings: CycleSettings(
        onboardingComplete: true,
        averageCycleLength: 28,
        averagePeriodLength: 4,
      ),
    );

    final starts = [
      DateTime(2026, 1, 1),
      DateTime(2026, 1, 31), // 30
      DateTime(2026, 3, 2), // 30
      DateTime(2026, 3, 31), // 29
      DateTime(2026, 4, 29), // 29
      DateTime(2026, 5, 27), // 28
      DateTime(2026, 6, 24), // 28
    ];

    for (final start in starts) {
      final logs = <CycleDayLog>[];
      for (var i = 0; i < 4; i++) {
        logs.add(
          _periodDay(
            start.add(Duration(days: i)),
            flow: i == 0 ? CycleFlow.medium : CycleFlow.light,
          ),
        );
      }
      state = state.upsertLogs(logs);
    }

    final prediction = CycleTrackerEngine.predict(
      state,
      referenceDate: DateTime(2026, 7, 1),
    );

    expect(prediction.averageCycleLength, 29);
    expect(prediction.periodWindowStart, isNotNull);
    expect(prediction.periodWindowEnd, isNotNull);
    expect(
      prediction.periodWindowEnd!.isAfter(prediction.periodWindowStart!),
      isTrue,
    );
    expect(prediction.variabilityDays, greaterThanOrEqualTo(0));
  });

  test('irregular user setting prevents an overconfident high estimate', () {
    var state = const CycleTrackerState(
      settings: CycleSettings(
        onboardingComplete: true,
        regularityMode: 'irregular',
      ),
    );

    for (final start in [
      DateTime(2026, 1, 1),
      DateTime(2026, 1, 29),
      DateTime(2026, 2, 26),
      DateTime(2026, 3, 26),
    ]) {
      state = state.upsertLogs([
        _periodDay(start),
        _periodDay(start.add(const Duration(days: 1))),
        _periodDay(start.add(const Duration(days: 2))),
      ]);
    }

    final prediction = CycleTrackerEngine.predict(
      state,
      referenceDate: DateTime(2026, 4, 1),
    );

    expect(prediction.confidence, CyclePredictionConfidence.medium);
  });

  test('bulk cycle writes preserve all dates in one canonical state', () {
    final now = DateTime(2026, 8, 10);
    final state = const CycleTrackerState().upsertLogs([
      _periodDay(now),
      _periodDay(now.add(const Duration(days: 1)), flow: CycleFlow.light),
      _periodDay(now.add(const Duration(days: 2)), flow: CycleFlow.light),
    ]);

    expect(state.dayLogs, hasLength(3));
    expect(CycleTrackerEngine.periods(state).single.periodLength, 3);
  });

  test('cycle UX includes onboarding, quick range and full private reminders', () {
    final screen =
        File('lib/src/screens/cycle_tracker_screen.dart').readAsStringSync();
    final notifications =
        File('lib/notification_service.dart').readAsStringSync();
    final vault = File('lib/vault_service.dart').readAsStringSync();

    expect(screen, contains('_maybeShowOnboarding'));
    expect(screen, contains('_showQuickPeriodRange'));
    expect(screen, contains('_dailyLogReminderId'));
    expect(screen, contains('_contraceptiveReminderId'));
    expect(screen, contains('_syncCycleReminders'));
    expect(screen, contains('_responsivePair'));
    expect(screen, contains('_buildTrendCard'));
    expect(notifications, contains('Future<void> scheduleDaily'));
    expect(
      notifications,
      contains('matchDateTimeComponents: DateTimeComponents.time'),
    );
    expect(vault, contains('Future<void> upsertCycleDayLogs'));
  });
}
