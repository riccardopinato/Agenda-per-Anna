import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('v0.88 locks the Private Vault local-only recovery contract', () {
    final productBible = File('docs/PRODUCT_BIBLE.md').readAsStringSync();
    final localization =
        File('lib/src/localization.dart').readAsStringSync();
    final screen =
        File('lib/src/screens/private_vault.dart').readAsStringSync();

    expect(
      productBible,
      contains(
        'personal Vault notes and personal passwords are intentionally device-local',
      ),
    );
    expect(productBible, contains('not recoverable'));
    expect(localization, contains('String get vaultLocalOnlyWarning'));
    expect(screen, contains('_vaultLocalOnlyWarning(context, strings)'));
  });

  test('v0.88 replaces the historical partial format gate', () {
    final workflow =
        File('.github/workflows/dev-checks.yml').readAsStringSync();

    expect(workflow, contains('Format Dart sources'));
    expect(
      workflow,
      contains(
        'dart format --output=none --set-exit-if-changed lib test integration_test',
      ),
    );
    expect(workflow, isNot(contains('Format v0.40 modules')));
  });

  test('v0.88 CI runs compatibility and persisted browser Vault tests', () {
    final workflow =
        File('.github/workflows/dev-checks.yml').readAsStringSync();

    expect(
      workflow,
      contains('test/v087_web_vault_kdf_browser_test.dart'),
    );
    expect(
      workflow,
      contains('test/v088_web_vault_e2e_browser_test.dart'),
    );
  });
}
