import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agenda_per_anna/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('personalized onboarding keeps My Life recommended by default',
      (tester) async {
    await initializeDateFormatting('it_IT', null);
    final store = AgendaStore();
    store.preferences = const AgendaPreferences(
      onboardingDone: false,
      appLanguage: AppLanguage.italian,
    );

    await tester.pumpWidget(
      AgendaApp(store: store, bypassIdentityForTesting: true),
    );
    await tester.pumpAndSettle();

    expect(find.text('La tua agenda, davvero tua.'), findsOneWidget);
    expect(find.text('Continua'), findsOneWidget);

    await tester.tap(find.text('Continua'));
    await tester.pumpAndSettle();

    expect(find.text('Come vuoi usare Anna’s Diary?'), findsOneWidget);
    expect(find.text('La mia vita'), findsOneWidget);
    expect(find.text('Consigliato'), findsOneWidget);
    expect(
      store.preferences.personalizationPreset,
      PersonalizationPreset.complete,
    );
  });

  testWidgets('Essential preset is persisted without deleting app data',
      (tester) async {
    await initializeDateFormatting('it_IT', null);
    final store = AgendaStore();
    store.shoppingItems.add(
      ShoppingItem(
        id: 'keep-shopping',
        name: 'Latte',
        createdAt: DateTime(2026, 10, 14),
      ),
    );
    store.preferences = const AgendaPreferences(
      onboardingDone: false,
      appLanguage: AppLanguage.italian,
    );

    await tester.pumpWidget(
      AgendaApp(store: store, bypassIdentityForTesting: true),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continua'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Essenziale'));
    await tester.pump();
    await tester.tap(find.text('Inizia'));
    await tester.pumpAndSettle();

    expect(store.preferences.onboardingDone, isTrue);
    expect(
      store.preferences.personalizationPreset,
      PersonalizationPreset.essential,
    );
    expect(store.preferences.enabledModules, isEmpty);
    expect(store.shoppingItems.single.id, 'keep-shopping');
    expect(find.text('La mia giornata'), findsWidgets);
  });
}
