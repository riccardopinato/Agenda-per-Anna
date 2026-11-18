import 'dart:io';

import 'package:agenda_per_anna/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Only real Flutter widget captures with synthetic guest data.
/// These captures cannot certify remote memberships or two-device sync.
const captureTogetherVisuals =
    bool.fromEnvironment('ANNA_TOGETHER_CAPTURE', defaultValue: false);

class _TogetherFixture {
  final String id;
  final int width;
  final int height;
  final AppLanguage language;
  final AgendaPalette palette;
  final AgendaThemeMode theme;
  final bool journal;
  final bool customPalette;

  const _TogetherFixture(
    this.id, this.width, this.height, this.language, this.palette,
    this.theme, this.journal, {this.customPalette = false},
  );
}

void main() {
  const fixtures = <_TogetherFixture>[
    _TogetherFixture('it_320_light_rose', 320, 640,
        AppLanguage.italian, AgendaPalette.rose, AgendaThemeMode.light, true),
    _TogetherFixture('en_390_dark_lilac', 390, 844,
        AppLanguage.english, AgendaPalette.lilac, AgendaThemeMode.dark, true),
    _TogetherFixture('es_600_light_sage', 600, 960,
        AppLanguage.spanish, AgendaPalette.sage, AgendaThemeMode.light, true),
    _TogetherFixture('fr_320_light_peach', 320, 740,
        AppLanguage.french, AgendaPalette.peach, AgendaThemeMode.light, true),
    _TogetherFixture('pt_390_light_sky', 390, 844,
        AppLanguage.portuguese, AgendaPalette.sky, AgendaThemeMode.light, true),
    _TogetherFixture('it_390_custom_hsv', 390, 844,
        AppLanguage.italian, AgendaPalette.rose, AgendaThemeMode.light, true,
        customPalette: true),
    _TogetherFixture('it_390_classic', 390, 844,
        AppLanguage.italian, AgendaPalette.rose, AgendaThemeMode.light, false),
  ];

  for (final fixture in fixtures) {
    testWidgets('Insieme real guest/help visual ${fixture.id}', (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        AnnaEditorialTodayMode.storageKey: fixture.journal,
      });
      await AnnaEditorialTodayMode.ensureLoaded();
      AnnaEditorialTodayMode.enabled.value = fixture.journal;
      addTearDown(() => AnnaEditorialTodayMode.enabled.value = false);

      await (FontLoader('Manrope')
            ..addFont(rootBundle.load('assets/fonts/Manrope-VF.ttf')))
          .load();
      await (FontLoader('Lora')
            ..addFont(rootBundle.load('assets/fonts/Lora-VF.ttf')))
          .load();
      final icons = await tester.runAsync(() async {
        final file = File('test/fixtures/MaterialIcons-Regular.otf');
        return await file.exists() ? file.readAsBytes() : null;
      });
      if (icons != null) {
        await (FontLoader('MaterialIcons')
              ..addFont(Future<ByteData>.value(ByteData.sublistView(icons))))
            .load();
      }

      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      const channel = MethodChannel('annas_diary/external_calendar');
      messenger.setMockMethodCallHandler(channel,
          (call) async => call.method == 'status'
              ? <String, Object>{'granted': false}
              : null);
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

      tester.view.physicalSize =
          Size(fixture.width.toDouble(), fixture.height.toDouble());
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final store = AgendaStore();
      addTearDown(store.dispose);
      store.preferences = AgendaPreferences(
        appLanguage: fixture.language,
        themeMode: fixture.theme,
        palette: fixture.palette,
        useCustomPalette: fixture.customPalette,
        customColorValue: 0xFF9574C3,
        onboardingDone: true,
        displayName: 'Utente QA',
      );
      await tester.pumpWidget(
        AgendaApp(store: store, bypassIdentityForTesting: true),
      );
      await tester.pump(const Duration(milliseconds: 350));
      final navigator =
          Navigator.of(tester.element(find.byType(MainShell)));
      navigator.push(MaterialPageRoute<void>(
        builder: (_) => SharedSpaceHubScreen(store: store),
      ));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 450));

      expect(find.byType(SharedSpaceHubScreen), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('context-help-shared')),
          findsOneWidget);
      expect(tester.takeException(), isNull);
      final guest = find.descendant(
        of: find.byType(SharedSpaceHubScreen),
        matching: find.byType(Scaffold),
      ).first;
      await expectLater(
        guest,
        matchesGoldenFile('goldens/together_guest_${fixture.id}.png'),
      );

      await tester.tap(find.byKey(
          const ValueKey<String>('context-help-shared')));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 450));
      final helpContents = find.byKey(
          const ValueKey<String>('context-help-contents-shared'));
      expect(helpContents, findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.ancestor(of: helpContents, matching: find.byType(Scaffold)).first,
        matchesGoldenFile('goldens/together_help_${fixture.id}.png'),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    },
        skip: !captureTogetherVisuals,
        timeout: const Timeout(Duration(seconds: 140)));
  }
}
