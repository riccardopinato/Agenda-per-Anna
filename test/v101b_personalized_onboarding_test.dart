import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agenda_per_anna/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'fresh onboarding applies the selected preset only when it completes',
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

      expect(find.byKey(const ValueKey('onboarding-preset-life')), findsOneWidget);
      expect(find.text('Consigliata'), findsOneWidget);
      expect(store.preferences.personalizationPreset, PersonalizationPreset.complete);

      await tester.tap(
        find.byKey(const ValueKey('onboarding-preset-essential')),
      );
      await tester.pump();
      final continueButton =
          find.byKey(const ValueKey('onboarding-continue'));
      await tester.ensureVisible(continueButton);
      await tester.pumpAndSettle();
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('onboarding-first-action-step')),
        findsOneWidget,
      );
      expect(store.preferences.onboardingDone, isFalse);
      expect(store.preferences.personalizationPreset, PersonalizationPreset.complete);

      final openAgendaButton =
          find.byKey(const ValueKey('onboarding-open-agenda'));
      await tester.ensureVisible(openAgendaButton);
      await tester.pumpAndSettle();
      await tester.tap(openAgendaButton);
      await tester.pumpAndSettle();

      expect(store.preferences.onboardingDone, isTrue);
      expect(
        store.preferences.personalizationPreset,
        PersonalizationPreset.essential,
      );
      expect(store.preferences.enabledModules, isEmpty);
      expect(store.shoppingItems.single.id, 'keep-shopping');
      expect(find.text('La mia giornata'), findsWidgets);

      store.dispose();
    },
  );

  testWidgets('existing profiles never re-enter personalized onboarding',
      (tester) async {
    await initializeDateFormatting('it_IT', null);
    final store = AgendaStore();
    store.preferences = const AgendaPreferences(
      onboardingDone: true,
      appLanguage: AppLanguage.italian,
    );

    await tester.pumpWidget(
      AgendaApp(store: store, bypassIdentityForTesting: true),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('onboarding-preset-life')), findsNothing);
    expect(find.text('La mia giornata'), findsWidgets);

    store.dispose();
  });

  test('first useful action reuses canonical Unified Capture and stable semantics',
      () {
    final shell = File('lib/src/app_shell.dart').readAsStringSync();
    final flow = File('.maestro/applab-smoke.yaml').readAsStringSync();

    expect(shell, contains('await showUnifiedCapture('));
    expect(shell, contains('UnifiedCaptureEntryPoint.home'));
    expect(shell, contains("identifier: 'onboarding_first_capture'"));
    expect(shell, contains("identifier: 'onboarding_open_agenda'"));
    expect(shell, contains('store.preferences.copyWith(onboardingDone: true)'));
    expect(flow, contains("id: 'onboarding_preset_complete'"));
    expect(flow, contains("id: 'onboarding_continue'"));
    expect(flow, contains("id: 'onboarding_open_agenda'"));
  });

  test('all v1.01-B user-facing copy stays in the canonical five-language catalog',
      () {
    final localization =
        File('lib/src/localization_d3.dart').readAsStringSync();
    const keys = <String>[
      'onboardingPresetIntro',
      'onboardingPresetEssentialTitle',
      'onboardingPresetLifeTitle',
      'onboardingPresetCompleteTitle',
      'onboardingChangeLater',
      'onboardingFirstActionTitle',
      'onboardingCaptureFirst',
      'onboardingOpenAgenda',
    ];

    for (final key in keys) {
      final start = localization.indexOf('"$key": <String, String>');
      expect(start, greaterThanOrEqualTo(0), reason: 'missing $key');
      final end = localization.indexOf('},', start);
      final entry = localization.substring(start, end);
      for (final locale in const ['"en"', '"it"', '"es"', '"fr"', '"pt"']) {
        expect(entry, contains(locale), reason: '$key missing $locale');
      }
    }
  });
}
