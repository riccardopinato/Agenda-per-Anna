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

  testWidgets('DS6 More routes are accessible from a narrow Web-like shell',
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
    expect(find.byKey(const ValueKey<String>('ds6-more-profile')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('more-search')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('more-inbox')),
        findsOneWidget);
    // More uses a lazily laid-out ListView. Settings and Vault can be
    // below the fold; assert those destinations *after* scrolling to them.
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(
        find.byKey(const ValueKey<String>('more-search')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<String>('more-search')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(PersonalSearchConnectionsScreen), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pageBack();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.ensureVisible(
        find.byKey(const ValueKey<String>('more-inbox')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<String>('more-inbox')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(InboxScreen), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('ds6-inbox-search')),
        findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pageBack();
    await tester.pump(const Duration(milliseconds: 500));
    final moreScrollable = find.descendant(
      of: find.byType(MoreScreen),
      matching: find.byType(Scrollable),
    ).first;

    // Cassaforte stays reachable, but no Vault screen or private content is
    // opened or captured for Web-first UI verification.
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey<String>('more-private-vault')),
      220,
      scrollable: moreScrollable,
      maxScrolls: 16,
    );
    expect(find.byKey(const ValueKey<String>('more-private-vault')),
        findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey<String>('more-settings')),
      220,
      scrollable: moreScrollable,
      maxScrolls: 16,
    );
    expect(find.byKey(const ValueKey<String>('more-settings')),
        findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('more-settings')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(SettingsHubScreen), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('settings-hub-personalization')),
        findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    store.dispose();
  });
}
