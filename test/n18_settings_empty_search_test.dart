import 'dart:io';

import 'package:agenda_per_anna/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    AnnaEditorialTodayMode.enabled.value = true;
  });
  tearDown(() => AnnaEditorialTodayMode.enabled.value = false);

  testWidgets('Journal Settings empty search is actionable at 320dp and 200% text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final store = AgendaStore();
    addTearDown(store.dispose);
    store.preferences = const AgendaPreferences(
      onboardingDone: true,
      appLanguage: AppLanguage.italian,
    );
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('it'),
      supportedLocales: AnnaStrings.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 760),
          textScaler: TextScaler.linear(2),
        ),
        child: SettingsHubScreen(store: store),
      ),
    ));
    await tester.pump();
    final search = find.byKey(const ValueKey<String>('qw2-settings-search'));
    await tester.scrollUntilVisible(
      search, 160,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 18,
    );
    await tester.enterText(search, 'zz_no_settings_match_467');
    await tester.pump();

    final empty = find.byKey(const ValueKey<String>(
      'settings-journal-empty-search',
    ));
    await tester.scrollUntilVisible(
      empty, 120,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 12,
    );
    expect(empty, findsOneWidget);
    final clear = find.byKey(const ValueKey<String>(
      'settings-journal-clear-empty-search',
    ));
    expect(clear, findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(clear);
    await tester.tap(clear);
    await tester.pump();
    expect(empty, findsNothing);
    expect(tester.widget<TextField>(search).controller!.text, isEmpty);
    expect(tester.takeException(), isNull);
  });

  test('Classic retains plain no-result presentation and canonical owners', () {
    final settings = File('lib/src/screens/settings_hub.dart')
        .readAsStringSync();
    expect(settings, contains('AnnaOrganicPastel.enabled(context)'));
    expect(settings, contains("'settings-journal-empty-search'"));
    expect(settings, contains("'settings-journal-clear-empty-search'"));
    expect(settings, contains("quickWins2Copy("));
    expect(settings, contains("'settingsNoMatch'"));
    expect(settings, contains('FocusScope.of(context).unfocus()'));
    expect(settings, contains("_search.clear();"));
    expect(settings, contains("_query = '';"));
    expect(settings, contains(': Padding('));
    for (final id in [
      'settings-hub-appearance',
      'settings-hub-personalization',
      'settings-hub-preferences-privacy',
      'settings-hub-account',
      'settings-hub-backup',
    ]) {
      expect(settings, contains("id: '$id'"));
    }
    expect(settings, isNot(contains('store.savePreferences(')));
  });
}
