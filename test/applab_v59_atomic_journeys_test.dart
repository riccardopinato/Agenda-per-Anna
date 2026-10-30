import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AppLab v5.9 catalog uses only supported journey fields', () {
    final project = jsonDecode(File('applab.project.json').readAsStringSync())
        as Map<String, dynamic>;
    final journeys = project['journeys'] as Map<String, dynamic>;
    final catalog = journeys['catalog'] as Map<String, dynamic>;

    expect(catalog.length, 9);
    expect(catalog.keys.first, 'core-shell');
    expect(catalog.keys, containsAll(<String>[
      'onboarding',
      'navigation-critical',
      'memories-critical',
      'settings-critical',
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

  test('AppLab workflow is pinned to reviewed v6.3A exact SHA', () {
    final workflow =
        File('.github/workflows/applab.yml').readAsStringSync();

    expect(
      workflow,
      contains('@46816a1786820eb7c0edab7500ca950b10c7718c'),
    );
    expect(
      workflow,
      contains('annas-diary-factory-fast-v4-journey-aware'),
    );
    expect(workflow, contains('analysis_mode: fast'));
    expect(workflow, contains('cache_verification: true'));
  });

  test('Factory adoption remains canonical and central', () {
    final adoption = File('APP_FACTORY_ADOPTION.yaml').readAsStringSync();

    expect(adoption, contains('repository: riccardopinato/Agenda-per-Anna'));
    expect(adoption, contains('profile_version: 1'));
    expect(adoption, contains('mode: CENTRAL'));
    expect(adoption, contains('overwrite_existing: false'));
  });
}
