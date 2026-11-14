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
  }, skip: !organicCaptureEnabled);
}
