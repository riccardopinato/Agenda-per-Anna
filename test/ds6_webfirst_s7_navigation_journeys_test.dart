import 'dart:io';

import 'package:agenda_per_anna/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// S7 runs the actual Flutter shell and canonical routes using a synthetic
/// empty guest store. It is NOT physical-device, browser or sync certification.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('it_IT', null);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      AnnaEditorialTodayMode.storageKey: true,
    });
    AnnaEditorialTodayMode.enabled.value = true;
  });

  tearDown(() {
    AnnaEditorialTodayMode.enabled.value = false;
  });

  Future<void> settlePush(WidgetTester tester) async {
    // Navigator inserts a new MaterialPageRoute on the next frame. Do not
    // mistake a single long pump for the route's first frame.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
  }

  Future<void> settlePop(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
  }

  Future<void> findInList(
    WidgetTester tester, Finder target, {
    double delta = 170,
  }) async {
    await tester.scrollUntilVisible(
      target,
      delta,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 24,
    );
    // scrollUntilVisible stops once a lazily built element EXISTS; it may
    // still sit below the attached navigation dock's actual hit-test area.
    // Position the existing ListTile within the upper portion of the viewport.
    await Scrollable.ensureVisible(
      tester.element(target),
      alignment: 0.3,
      duration: const Duration(milliseconds: 150),
    );
    await tester.pump(const Duration(milliseconds: 200));
  }

  testWidgets('S7 mobile shell navigates through real Search, Settings and '
      'Appearance, returns to tabs and opens only canonical Create',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final store = AgendaStore();
    store.preferences = const AgendaPreferences(
      onboardingDone: true,
      appLanguage: AppLanguage.italian,
    );
    await tester.pumpWidget(
      AgendaApp(store: store, bypassIdentityForTesting: true),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(MainShell), findsOneWidget);
    expect(find.byKey(const ValueKey('main-editorial-dock')), findsOneWidget);

    // The four destinations are the original IndexedStack pages, not
    // additional Navigator routes. The center stays reserved for +Create.
    await tester.tap(find.byKey(const ValueKey('main-nav-more')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(MoreScreen), findsOneWidget);

    final search = find.byKey(const ValueKey('more-search'));
    await tester.ensureVisible(search);
    await tester.tap(search);
    await settlePush(tester);
    expect(find.byType(PersonalSearchConnectionsScreen), findsOneWidget);
    final query = find.byKey(const ValueKey('approved-search-query'));
    await tester.enterText(query, 'not-present-synthetic');
    await tester.pump();
    expect(find.byKey(const ValueKey('approved-search-clear')), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await settlePop(tester);
    expect(find.byType(PersonalSearchConnectionsScreen), findsNothing);
    expect(find.byType(MoreScreen), findsOneWidget);

    final settings = find.byKey(const ValueKey('more-settings'));
    await findInList(tester, settings);
    await tester.tap(settings);
    await settlePush(tester);
    expect(find.byType(SettingsHubScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('qw2-settings-search')), findsOneWidget);

    final appearance = find.byKey(const ValueKey('settings-hub-appearance'));
    await findInList(tester, appearance);
    await tester.tap(appearance);
    await settlePush(tester);
    expect(find.byType(AppearanceColorsScreen), findsOneWidget);

    // Back/cancel must keep the same settings route rather than duplicating it.
    // Use browser/system Back to validate the route stack. pageBack() only
    // presses an auto-generated AppBar BackButton, which is not guaranteed
    // for all embedded routes and is not the browser Back gesture.
    await tester.binding.handlePopRoute();
    await settlePop(tester);
    expect(find.byType(SettingsHubScreen), findsOneWidget);
    // Use browser/system Back to validate the route stack. pageBack() only
    // presses an auto-generated AppBar BackButton, which is not guaranteed
    // for all embedded routes and is not the browser Back gesture.
    await tester.binding.handlePopRoute();
    await settlePop(tester);
    expect(find.byType(MoreScreen), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('main-nav-memories')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(DiaryMemoriesScreen), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('main-nav-today')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(PlannerScreen), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('main-nav-create')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.byType(BottomSheet), findsOneWidget);
    // Use browser/system Back to validate the route stack. pageBack() only
    // presses an auto-generated AppBar BackButton, which is not guaranteed
    // for all embedded routes and is not the browser Back gesture.
    await tester.binding.handlePopRoute();
    await settlePop(tester);
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.byType(MainShell), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    store.dispose();
  });

  testWidgets('S7 Classic Today opens one canonical Calendar and returns',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    AnnaEditorialTodayMode.enabled.value = false;
    final store = AgendaStore();
    store.preferences = const AgendaPreferences(
      onboardingDone: true, appLanguage: AppLanguage.italian,
    );
    await tester.pumpWidget(
      AgendaApp(store: store, bypassIdentityForTesting: true),
    );
    await tester.pump(const Duration(milliseconds: 400));

    final calendar = find.byKey(const ValueKey('today-open-calendar'));
    expect(calendar, findsOneWidget);
    await tester.tap(calendar);
    await settlePush(tester);
    expect(find.byType(CalendarHubScreen), findsOneWidget);
    // Use browser/system Back to validate the route stack. pageBack() only
    // presses an auto-generated AppBar BackButton, which is not guaranteed
    // for all embedded routes and is not the browser Back gesture.
    await tester.binding.handlePopRoute();
    await settlePop(tester);
    expect(find.byType(CalendarHubScreen), findsNothing);
    expect(find.byType(MainShell), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    store.dispose();
  });

  testWidgets('S7 wide layout keeps original rail routes and Create owner',
      (tester) async {
    tester.view.physicalSize = const Size(900, 1050);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final store = AgendaStore();
    store.preferences = const AgendaPreferences(
      onboardingDone: true, appLanguage: AppLanguage.french,
    );
    await tester.pumpWidget(
      AgendaApp(store: store, bypassIdentityForTesting: true),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey('main-navigation-rail')), findsOneWidget);
    expect(find.byKey(const ValueKey('main-editorial-dock')), findsNothing);
    expect(find.byKey(const ValueKey('main-rail-more')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('main-rail-more')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(MoreScreen), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    store.dispose();
  });

  test('S7 nav/capture focus release is owned only by the existing shell',
      () {
    final shell = File('lib/src/screens/home_inbox_search.dart')
        .readAsStringSync();
    final more = File('lib/src/screens/more_screen.dart').readAsStringSync();
    final capture = File('lib/src/unified_capture.dart').readAsStringSync();
    expect(shell, contains('FocusScope.of(context).unfocus();'));
    expect(shell, contains('void _selectDestination(int value)'));
    expect(shell, contains('if (value == index) return;'));
    expect(shell, contains('IndexedStack(index: index, children: pages)'));
    expect(shell, contains('await showUnifiedCapture('));
    expect(more, contains('PersonalSearchConnectionsScreen(store: store)'));
    expect(more, contains('SettingsHubScreen(store: store)'));
    expect(capture, contains('Future<void> showUnifiedCapture('));
    expect(shell, isNot(contains('Navigator.pushNamedAndRemoveUntil(')));
  });
}
