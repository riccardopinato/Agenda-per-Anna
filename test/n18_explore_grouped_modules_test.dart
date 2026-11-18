import 'dart:io';

import 'package:agenda_per_anna/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() => AnnaEditorialTodayMode.enabled.value = false);

  test('enabled-module status is localized in all five supported languages', () {
    expect(annaExploreEnabledSummary('it', 2), '2 moduli attivi');
    expect(annaExploreEnabledSummary('en', 2), '2 active modules');
    expect(annaExploreEnabledSummary('es', 2), '2 módulos activos');
    expect(annaExploreEnabledSummary('fr', 2), '2 modules actifs');
    expect(annaExploreEnabledSummary('pt', 2), '2 módulos ativos');
  });

  testWidgets('Journal groups real enabled modules; disabled never appear',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final store = AgendaStore();
    addTearDown(store.dispose);
    store.preferences = const AgendaPreferences(
      enabledModules: {AppModule.shopping, AppModule.people},
    );
    AnnaEditorialTodayMode.enabled.value = true;
    await tester.pumpWidget(MaterialApp(
      home: ExploreScreen(store: store),
    ));
    await tester.pump();
    expect(find.byKey(const ValueKey<String>(
      'explore-journal-modules-group',
    )), findsOneWidget);
    expect(find.text('2 active modules'), findsOneWidget);
    expect(find.byType(AnnaOrganicJournalRow), findsNWidgets(3));
    expect(find.byType(AnnaOrganicJournalRule), findsOneWidget);
    expect(find.byKey(const ValueKey<String>(
      'explore-journal-personalization-entry',
    )), findsOneWidget);
    expect(tester.takeException(), isNull);

    AnnaEditorialTodayMode.enabled.value = false;
    await tester.pump();
    expect(find.byKey(const ValueKey<String>(
      'explore-journal-modules-group',
    )), findsNothing);
    expect(find.byType(NavigationCard), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  test('N18-07 is only presentation; route guards and Classic survive', () {
    final src = File('lib/src/screens/explore_screen.dart').readAsStringSync();
    expect(src, contains('if (!prefs.isModuleEnabled(module)) return;'));
    expect(src, contains('if (!organic && modules.isNotEmpty)'));
    expect(src, contains('NavigationCard('));
    expect(src, contains('AnnaOrganicJournalRow('));
    expect(src, contains('AnnaOrganicPaperSurface('));
    expect(src, contains('AnnaOrganicJournalRule()'));
    expect(src, contains('ShoppingListScreen(store: store)'));
    expect(src, contains('WorkoutScreen(store: store)'));
    expect(src, contains('SharedSpaceHubScreen(store: store)'));
    expect(src, contains('PrivateVaultScreen(store: store)'));
    expect(src, contains('PersonalizationScreen(store: store)'));
    expect(src, isNot(contains('store.savePreferences(')));
    expect(src, isNot(contains('SharedPreferences.getInstance(')));
  });
}
