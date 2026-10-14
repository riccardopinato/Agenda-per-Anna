import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agenda_per_anna/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<AgendaStore> pumpApp(
    WidgetTester tester, {
    AgendaPreferences preferences = const AgendaPreferences(
      appLanguage: AppLanguage.italian,
    ),
  }) async {
    await initializeDateFormatting('it_IT', null);
    final store = AgendaStore();
    store.preferences = preferences;
    await tester.pumpWidget(
      AgendaApp(store: store, bypassIdentityForTesting: true),
    );
    await tester.pumpAndSettle();
    return store;
  }

  testWidgets('Explore only renders enabled optional modules', (tester) async {
    final store = await pumpApp(
      tester,
      preferences: const AgendaPreferences(
        appLanguage: AppLanguage.italian,
        personalizationPreset: PersonalizationPreset.custom,
        enabledModules: {AppModule.memories},
      ),
    );

    appNavigatorKey.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => ExploreScreen(store: store),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('I miei ricordi'), findsOneWidget);
    expect(find.text('Lista della spesa'), findsNothing);
    expect(find.text('Allenamento'), findsNothing);
    expect(find.text('Persone importanti'), findsNothing);
  });

  testWidgets('Essential Explore has a safe personalization empty state',
      (tester) async {
    final store = await pumpApp(
      tester,
      preferences: const AgendaPreferences(
        appLanguage: AppLanguage.italian,
        personalizationPreset: PersonalizationPreset.essential,
        enabledModules: {},
      ),
    );

    appNavigatorKey.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => ExploreScreen(store: store),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Il tuo spazio Esplora è minimale'), findsOneWidget);
    expect(find.text('Personalizza'), findsOneWidget);
  });

  testWidgets('module toggle hides presentation but preserves domain data',
      (tester) async {
    final store = await pumpApp(tester);
    store.shoppingItems.add(
      ShoppingItem(
        id: 'shopping-kept',
        name: 'Pane',
        createdAt: DateTime(2026, 10, 14),
      ),
    );

    appNavigatorKey.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => PersonalizationScreen(store: store),
      ),
    );
    await tester.pumpAndSettle();

    final shoppingToggle =
        find.byKey(const ValueKey<String>('module-toggle-shopping'));
    expect(shoppingToggle, findsOneWidget);

    await tester.tap(shoppingToggle);
    await tester.pumpAndSettle();

    expect(store.preferences.isModuleEnabled(AppModule.shopping), isFalse);
    expect(store.preferences.personalizationPreset, PersonalizationPreset.custom);
    expect(store.shoppingItems.single.id, 'shopping-kept');

    await tester.tap(shoppingToggle);
    await tester.pumpAndSettle();

    expect(store.preferences.isModuleEnabled(AppModule.shopping), isTrue);
    expect(store.shoppingItems.single.id, 'shopping-kept');
  });

  testWidgets('Complete preset restores all optional destinations',
      (tester) async {
    final store = await pumpApp(
      tester,
      preferences: const AgendaPreferences(
        appLanguage: AppLanguage.italian,
        personalizationPreset: PersonalizationPreset.essential,
        enabledModules: {},
      ),
    );

    appNavigatorKey.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => PersonalizationScreen(store: store),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(
        const ValueKey<String>('personalization-preset-complete'),
      ),
    );
    await tester.pumpAndSettle();

    expect(store.preferences.personalizationPreset, PersonalizationPreset.complete);
    expect(store.preferences.enabledModules, completeAppModules);
  });
}
