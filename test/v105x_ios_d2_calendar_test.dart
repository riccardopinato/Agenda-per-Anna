import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Calendar C keeps month/week state, dates and notebooks', () {
    final file = File('lib/src/planner_views.dart').readAsStringSync();
    final calendar = file
        .split('class _CalendarHubScreenState')[1]
        .split('class CalendarScreen')[0];
    for (final item in [
      'toolbarHeight: 78',
      'headlineMedium',
      'SegmentedButton<_CalendarHubView>',
      'WidgetStatePropertyAll',
      '_CalendarHubView.month',
      '_CalendarHubView.week',
      'AnnaJournalCard(',
      'AnnaVisualDomain.calendar',
      'calendar-open-month-notebook',
      'calendar-open-year-overview',
      'MonthScreen(store: widget.store)',
      'YearScreen(store: widget.store)',
      'CalendarScreen(',
      'WeekScreen(',
      'IndexedStack(',
    ]) {
      expect(calendar, contains(item));
    }
  });

  test('New Calendar C presentation does not change calendar data ownership', () {
    final source = File('lib/src/planner_views.dart').readAsStringSync();
    final calendar = source
        .split('class _CalendarHubScreenState')[1]
        .split('class CalendarScreen')[0];
    expect(calendar, isNot(contains('savePreferences(')));
    expect(calendar, isNot(contains('CloudSyncService.instance')));
    expect(calendar, contains('store: widget.store'));
  });
}
