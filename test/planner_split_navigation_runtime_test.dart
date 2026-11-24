import 'package:agenda_per_anna/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pure widget-level navigation on synthetic local state.
/// This is NOT an Android emulator, installed APK or physical-device test.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('planner split retains calendar/week/month/year routes',
      (tester) async {
    await initializeDateFormatting('it_IT', null);
    // The Flutter test renderer defaults to Ahem, which measures text
    // differently and can create synthetic Row overflows. Load the same
    // bundled fonts as the certified 19-image visual-parity fixture.
    await (FontLoader('Manrope')
          ..addFont(rootBundle.load('assets/fonts/Manrope-VF.ttf')))
        .load();
    await (FontLoader('Lora')
          ..addFont(rootBundle.load('assets/fonts/Lora-VF.ttf')))
        .load();

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const calendarChannel = MethodChannel('annas_diary/external_calendar');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      calendarChannel,
      (call) async => call.method == 'status'
          ? <String, Object>{'granted': false}
          : null,
    );
    addTearDown(() => messenger.setMockMethodCallHandler(calendarChannel, null));

    SharedPreferences.setMockInitialValues(<String, Object>{
      AnnaEditorialTodayMode.storageKey: true,
    });
    await AnnaEditorialTodayMode.ensureLoaded();
    AnnaEditorialTodayMode.enabled.value = true;
    addTearDown(() => AnnaEditorialTodayMode.enabled.value = false);

    final store = AgendaStore();
    addTearDown(store.dispose);
    store.preferences = const AgendaPreferences(
      appLanguage: AppLanguage.italian,
      onboardingDone: true,
      displayName: 'Synthetic QA',
      palette: AgendaPalette.rose,
    );

    await tester.pumpWidget(
      AgendaApp(store: store, bypassIdentityForTesting: true),
    );
    await tester.pump(const Duration(milliseconds: 350));

    // Use the application's real Navigator, not a reconstructed test router.
    final navigator = Navigator.of(tester.element(find.byType(MainShell)));
    final routes = <(Widget, Type)>[
      (CalendarHubScreen(store: store), CalendarHubScreen),
      (CalendarScreen(store: store), CalendarScreen),
      (WeekScreen(store: store), WeekScreen),
      (MonthScreen(store: store, initialMonth: DateTime(2026, 11)), MonthScreen),
      (YearScreen(store: store, initialYear: 2026), YearScreen),
    ];

    for (final (page, pageType) in routes) {
      navigator.push(MaterialPageRoute<void>(builder: (_) => page));
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pump(const Duration(milliseconds: 450));
      expect(find.byType(pageType), findsOneWidget);
      if (pageType == YearScreen) {
        expect(find.byKey(const ValueKey<String>('year-review-surface')),
            findsOneWidget);
      }
      expect(tester.takeException(), isNull,
          reason: 'Route $pageType must render without Flutter exceptions.');
      navigator.pop();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
    }
  });
}
