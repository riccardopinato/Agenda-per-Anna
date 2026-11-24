import 'dart:io';

/// Reconstitutes the canonical planner source for legacy source-contract tests.
///
/// The production code uses three `part of '../main.dart'` files within the
/// same Dart library. Tests historically asserted over one contiguous file.
/// Removing only the duplicated part directives restores that exact order
/// without weakening any existing source assertions.
String readPlannerSourceParts() {
  const partHeader = "part of '../main.dart';\n\n";
  final planner = File('lib/src/planner_views.dart').readAsStringSync();
  final week = File('lib/src/planner_week_views.dart').readAsStringSync();
  final monthYear =
      File('lib/src/planner_month_year_views.dart').readAsStringSync();

  for (final source in [planner, week, monthYear]) {
    if (!source.startsWith(partHeader)) {
      throw StateError('Planner source is not a canonical main.dart part.');
    }
  }

  return planner +
      week.substring(partHeader.length) +
      monthYear.substring(partHeader.length);
}
