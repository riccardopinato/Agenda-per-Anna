import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:agenda_per_anna/main.dart';

void main() {
  test('v1.05-A1 responsive shell breakpoints are deterministic', () {
    expect(AnnaResponsiveShellPolicy.useRail(839), isFalse);
    expect(AnnaResponsiveShellPolicy.useRail(840), isTrue);
    expect(AnnaResponsiveShellPolicy.extendRail(1179), isFalse);
    expect(AnnaResponsiveShellPolicy.extendRail(1180), isTrue);
  });

  test('v1.05-A1 preserves the existing four destinations on both shells', () {
    final source =
        File('lib/src/screens/home_inbox_search.dart').readAsStringSync();

    for (final page in const <String>[
      'HomeScreen(store: widget.store)',
      'CalendarScreen(store: widget.store)',
      'WeekScreen(store: widget.store)',
      'PlannerScreen(store: widget.store)',
    ]) {
      expect(source, contains(page));
    }

    for (final id in const <String>[
      'main-nav-home',
      'main-nav-month',
      'main-nav-week',
      'main-nav-today',
      'main-rail-home',
      'main-rail-month',
      'main-rail-week',
      'main-rail-today',
    ]) {
      expect(source, contains(id));
    }

    expect(source, contains('NavigationBar('));
    expect(source, contains('NavigationRail('));
    expect(source, contains('LayoutBuilder('));
    expect(source, contains('AnnaResponsiveShellPolicy.useRail'));
    expect(source, contains('AnnaResponsiveShellPolicy.extendRail'));
  });

  test('v1.05-A1 changes presentation only', () {
    final source =
        File('lib/src/screens/home_inbox_search.dart').readAsStringSync();

    for (final forbidden in const <String>[
      'SharedPreferences.getInstance',
      'LocalStateStore.instance',
      'Supabase',
      'NavigationDatabase',
      'ShellRepository',
    ]) {
      expect(source, isNot(contains(forbidden)));
    }
  });
}
