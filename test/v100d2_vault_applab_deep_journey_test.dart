import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('v1.00-D2 Vault AppLab flow proves the full password lifecycle', () {
    final smoke =
        File('.maestro/applab-smoke.yaml').readAsStringSync();
    final journey =
        File('.maestro/applab-journey.json').readAsStringSync();
    final vault =
        File('.maestro/journey/vault.yaml').readAsStringSync();

    expect(smoke, contains('runFlow: journey/vault.yaml'));
    expect(journey, isNot(contains('"name": "vault"')));

    // clearState=true belongs to the parent smoke. The deep flow must therefore
    // require first-time setup instead of accepting setup OR locked state.
    expect(smoke, contains('clearState: true'));
    expect(vault, contains('Uno spazio solo tuo|A space just for you'));
    expect(
      vault,
      isNot(
        contains(
          'Uno spazio solo tuo|A space just for you|Un espacio solo para ti|Un espace rien qu’à toi|Um espaço só teu|Cassaforte bloccata',
        ),
      ),
    );

    expect(vault, contains("inputText: 'D2VaultPassword2026'"));
    expect(
      "inputText: 'D2VaultPassword2026'".allMatches(vault).length,
      greaterThanOrEqualTo(4),
    );
    expect(vault, contains("inputText: 'D2WrongPassword2026'"));
    expect(vault, contains('eraseText: 64'));

    expect(vault, contains("inputText: 'D2_APPLAB_PERSISTENCE'"));
    expect(
      vault,
      contains(
        "inputText: 'D2 encrypted payload survives relock and restart'",
      ),
    );
    expect(
      "assertVisible: 'D2 encrypted payload survives relock and restart'"
          .allMatches(vault)
          .length,
      2,
    );

    expect(vault, contains('Blocca adesso|Lock now'));
    expect(vault, contains('Password non corretta\\.|Incorrect password\\.'));
    expect(vault, contains('stopApp'));
    expect(vault, contains('launchApp'));
  });

  test('v1.00-D2 deep Vault steps stay ordered and cannot collapse to navigation',
      () {
    final vault =
        File('.maestro/journey/vault.yaml').readAsStringSync();

    int at(String marker) {
      final index = vault.indexOf(marker);
      expect(index, greaterThanOrEqualTo(0), reason: 'Missing $marker');
      return index;
    }

    final setup = at("inputText: 'D2VaultPassword2026'");
    final create = at("inputText: 'D2_APPLAB_PERSISTENCE'");
    final relock = at('# RELOCK:');
    final wrong = at("inputText: 'D2WrongPassword2026'");
    final correct = at('# CORRECT UNLOCK:');
    final stop = at('- stopApp');
    final restartUnlock = vault.lastIndexOf("inputText: 'D2VaultPassword2026'");
    final finalPayload =
        vault.lastIndexOf("assertVisible: 'D2 encrypted payload survives relock and restart'");

    expect(setup, lessThan(create));
    expect(create, lessThan(relock));
    expect(relock, lessThan(wrong));
    expect(wrong, lessThan(correct));
    expect(correct, lessThan(stop));
    expect(stop, lessThan(restartUnlock));
    expect(restartUnlock, lessThan(finalPayload));
  });

  test('v1.00-D2 keeps physical-only security evidence out of AppLab claims', () {
    final doc =
        File('docs/V100_D2_VAULT_APPLAB_DEEP_JOURNEY.md').readAsStringSync();

    expect(doc, contains('TRUSTED RUNTIME'));
    expect(doc, contains('does not certify'));
    expect(doc, contains('Android Keystore'));
    expect(doc, contains('biometric'));
    expect(doc, contains('physical'));
  });
}
