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
      'PlannerScreen(store: widget.store, embedded: true)',
      'CalendarHubScreen(',
      'DiaryMemoriesScreen(store: widget.store)',
      'MoreScreen(store: widget.store)',
    ]) {
      expect(source, contains(page));
    }

    for (final id in const <String>[
      'main-nav-today',
      'main-nav-messages',
      'main-nav-memories',
      'main-nav-more',
      'main-rail-today',
      'main-rail-messages',
      'main-rail-memories',
      'main-rail-more',
    ]) {
      expect(source, contains(id));
    }

    expect(source, contains('NavigationBar('));
    expect(source, contains('NavigationRail('));
    expect(source, contains('LayoutBuilder('));
    expect(source, contains('AnnaResponsiveShellPolicy.useRail'));
    expect(source, contains('AnnaResponsiveShellPolicy.extendRail'));
    expect(source, contains('Offstage('));
    expect(source, contains("ValueKey<String>('main-shell-content')"));
  });

  test('v1.05-A1 keeps the page subtree mounted across breakpoint changes', () {
    final source =
        File('lib/src/screens/home_inbox_search.dart').readAsStringSync();

    expect(
      RegExp(r'body:\s*Row\([\s\S]*main-shell-content').hasMatch(source),
      isTrue,
    );
    expect(
      RegExp(r'bottomNavigationBar:\s*useRail\s*\?\s*null').hasMatch(source),
      isTrue,
    );
    expect(
      source,
      isNot(contains(
        "if (!useRail) {\n          return Scaffold(",
      )),
    );
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
