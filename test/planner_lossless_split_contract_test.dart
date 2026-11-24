import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/planner_source_parts.dart';

void main() {
  test('planner stays in one canonical Dart library across three parts', () {
    final entrypoint = File('lib/main.dart').readAsStringSync();
    for (final path in [
      'src/planner_views.dart',
      'src/planner_week_views.dart',
      'src/planner_month_year_views.dart',
    ]) {
      expect(entrypoint, contains("part '$path';"));
    }

    final source = readPlannerSourceParts();
    final calendar = source.indexOf('class CalendarHubScreen');
    final today = source.indexOf('class PlannerScreen');
    final week = source.indexOf('class WeekScreen');
    final month = source.indexOf('class MonthScreen');
    final year = source.indexOf('class YearScreen');
    expect(calendar, greaterThanOrEqualTo(0));
    expect(today, greaterThan(calendar));
    expect(week, greaterThan(today));
    expect(month, greaterThan(week));
    expect(year, greaterThan(month));
    expect('class WeekScreen'.allMatches(source).length, 1);
    expect('class MonthScreen'.allMatches(source).length, 1);
    expect('class YearScreen'.allMatches(source).length, 1);
  });
}
