import 'dart:io';

import 'package:agenda_per_anna/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// N18-01/03: the approved Organic Home replaces the large WeeklyReviewHomeCard
/// with a compact paired tile. Keep the original reminder service and settings
/// route reachable; source/widget PASS is not notification-delivery evidence.
void main() {
  test('Organic reminder reconciliation preserves Classic and canonical owner',
      () {
    final planner = File('lib/src/planner_views.dart').readAsStringSync();
    final review = File('lib/src/weekly_review.dart').readAsStringSync();

    final start = planner.indexOf('class _PlannerScreenState');
    final end = planner.indexOf('class _CalendarDayContextCard', start);
    expect(start, greaterThanOrEqualTo(0));
    expect(end, greaterThan(start));
    final today = planner.substring(start, end);
    expect(today, contains('widget.embedded &&'));
    expect(today, contains('AnnaEditorialTodayMode.enabled.value &&'));
    expect(today,
        contains('widget.store.preferences.weeklyReviewReminderEnabled'));
    expect(today, contains(
        'unawaited(WeeklyReviewReminders.reconcile(widget.store));'));
    expect(today, contains("if (card == 'review' && !editorial)"));
    expect(today, contains('WeeklyReviewHomeCard('));

    expect(review, contains('class WeeklyReviewReminders'));
    expect(review, contains('class WeeklyReviewSettingsPage'));
    expect(review, contains("'weekly-review-reminder-settings'"));
    expect(review,
        contains('WeeklyReviewSettingsPage(store:widget.store)'));
    expect(review, contains("wrText(c,'reminders')"));
  });

  testWidgets('Review settings are reachable without the old Home review card',
      (tester) async {
    await initializeDateFormatting();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final store = AgendaStore();
    addTearDown(store.dispose);
    await tester.pumpWidget(MaterialApp(
      home: WeeklyReviewScreen(
        store: store,
        reviewWeek: DateTime(2026, 11, 16),
        planWeek: DateTime(2026, 11, 16),
      ),
    ));

    final action = find.byKey(
      const ValueKey<String>('weekly-review-reminder-settings'),
    );
    expect(action, findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(find.byType(WeeklyReviewSettingsPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
