import 'dart:io';

import 'package:agenda_per_anna/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// S6: mounts real, existing Settings, Search and Appearance screen widgets
/// with synthetic empty stores. CI widgets != physical PWA/browser acceptance.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AnnaEditorialTodayMode.enabled.value = true;
  });

  tearDown(() => AnnaEditorialTodayMode.enabled.value = false);

  Widget app(Widget screen, {String locale = 'it', double textScale = 2}) =>
      MaterialApp(
        locale: Locale(locale),
        supportedLocales: const [
          Locale('it'), Locale('en'), Locale('es'), Locale('fr'), Locale('pt'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(useMaterial3: true),
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(320, 760),
            textScaler: TextScaler.linear(textScale),
          ),
          child: screen,
        ),
      );

  void compactPwa(WidgetTester tester) {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  testWidgets('real Settings: search submit dismisses focus and tile opens',
      (tester) async {
    compactPwa(tester);
    final store = AgendaStore();
    store.preferences = const AgendaPreferences(
      onboardingDone: true,
      appLanguage: AppLanguage.italian,
    );
    await tester.pumpWidget(app(SettingsHubScreen(store: store)));
    await tester.pump();

    final search = find.byKey(const ValueKey('qw2-settings-search'));
    // At 320dp / 2x the approved editorial header and preview occupy the
    // initial viewport. Reach the real search by scrolling before asserting.
    await tester.scrollUntilVisible(
      search,
      180,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 15,
    );
    expect(search, findsOneWidget);
    await tester.enterText(search, 'palette');
    await tester.pump();
    final appearance = find.byKey(
      const ValueKey('settings-hub-appearance'),
    );
    await tester.scrollUntilVisible(
      appearance,
      120,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 12,
    );
    expect(appearance, findsOneWidget);

    final editable = tester.widget<EditableText>(
      find.descendant(of: search, matching: find.byType(EditableText)),
    );
    expect(editable.focusNode.hasFocus, isTrue);
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    expect(editable.focusNode.hasFocus, isFalse);

    await tester.tap(appearance);
    // Navigator installs the pushed route on the following frame. Giving
    // the duration to the first frame alone can report a false negative.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 850));
    expect(find.byType(AppearanceColorsScreen), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    store.dispose();
  });

  testWidgets('real global Search: five languages fit sort and filter strip',
      (tester) async {
    compactPwa(tester);
    for (final language in const ['it', 'en', 'es', 'fr', 'pt']) {
      final store = AgendaStore();
      store.preferences = const AgendaPreferences(onboardingDone: true);
      await tester.pumpWidget(app(
        PersonalSearchConnectionsScreen(store: store), locale: language,
      ));
      await tester.pump(const Duration(milliseconds: 300));

      final filters = find.byKey(
        const ValueKey<String>('approved-search-filter-strip'),
      );
      final sort = find.byKey(
        const ValueKey<String>('approved-search-sort'),
      );
      expect(filters, findsOneWidget, reason: language);
      expect(tester.getSize(filters).height, greaterThan(60),
          reason: 'chips must grow with 2x text: $language');
      expect(sort, findsOneWidget, reason: language);
      expect(tester.widget<DropdownButton<ApprovedSearchSort>>(sort).isExpanded,
          isTrue);
      expect(tester.takeException(), isNull,
          reason: 'real Search at 320dp/2x: $language');

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      store.dispose();
    }
  });

  testWidgets('real Appearance: Cancel and Apply stack at 320dp/2x',
      (tester) async {
    compactPwa(tester);
    final store = AgendaStore();
    store.preferences = const AgendaPreferences(
      onboardingDone: true,
      appLanguage: AppLanguage.french,
    );
    await tester.pumpWidget(app(
      AppearanceColorsScreen(store: store), locale: 'fr',
    ));
    await tester.pump();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey<String>('appearance-actions-stacked')),
      240,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 30,
    );
    expect(find.byKey(const ValueKey<String>('appearance-actions-stacked')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('appearance-apply')),
        findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    store.dispose();
  });

  test('no search index, preferences writer, QR, Vault or sync rework', () {
    final settings = File('lib/src/screens/settings_hub.dart')
        .readAsStringSync();
    final search = File('lib/src/search_connections_domain.dart')
        .readAsStringSync();
    final appearance = File('lib/src/screens/appearance_colors.dart')
        .readAsStringSync();
    expect(settings, contains('ScrollViewKeyboardDismissBehavior.onDrag'));
    expect(settings, contains('onSubmitted: (_) => FocusScope.of(context).unfocus()'));
    expect(search, contains('widget.store.approvedPersonalSearch('));
    expect(search, contains('approved-search-filter-strip'));
    expect(appearance, contains('widget.store.savePreferences(current.copyWith('));
    expect(appearance, contains('appearance-actions-stacked'));
    expect(appearance, isNot(contains('CloudSyncService')));
  });
}
