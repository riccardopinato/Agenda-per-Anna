import 'dart:io';

import 'package:agenda_per_anna/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Step 2 of the Web-first DS6 audit. These are REAL Flutter widget layouts
/// with a fresh, empty, synthetic guest store—not screenshots of user records.
////
//// Passing here does not imply browser/PWA visual approval, physical Android
//// validation, Web Push receipt, Web biometric security or two-account sync.
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

  testWidgets('DS6 real shell fits mobile/PWA-like and wide layouts',
      (tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    for (final variant in <({Size size, double scale})>[
      (size: const Size(320, 640), scale: 1),
      (size: const Size(360, 780), scale: 1.6),
      (size: const Size(390, 844), scale: 1),
      (size: const Size(800, 1100), scale: 1),
      (size: const Size(900, 1100), scale: 1),
    ]) {
      tester.view.physicalSize = variant.size;
      tester.view.devicePixelRatio = 1;

      final store = AgendaStore();
      store.preferences = const AgendaPreferences(
        onboardingDone: true,
        appLanguage: AppLanguage.italian,
      );

      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(
            size: variant.size,
            textScaler: TextScaler.linear(variant.scale),
          ),
          child: AgendaApp(
            store: store,
            bypassIdentityForTesting: true,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(MainShell), findsOneWidget,
          reason: 'shell on ${variant.size}');
      expect(find.byKey(const ValueKey<String>('main-shell-content')),
          findsOneWidget, reason: 'content on ${variant.size}');

      if (variant.size.width >= AnnaDesignTokens.wideBreakpoint) {
        expect(find.byKey(const ValueKey<String>('main-navigation-rail')),
            findsOneWidget, reason: 'wide navigation on ${variant.size}');
        expect(find.byKey(const ValueKey<String>('main-editorial-dock')),
            findsNothing);
      } else {
        expect(find.byKey(const ValueKey<String>('main-editorial-dock')),
            findsOneWidget, reason: 'attached dock on ${variant.size}');
        expect(find.byKey(const ValueKey<String>('main-nav-create')),
            findsOneWidget);
      }

      expect(tester.takeException(), isNull,
          reason: 'unexpected Flutter layout/runtime error at '
              '${variant.size} with text scale ${variant.scale}');

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      store.dispose();
    }
  });

  testWidgets('DS6 More shows real guest quick actions on a mobile viewport',
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

    await tester.tap(find.byKey(const ValueKey<String>('main-nav-more')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(MoreScreen), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('ds6-more-profile')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('more-search')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('more-inbox')),
        findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    store.dispose();
  });

  test('More entry points retain the canonical source-screen routes', () {
    // Source contract only. Real browser tap/navigation will be verified on
    // installed PWAs; no claim of end-to-end pass is made here.
    final source = File('lib/src/screens/more_screen.dart')
        .readAsStringSync();
    for (final id in [
      'more-search', 'more-inbox', 'more-private-vault', 'more-settings'
    ]) {
      expect(source, contains("id: '$id'"));
    }
    expect(source, contains('PersonalSearchConnectionsScreen(store: store)'));
    expect(source, contains('InboxScreen(store: store)'));
    expect(source, contains('SettingsHubScreen(store: store)'));
    expect(source, contains('PrivateVaultScreen(store: store)'));
  });
}
