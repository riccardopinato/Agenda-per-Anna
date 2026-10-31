import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AppLab v5.9 catalog uses only supported journey fields', () {
    final project = jsonDecode(File('applab.project.json').readAsStringSync())
        as Map<String, dynamic>;
    final journeys = project['journeys'] as Map<String, dynamic>;
    final catalog = journeys['catalog'] as Map<String, dynamic>;

    expect(catalog.length, 10);
    expect(catalog.keys.first, 'core-shell');
    expect(catalog.keys, containsAll(<String>[
      'onboarding',
      'navigation-critical',
      'memories-critical',
      'settings-critical',
      'personalization-critical',
      'vault-create',
      'vault-wrong-password',
      'vault-correct-unlock',
      'vault-restart-unlock',
    ]));

    const allowed = <String>{
      'flow',
      'paths',
      'labs',
      'surfaces',
      'capabilities',
      'risk_class',
      'always_fast',
    };
    for (final entry in catalog.entries) {
      final row = entry.value as Map<String, dynamic>;
      expect(row.keys.toSet().difference(allowed), isEmpty, reason: entry.key);
      expect(File(row['flow'] as String).existsSync(), isTrue, reason: entry.key);
    }

    expect(
      (catalog['core-shell'] as Map<String, dynamic>)['risk_class'],
      'core',
    );
    expect(
      (catalog['core-shell'] as Map<String, dynamic>)['always_fast'],
      isTrue,
    );
    for (final id in const <String>[
      'vault-create',
      'vault-wrong-password',
      'vault-correct-unlock',
      'vault-restart-unlock',
    ]) {
      expect((catalog[id] as Map<String, dynamic>)['risk_class'], 'deep');
    }
  });

  test('Personalization atomic flow boots independently and reuses the visual scenario', () {
    final project = jsonDecode(File('applab.project.json').readAsStringSync())
        as Map<String, dynamic>;
    final journeys = project['journeys'] as Map<String, dynamic>;
    final catalog = journeys['catalog'] as Map<String, dynamic>;
    final item = catalog['personalization-critical'] as Map<String, dynamic>;
    const flowPath = '.maestro/journeys/personalization-atomic.yaml';
    const scenarioPath = '.maestro/journey/personalization.yaml';
    final flow = File(flowPath).readAsStringSync();
    final scenario = File(scenarioPath).readAsStringSync();

    expect(item['flow'], flowPath);
    expect(item['paths'], contains('lib/src/screens/personalization_screen.dart'));
    expect(item['paths'], contains(scenarioPath));
    expect(item['risk_class'], 'normal');
    expect(item['always_fast'], isFalse);
    expect(flow, contains('clearState: true'));
    expect(flow, contains("id: 'onboarding_open_agenda'"));
    expect(flow, contains("id: 'main-nav-more'"));
    expect(flow, contains('file: ../journey/personalization.yaml'));
    expect(scenario, contains("id: 'personalization_preset_essential'"));
    expect(scenario, contains("id: 'personalization_restore_complete'"));
    expect(journeys['primary'], '.maestro/applab-smoke.yaml');
  });

  test('Vault atomic journeys are independently bootstrappable', () {
    final create =
        File('.maestro/journeys/vault-create.yaml').readAsStringSync();
    final wrong =
        File('.maestro/journeys/vault-wrong-password.yaml').readAsStringSync();
    final correct =
        File('.maestro/journeys/vault-correct-unlock.yaml').readAsStringSync();
    final restart =
        File('.maestro/journeys/vault-restart-unlock.yaml').readAsStringSync();

    expect(create, contains('clearState: true'));
    expect(create, contains("id: 'vault_repeat_password_field'"));
    expect(wrong, contains("visible: '.*(Uno spazio solo tuo"));
    expect(wrong, contains("inputText: 'D2WrongPassword2026'"));
    expect(correct, contains("inputText: 'D2VaultPassword2026'"));
    expect(restart, contains('- stopApp'));
    expect(restart, contains('D2_APPLAB_PERSISTENCE'));

    for (final flow in <String>[wrong, correct, restart]) {
      expect(flow, contains("id: 'identity-offline-continue'"));
      expect(flow, contains("id: 'main-nav-more'"));
      expect(flow, contains("visible: '.*(Uno spazio solo tuo"));
    }
  });

  test('visual calendar checkpoint owns its starting state', () {
    final calendar =
        File('.maestro/journey/calendar.yaml').readAsStringSync();

    expect(calendar, contains('- launchApp'));
    expect(calendar, contains("id: 'main-nav-calendar'"));
    expect(calendar, contains("id: 'calendar-open-month-notebook'"));
  });

  test('legacy primary remains fail-safe while catalog is atomic', () {
    final project = jsonDecode(File('applab.project.json').readAsStringSync())
        as Map<String, dynamic>;
    final journeys = project['journeys'] as Map<String, dynamic>;
    final legacy = File('.maestro/applab-smoke.yaml').readAsStringSync();

    expect(journeys['primary'], '.maestro/applab-smoke.yaml');
    expect(legacy, contains('D2_APPLAB_PERSISTENCE'));
    expect(legacy, contains('D2WrongPassword2026'));
  });

  test('AppLab source-only lane never compiles or launches Android', () {
    final workflow =
        File('.github/workflows/applab.yml').readAsStringSync();
    final sourceCheck =
        File('tool/check_ui5_visual_flows.py').readAsStringSync();

    expect(workflow, contains('AppLab Source Gate'));
    expect(workflow, contains('tool/check_ui5_visual_flows.py'));
    expect(workflow, isNot(contains('external-project-runner.yml')));
    expect(workflow, isNot(contains('flutter build apk')));
    expect(workflow, isNot(contains('run_maestro: true')));
    expect(sourceCheck, contains('ui5-today-date-strip'));
  });

  test('Factory adoption remains canonical and central', () {
    final adoption = File('APP_FACTORY_ADOPTION.yaml').readAsStringSync();

    expect(adoption, contains('repository: riccardopinato/Agenda-per-Anna'));
    expect(adoption, contains('profile_version: 1'));
    expect(adoption, contains('mode: CENTRAL'));
    expect(adoption, contains('overwrite_existing: false'));
  });

  test('core-shell Capture validates the real date control, not a translated title', () {
    final flow = File('.maestro/journeys/core-shell.yaml').readAsStringSync();
    expect(
      flow,
      contains("- tapOn:\n    id: 'main-nav-create'\n- extendedWaitUntil:\n    visible:\n      id: 'capture-effective-date'"),
    );
    expect(flow, contains("- assertVisible:\n    id: 'capture-effective-date'"));
    expect(flow, isNot(contains("visible: '(Cattura|Capture|Capturar|Capturer)'")));
  });
}
