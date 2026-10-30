import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('UI5 Oggi places real day overview before diary and secondary sections', () {
    final source = File('lib/src/planner_views.dart').readAsStringSync();
    final planner = source
        .split('class _PlannerScreenState')[1]
        .split('class _CalendarDayContextCard')[0];
    final focus = planner.indexOf('_TodayFocusCard(');
    final diary = planner.indexOf('_TodayCompactDiaryPreview(');
    final overview = planner.indexOf('_TodayCompactSummary(');
    final wellbeing = planner.indexOf('_TodayWellbeingCard(');
    final rituals = planner.indexOf('DailyRitualCard(');
    final stream = planner.indexOf('_DayLifeStream(');
    final timeline = planner.indexOf('ExpansionTile(');
    expect(focus, greaterThan(0));
    expect(overview, greaterThan(0));
    expect(focus, greaterThan(overview));
    expect(wellbeing, greaterThan(focus));
    expect(diary, greaterThan(wellbeing));
    expect(rituals, greaterThan(diary));
    expect(stream, greaterThan(rituals));
    expect(timeline, greaterThan(stream));
  });

  test('Today keeps canonical editor, filters, capture, privacy and rail', () {
    final source = File('lib/src/planner_views.dart').readAsStringSync();
    final planner = source
        .split('class _PlannerScreenState')[1]
        .split('class _CalendarDayContextCard')[0];
    for (final required in [
      'AnnaJournalSectionHeading(title: strings.diary)',
      'AgendaContentFilterBar(store: widget.store)',
      'FloatingActionButton.extended(',
      'UnifiedCaptureEntryPoint.day',
      'hideDetails: widget.store.preferences.hideHomeDetails',
      'today-pinned-section',
      'memoryRecall.onThisDay',
      'DayTimeline(',
      'maxWidth: AnnaDesignTokens.readingContentWidth',
    ]) {
      expect(planner, contains(required));
    }
    expect(planner, contains('EdgeInsets.fromLTRB(20, 14, 20, 110)'));
    expect(planner, contains('_TodayCompactDiaryPreview('));
  });
}
