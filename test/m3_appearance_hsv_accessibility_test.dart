import 'package:agenda_per_anna/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// M3 real Flutter widget regression for an approved N18-08 settings journey.
/// Visual quality and physical VoiceOver/TalkBack approval are independent.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets(
    'N18 HSV appearance: 320dp, 200% text, dark mode, stacked actions and draft-only',
    (tester) async {
      tester.view.physicalSize = const Size(320, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final store = AgendaStore();
      addTearDown(store.dispose);
      const before = AgendaPreferences(
        palette: AgendaPalette.rose,
        appLanguage: AppLanguage.italian,
        useCustomPalette: false,
      );
      store.preferences = before;

      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        locale: const Locale('it'),
        supportedLocales: AnnaStrings.supportedLocales,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 780),
            textScaler: TextScaler.linear(2),
          ),
          child: AppearanceColorsScreen(store: store),
        ),
      ));
      await tester.pumpAndSettle();

      final custom = find.byKey(const ValueKey<String>('appearance-custom'));
      expect(custom, findsOneWidget);
      await tester.tap(custom);
      await tester.pump();
      expect(store.preferences.useCustomPalette, isFalse,
          reason: 'Preview selection must never persist until Apply');
      expect(find.byKey(const ValueKey<String>('appearance-hue-slider')),
          findsOneWidget);

      final list = find.byType(Scrollable).first;
      final actions = find.byKey(
          const ValueKey<String>('appearance-actions-stacked'));
      await tester.scrollUntilVisible(actions, 150,
          scrollable: list, maxScrolls: 35);
      expect(actions, findsOneWidget);
      expect(find.byKey(const ValueKey<String>('appearance-apply')),
          findsOneWidget);
      expect(tester.takeException(), isNull,
          reason: 'No render overflow or assertion at 320dp / 200%');

      await tester.scrollUntilVisible(
          find.byKey(const ValueKey<String>('appearance-hex')), -160,
          scrollable: list, maxScrolls: 35);
      await tester.enterText(
          find.byKey(const ValueKey<String>('appearance-hex')), '#12345');
      await tester.pump();
      await tester.scrollUntilVisible(actions, 160,
          scrollable: list, maxScrolls: 35);
      final apply = find.byKey(const ValueKey<String>('appearance-apply'));
      expect(tester.widget<FilledButton>(apply).onPressed, isNull,
          reason: 'Invalid HEX input cannot silently save the previous shade');
      expect(store.preferences.useCustomPalette, isFalse);
      expect(tester.takeException(), isNull);
    },
    timeout: const Timeout(Duration(seconds: 90)),
  );

  test('N18 palette source remains exactly the five approved presets', () {
    expect(AgendaPalette.values.map((p) => p.name).toList(),
        <String>['rose', 'lilac', 'sage', 'peach', 'sky']);
    // Mock-up approval must never introduce a sixth persisted enum/palette.
  });
}
