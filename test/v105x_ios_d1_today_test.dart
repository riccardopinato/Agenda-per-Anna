import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Today C places daily focus and diary before secondary summaries', () {
    final source = File('lib/src/planner_views.dart').readAsStringSync();
    final planner = source
        .split('class _PlannerScreenState')[1]
        .split('class _CalendarDayContextCard')[0];
    final focus = planner.indexOf('_TodayFocusCard(');
    final diary = planner.indexOf('JournalEditor(store: widget.store, date: day)');
    final overview = planner.indexOf('_DayLifeOverviewCard(');
    final wellbeing = planner.indexOf('_TodayWellbeingCard(');
    final rituals = planner.indexOf('DailyRitualCard(');
    final stream = planner.indexOf('_DayLifeStream(');
    final timeline = planner.indexOf('ExpansionTile(');
    expect(focus, greaterThan(0));
    expect(diary, greaterThan(focus));
    expect(overview, greaterThan(diary));
    expect(wellbeing, greaterThan(overview));
    expect(rituals, greaterThan(wellbeing));
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
  });
}
