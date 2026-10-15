import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agenda_per_anna/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const explicitLanguages = <AppLanguage>[
    AppLanguage.english,
    AppLanguage.italian,
    AppLanguage.spanish,
    AppLanguage.french,
    AppLanguage.portuguese,
  ];

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'v1.01 onboarding renders on a narrow viewport in every supported language',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      for (final language in explicitLanguages) {
        SharedPreferences.setMockInitialValues({});
        final store = AgendaStore();
        store.preferences = AgendaPreferences(
          onboardingDone: false,
          appLanguage: language,
        );

        await tester.pumpWidget(
          AgendaApp(store: store, bypassIdentityForTesting: true),
        );
        await tester.pumpAndSettle();

        final strings = AnnaStrings.forPreference(language);
        expect(find.text(strings.d3('onboardingTitle')), findsOneWidget);
        expect(
          find.byKey(const ValueKey('onboarding-preset-life')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('onboarding-continue')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        store.dispose();
      }
    },
  );

  test('v1.01 accessibility contracts stay explicit and stable', () {
    final shell = File('lib/src/app_shell.dart').readAsStringSync();
    final personalization =
        File('lib/src/screens/personalization_screen.dart').readAsStringSync();
    final home =
        File('lib/src/screens/home_inbox_search.dart').readAsStringSync();

    expect(shell, contains('materialTapTargetSize: MaterialTapTargetSize.padded'));
    expect(shell, contains('SingleChildScrollView('));
    expect(shell, contains('BoxConstraints(maxWidth: 560)'));
    expect(shell, contains('WrapCrossAlignment.center'));
    expect(shell, contains('header: true'));
    expect(shell, contains('excludeSemantics: true'));
    expect(shell, contains('label: semanticLabel'));
    expect(shell, contains('onTap: onTap'));

    for (final id in const <String>[
      'personalization_preset_',
      'personalization_module_',
      'personalization_restore_complete',
    ]) {
      expect(personalization, contains(id));
    }
    expect(personalization, contains('toggled: enabled'));
    expect(personalization, contains('excludeSemantics: true'));
    expect(personalization, contains('header: true'));

    expect(home, contains("identifier: 'home_more_menu'"));
    expect(home, contains("label: strings.d3('homeMore')"));
  });

  test('all v1.01 presentation copy has non-empty en/it/es/fr/pt rows', () {
    final localization =
        File('lib/src/localization_d3.dart').readAsStringSync();

    const keys = <String>[
      'onboardingTitle',
      'onboardingPresetIntro',
      'onboardingPresetEssentialTitle',
      'onboardingPresetEssentialSubtitle',
      'onboardingPresetLifeTitle',
      'onboardingPresetLifeSubtitle',
      'onboardingPresetCompleteTitle',
      'onboardingPresetCompleteSubtitle',
      'onboardingRecommended',
      'onboardingChangeLater',
      'onboardingContinue',
      'onboardingFirstActionTitle',
      'onboardingFirstActionSubtitle',
      'onboardingCaptureFirst',
      'onboardingCaptureFirstSubtitle',
      'onboardingOpenAgenda',
      'onboardingOpenAgendaSubtitle',
      'personalizationTitle',
      'personalizationIntro',
      'personalizationSettingsSubtitle',
      'personalizationPresetTitle',
      'personalizationCurrentPreset',
      'personalizationCustomTitle',
      'personalizationCustomActive',
      'personalizationHiddenDataSafe',
      'personalizationModulesTitle',
      'personalizationModulesHint',
      'personalizationHabits',
      'personalizationCycleDependency',
      'personalizationVaultDependency',
      'personalizationRestoreComplete',
      'personalizationExploreEmpty',
      'homeMore',
      'homeExploreAreasCount',
    ];

    final rows = localization.split('\n');
    for (final key in keys) {
      final row = rows.firstWhere(
        (line) => line.contains('"$key": <String, String>'),
        orElse: () => '',
      );
      expect(row, isNotEmpty, reason: 'missing v1.01 localization row $key');
      for (final locale in const <String>['en', 'it', 'es', 'fr', 'pt']) {
        expect(
          RegExp('"$locale":\\s*"[^"]+"').hasMatch(row),
          isTrue,
          reason: '$key missing or empty for $locale',
        );
      }
    }
  });

  test('v1.01-E trusted journey exercises reversible personalization', () {
    final journey =
        File('.maestro/applab-journey.json').readAsStringSync();
    final flow =
        File('.maestro/journey/personalization.yaml').readAsStringSync();

    expect(journey, contains('"name": "personalization"'));
    expect(
      journey,
      contains('.maestro/journey/personalization.yaml'),
    );
    expect(flow, contains('home_more_menu'));
    expect(flow, contains('personalization_preset_essential'));
    expect(flow, contains('personalization_module_shopping'));
    expect(flow, contains('personalization_restore_complete'));
    expect(flow, contains('personalization_module_ecosystem'));
    expect(flow, contains('Personalizza|Personalize|Personalizar|Personnaliser'));
  });

  test('v1.01-E stays presentation-only and preserves canonical ownership', () {
    final personalization =
        File('lib/src/screens/personalization_screen.dart').readAsStringSync();
    final shell = File('lib/src/app_shell.dart').readAsStringSync();

    for (final forbidden in const <String>[
      'SharedPreferences',
      'LocalStateStore',
      'MediaAssetStore',
      'deleteModule',
      'removeWhere((module)',
    ]) {
      expect(personalization, isNot(contains(forbidden)));
    }

    expect(personalization, contains('store.applyPersonalizationPreset'));
    expect(personalization, contains('store.setModuleEnabled'));
    expect(shell, contains('applyPersonalizationPreset(selectedPreset)'));
    expect(shell, contains('store.preferences.copyWith(onboardingDone: true)'));
  });
}
