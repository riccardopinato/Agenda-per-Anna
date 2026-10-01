import 'dart:io';

import 'package:agenda_per_anna/cycle_tracker_domain.dart';
import 'package:flutter_test/flutter_test.dart';

CycleDayLog _day(
  DateTime date, {
  CycleFlow flow = CycleFlow.none,
  int pain = 0,
  List<String> symptoms = const [],
  List<String> moods = const [],
  String discharge = '',
  bool hadSex = false,
  double? basalTemperature,
  String ovulationTest = '',
}) =>
    CycleDayLog(
      date: date,
      flow: flow,
      painLevel: pain,
      symptoms: symptoms,
      moods: moods,
      discharge: discharge,
      hadSex: hadSex,
      basalTemperature: basalTemperature,
      ovulationTest: ovulationTest,
      createdAt: date,
      updatedAt: date,
    );

void main() {
  test('custom symptoms normalize, deduplicate and survive round-trip', () {
    final settings = const CycleSettings().copyWith(
      customSymptoms: const [
        '  Mal di gambe  ',
        'mal di gambe',
        'Craving',
      ],
    );
    final state = CycleTrackerState(settings: settings);
    final restored = CycleTrackerState.fromJson(state.toJson());

    expect(restored.settings.customSymptoms, ['Mal di gambe', 'Craving']);
    expect(restored.toJson()['v'], CycleTrackerState.currentVersion);
  });

  test('v0.88 cycle payload remains readable without premium fields', () {
    final restored = CycleTrackerState.fromJson({
      'v': 1,
      'settings': {
        'averageCycleLength': 28,
        'averagePeriodLength': 5,
        'trackFertility': true,
      },
      'dayLogs': [
        {
          'date': '2026-09-01',
          'flow': 'medium',
          'painLevel': 2,
          'energyLevel': 3,
          'symptoms': ['cramps'],
          'moods': ['calm'],
          'createdAt': '2026-09-01T08:00:00Z',
          'updatedAt': '2026-09-01T08:00:00Z',
        },
      ],
    });

    expect(restored.settings.customSymptoms, isEmpty);
    expect(restored.logFor(DateTime(2026, 9, 1))?.flow, CycleFlow.medium);
  });

  test('premium analytics are deterministic and descriptive', () {
    var state = const CycleTrackerState();

    for (final start in [
      DateTime(2026, 6, 1),
      DateTime(2026, 6, 29),
      DateTime(2026, 7, 28),
      DateTime(2026, 8, 25),
    ]) {
      for (var offset = 0; offset < 4; offset++) {
        final date = start.add(Duration(days: offset));
        state = state.upsertLog(
          _day(
            date,
            flow: offset == 0 ? CycleFlow.medium : CycleFlow.light,
            pain: offset < 2 ? 3 : 1,
            symptoms: offset < 2 ? const ['cramps'] : const [],
          ),
        );
      }
    }

    state = state.upsertLog(
      _day(
        DateTime(2026, 9, 8),
        symptoms: const ['headache', 'custom:Craving'],
        moods: const ['sensitive'],
        discharge: 'eggWhite',
        hadSex: true,
        basalTemperature: 36.55,
        ovulationTest: 'positive',
      ),
    );

    final insights = CyclePremiumAnalytics.insights(
      state,
      referenceDate: DateTime(2026, 9, 10),
    );

    expect(insights.periodCount, 4);
    expect(insights.loggedDays, 17);
    expect(insights.shortestCycle, 28);
    expect(insights.longestCycle, 29);
    expect(insights.cycleVariabilityDays, greaterThanOrEqualTo(0));
    expect(insights.basalTemperatureEntries, 1);
    expect(insights.positiveOvulationTests, 1);
    expect(insights.cervicalMucusEntries, 1);
    expect(insights.sexualActivityEntries, 1);
    expect(
      insights.symptomPatterns.firstWhere((item) => item.key == 'cramps')
          .periodCount,
      8,
    );
    expect(insights.estimatedWindowStart, isNotNull);
    expect(insights.estimatedWindowEnd, isNotNull);
  });

  test('premium access is centralized and cycle UI does not own billing state', () {
    final premium =
        File('lib/premium_entitlement_service.dart').readAsStringSync();
    final screen =
        File('lib/src/screens/cycle_tracker_screen.dart').readAsStringSync();

    expect(premium, contains('enum PremiumCapability'));
    expect(premium, contains('cycleInsights'));
    expect(premium, contains('cycleAdvancedTracking'));
    expect(premium, contains('ANNA_PREMIUM_PREVIEW'));
    expect(screen, contains('PremiumEntitlementService.instance'));
    expect(screen, isNot(contains('RevenueCat')));
    expect(screen, isNot(contains('Purchases.configure')));
  });
}
