import 'dart:io';

import 'package:agenda_per_anna/cycle_tracker_domain.dart';
import 'package:flutter_test/flutter_test.dart';

CycleDayLog _log(
  int year,
  int month,
  int day,
  CycleFlow flow,
) {
  final date = DateTime(year, month, day);
  return CycleDayLog(
    date: date,
    flow: flow,
    createdAt: date,
    updatedAt: date,
  );
}

void main() {
  test('cycle state round-trips without losing sensitive day data', () {
    final state = const CycleTrackerState().upsertLog(
      CycleDayLog(
        date: DateTime(2026, 3, 4),
        flow: CycleFlow.medium,
        painLevel: 3,
        energyLevel: 2,
        symptoms: const ['cramps', 'headache'],
        moods: const ['sensitive'],
        notes: 'Private note',
        createdAt: DateTime(2026, 3, 4, 9),
        updatedAt: DateTime(2026, 3, 4, 10),
      ),
    );

    final restored = CycleTrackerState.fromJson(state.toJson());
    final log = restored.logFor(DateTime(2026, 3, 4));

    expect(log, isNotNull);
    expect(log!.flow, CycleFlow.medium);
    expect(log.painLevel, 3);
    expect(log.energyLevel, 2);
    expect(log.symptoms, containsAll(['cramps', 'headache']));
    expect(log.moods, contains('sensitive'));
    expect(log.notes, 'Private note');
  });

  test('prediction uses recent recorded cycles deterministically', () {
    var state = const CycleTrackerState();

    for (final start in [
      DateTime(2026, 1, 1),
      DateTime(2026, 1, 29),
      DateTime(2026, 2, 26),
    ]) {
      for (var offset = 0; offset < 4; offset++) {
        final day = start.add(Duration(days: offset));
        state = state.upsertLog(
          CycleDayLog(
            date: day,
            flow: offset == 0 ? CycleFlow.medium : CycleFlow.light,
            createdAt: day,
            updatedAt: day,
          ),
        );
      }
    }

    final prediction = CycleTrackerEngine.predict(
      state,
      referenceDate: DateTime(2026, 3, 10),
    );

    expect(prediction.averageCycleLength, 28);
    expect(prediction.averagePeriodLength, 4);
    expect(prediction.nextPeriodStart, DateTime(2026, 3, 26));
    expect(prediction.ovulationDate, DateTime(2026, 3, 12));
    expect(prediction.fertileStart, DateTime(2026, 3, 7));
    expect(prediction.fertileEnd, DateTime(2026, 3, 13));
    expect(prediction.currentCycleDay, 13);
    expect(prediction.confidence, CyclePredictionConfidence.medium);
    expect(prediction.phase, CyclePhase.fertile);
  });

  test('isolated spotting does not create a menstrual period', () {
    var state = const CycleTrackerState();
    state = state.upsertLog(_log(2026, 4, 1, CycleFlow.spotting));
    state = state.upsertLog(_log(2026, 4, 10, CycleFlow.medium));
    state = state.upsertLog(_log(2026, 4, 11, CycleFlow.light));

    final periods = CycleTrackerEngine.periods(state);

    expect(periods, hasLength(1));
    expect(periods.single.start, DateTime(2026, 4, 10));
    expect(periods.single.periodLength, 2);
  });

  test('cycle data stays inside the encrypted Vault persistence boundary', () {
    final vault = File('lib/vault_service.dart').readAsStringSync();
    final backup = File('lib/backup_service.dart').readAsStringSync();
    final cloud = File('lib/cloud_sync_service.dart').readAsStringSync();
    final screen =
        File('lib/src/screens/cycle_tracker_screen.dart').readAsStringSync();

    expect(vault, contains("'cycleTracker': _cycleTrackerState.toJson()"));
    expect(vault, contains('CycleTrackerState get cycleTrackerState'));
    expect(backup, isNot(contains('CycleTrackerState')));
    expect(cloud, isNot(contains('CycleTrackerState')));
    expect(screen, contains('if (!vault.unlocked)'));
    expect(screen, contains('cyclePrivateReminder'));
  });
}
