import 'dart:io';

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

  Future<AgendaStore> pumpHome(
    WidgetTester tester, {
    required PersonalizationPreset preset,
    required Set<AppModule> modules,
  }) async {
    await initializeDateFormatting('it_IT', null);
    final store = AgendaStore();
    store.preferences = AgendaPreferences(
      onboardingDone: true,
      appLanguage: AppLanguage.italian,
      startTab: StartTab.home,
      personalizationPreset: preset,
      enabledModules: modules,
    );

    await tester.pumpWidget(
      AgendaApp(store: store, bypassIdentityForTesting: true),
    );
    await tester.pumpAndSettle();
    return store;
  }

  testWidgets('Essential Home hides optional chrome and healthy local sync',
      (tester) async {
    await pumpHome(
      tester,
      preset: PersonalizationPreset.essential,
      modules: const {},
    );

    expect(
      find.byKey(const ValueKey<String>('home-more-menu')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('home-vault-card')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('home-wellbeing-card')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('home-sync-attention')),
      findsNothing,
    );
    expect(find.text('Personalizza'), findsOneWidget);
  });

  testWidgets('Complete Home keeps Vault and wellbeing available',
      (tester) async {
    await pumpHome(
      tester,
      preset: PersonalizationPreset.complete,
      modules: completeAppModules,
    );

    expect(
      find.byKey(const ValueKey<String>('home-vault-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('home-wellbeing-card')),
      findsOneWidget,
    );
  });

  testWidgets('Home More keeps secondary operational destinations reachable',
      (tester) async {
    await pumpHome(
      tester,
      preset: PersonalizationPreset.complete,
      modules: completeAppModules,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('home-more-menu')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Esplora'), findsOneWidget);
    expect(find.text('Personalizza'), findsOneWidget);
    expect(find.text('Archivio'), findsOneWidget);
    expect(find.text('Backup'), findsOneWidget);
    expect(find.text('Cloud'), findsOneWidget);
    expect(find.text('Impostazioni'), findsOneWidget);
    expect(find.text('Noi ♡'), findsOneWidget);
  });

  test('D journey routes secondary Home destinations through stable More id',
      () {
    final smoke =
        File('.maestro/applab-smoke.yaml').readAsStringSync();
    final d6 =
        File('.maestro/journey/d6-functional-navigation.yaml').readAsStringSync();
    final archive =
        File('.maestro/journey/archive.yaml').readAsStringSync();
    final backup =
        File('.maestro/journey/backup.yaml').readAsStringSync();

    for (final flow in [smoke, d6, archive, backup]) {
      expect(flow, contains('home_more_menu'));
    }
  });
}
