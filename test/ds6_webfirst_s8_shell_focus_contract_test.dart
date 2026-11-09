import 'package:agenda_per_anna/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// S8: real shell widget regressions using an empty synthetic guest store.
/// Focus and route tests are not evidence of installed-PWA or real keyboard QA.
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

  testWidgets('S8 tab switch and central Create release shell focus',
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

    // A synthetic focused node inside the shell's real FocusScope lets this
    // verify the tab-change contract without editing or reading user content.
    final focusNode = FocusNode(debugLabel: 'S8 synthetic focus');
    addTearDown(focusNode.dispose);
    FocusScope.of(tester.element(find.byType(MainShell)))
        .requestFocus(focusNode);
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    await tester.tap(find.byKey(const ValueKey('main-nav-messages')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(focusNode.hasFocus, isFalse);
    expect(find.byType(MainShell), findsOneWidget);

    FocusScope.of(tester.element(find.byType(MainShell)))
        .requestFocus(focusNode);
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    await tester.tap(find.byKey(const ValueKey('main-nav-create')));
    await tester.pump();
    expect(focusNode.hasFocus, isFalse);
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.byType(BottomSheet), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.byType(MainShell), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    store.dispose();
  });

  testWidgets('S8 compact dock keeps one shell through four destinations',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
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

    const destinations = <String>[
      'main-nav-more',
      'main-nav-memories',
      'main-nav-messages',
      'main-nav-today',
    ];
    for (final id in destinations) {
      await tester.tap(find.byKey(ValueKey<String>(id)));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(MainShell), findsOneWidget);
      expect(find.byKey(const ValueKey('main-editorial-dock')),
          findsOneWidget);
      expect(tester.takeException(), isNull);
    }

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    store.dispose();
  });
}
