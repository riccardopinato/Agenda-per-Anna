import 'dart:io';

import 'package:agenda_per_anna/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Draft-PR visual parity only: the QA workflow copies this fixture into the
// unmodified baseline checkout. It uses an isolated, synthetic in-memory store.
const _captureYear = bool.fromEnvironment(
  'ANNA_PLANNER_EXPERIMENT_YEAR_CAPTURE',
  defaultValue: false,
);

void main() {
  testWidgets('Year review screenshot parity, 390dp, empty synthetic year',
      (tester) async {
    await initializeDateFormatting('it_IT', null);
    await (FontLoader('Manrope')
          ..addFont(rootBundle.load('assets/fonts/Manrope-VF.ttf')))
        .load();
    await (FontLoader('Lora')
          ..addFont(rootBundle.load('assets/fonts/Lora-VF.ttf')))
        .load();

    final iconBytes = await tester.runAsync(() async {
      final iconFont = File('test/fixtures/MaterialIcons-Regular.otf');
      return await iconFont.exists() ? iconFont.readAsBytes() : null;
    });
    if (iconBytes != null) {
      await (FontLoader('MaterialIcons')
            ..addFont(Future<ByteData>.value(ByteData.sublistView(iconBytes))))
          .load();
    }

    SharedPreferences.setMockInitialValues(<String, Object>{
      AnnaEditorialTodayMode.storageKey: true,
    });
    await AnnaEditorialTodayMode.ensureLoaded();
    AnnaEditorialTodayMode.enabled.value = true;
    addTearDown(() => AnnaEditorialTodayMode.enabled.value = false);

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

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final store = AgendaStore();
    addTearDown(store.dispose);
    store.preferences = const AgendaPreferences(
      appLanguage: AppLanguage.italian,
      onboardingDone: true,
      displayName: 'Giulia',
      palette: AgendaPalette.rose,
    );

    await tester.pumpWidget(
      AgendaApp(store: store, bypassIdentityForTesting: true),
    );
    await tester.pump(const Duration(milliseconds: 350));

    Navigator.of(tester.element(find.byType(Scaffold).first)).push(
      MaterialPageRoute<void>(
        builder: (_) => YearScreen(store: store, initialYear: 2026),
      ),
    );
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.byKey(const ValueKey<String>('year-review-surface')),
        findsOneWidget);
    await expectLater(
      find.descendant(
        of: find.byType(YearScreen),
        matching: find.byType(Scaffold),
      ).first,
      matchesGoldenFile('goldens/anna_planner_split_year_empty_390.png'),
    );
    expect(tester.takeException(), isNull);
  }, skip: !_captureYear);
}
