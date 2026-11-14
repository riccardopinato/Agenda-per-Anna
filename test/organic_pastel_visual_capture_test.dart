import 'dart:io';
import 'dart:typed_data';

import 'package:agenda_per_anna/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Manual visual-evidence job only. Regular flutter test skips screenshots.
// Contents are empty/synthetic local state: no production account or media.
const organicCaptureEnabled =
    bool.fromEnvironment('ANNA_ORGANIC_CAPTURE', defaultValue: false);

void main() {
  testWidgets('real Organic Pastel Today at 390dp (synthetic offline state)',
      (tester) async {
    await initializeDateFormatting('it_IT', null);
    final manrope = FontLoader('Manrope')
      ..addFont(rootBundle.load('assets/fonts/Manrope-VF.ttf'));
    final lora = FontLoader('Lora')
      ..addFont(rootBundle.load('assets/fonts/Lora-VF.ttf'));
    await Future.wait([manrope.load(), lora.load()]);
    // Widget tests otherwise substitute squares for Material icon glyphs.
    // The CI capture workflow provides Flutter SDK's bundled original font.
    final iconFont = File('test/fixtures/MaterialIcons-Regular.otf');
    if (await iconFont.exists()) {
      final bytes = await iconFont.readAsBytes();
      await (FontLoader('MaterialIcons')
            ..addFont(Future<ByteData>.value(ByteData.sublistView(bytes))))
          .load();
    }
    // Widget tests do not host Android's external-calendar MethodChannel.
    // Mock only the read-only status result; no real account/calendars touched.
    const externalCalendarChannel =
        MethodChannel('annas_diary/external_calendar');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      externalCalendarChannel,
      (call) async => call.method == 'status'
          ? <String, Object>{'granted': false}
          : null,
    );
    addTearDown(() => messenger.setMockMethodCallHandler(
          externalCalendarChannel,
          null,
        ));
    SharedPreferences.setMockInitialValues(<String, Object>{
      AnnaEditorialTodayMode.storageKey: true,
    });
    await AnnaEditorialTodayMode.ensureLoaded();
    AnnaEditorialTodayMode.enabled.value = true;
    addTearDown(() => AnnaEditorialTodayMode.enabled.value = false);

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final store = AgendaStore();
    store.preferences = const AgendaPreferences(
      appLanguage: AppLanguage.italian,
      onboardingDone: true,
      palette: AgendaPalette.sage,
    );
    addTearDown(store.dispose);
    await tester.pumpWidget(
      AgendaApp(store: store, bypassIdentityForTesting: true),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('organic-pastel-landscape')),
      findsWidgets,
    );
    expect(
      find.byKey(const ValueKey<String>('main-nav-create')),
      findsOneWidget,
    );
    await expectLater(
      find.byType(Scaffold).first,
      matchesGoldenFile('goldens/organic_pastel_today_390.png'),
    );
    expect(tester.takeException(), isNull);
    // Staggered Motion and delayed card timers must fully drain before
    // teardown; a pending delay is not evidence of pixel failure.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
  }, skip: !organicCaptureEnabled);
}
