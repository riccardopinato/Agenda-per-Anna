import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('v0.79 consolidates existing privacy systems without new persistence', () {
    final settings =
        File('lib/src/screens/backup_settings.dart').readAsStringSync();
    final localization =
        File('lib/src/localization_v100.dart').readAsStringSync();
    final shell = File('lib/src/app_shell.dart').readAsStringSync();
    final vault = File('lib/vault_service.dart').readAsStringSync();
    final account =
        File('lib/src/screens/cloud_account.dart').readAsStringSync();

    expect(settings, contains('strings.v100PrivacyCenter'));
    expect(settings, contains('strings.v100PrivateVault'));
    expect(settings, contains('strings.v100BackupSafetyData'));
    expect(settings, contains('strings.v100AccountDataRights'));
    expect(localization, contains("it: 'Cassaforte privata'"));
    expect(localization, contains("it: 'Backup e sicurezza dati'"));
    expect(localization, contains("it: 'Account e diritti sui dati'"));

    expect(settings, contains('prefs.privacyLockEnabled'));
    expect(settings, contains('prefs.biometricUnlock'));
    expect(settings, contains('prefs.autoLockMinutes'));
    expect(settings, contains('prefs.hideHomeDetails'));

    expect(shell, contains('class _PrivacyGate'));
    expect(shell, contains('preferences.privacyLockEnabled'));
    expect(vault, contains("static const _metaKey = 'private_vault_meta_v1'"));
    expect(vault, contains("static const _payloadKey = 'private_vault_payload_v1'"));
    expect(account, contains('deleteCurrentAccount()'));
    expect(account, contains('eraseLocalCloudAccount(accountId)'));

    for (final forbidden in [
      'privacy_center_v1',
      'privacy_center_v2',
      '_privacyCenterKey',
      'privacy_database',
      'privacy_sync_queue',
      'privacy_cloud_table',
    ]) {
      expect(
        settings.toLowerCase(),
        isNot(contains(forbidden.toLowerCase())),
      );
    }
  });

  test('Privacy Center explicitly preserves Vault and cloud separation', () {
    final settings =
        File('lib/src/screens/backup_settings.dart').readAsStringSync();
    final localization =
        File('lib/src/localization_v100.dart').readAsStringSync();

    expect(settings, contains('strings.v100VaultAccountBoundary'));
    expect(settings, contains('strings.v100PrivateVaultDescription'));
    expect(settings, contains('strings.v100AccountDataRightsDescription'));
    expect(
      localization,
      contains('La Cassaforte resta locale anche se elimini l’account cloud.'),
    );
    expect(
      localization,
      contains('Spazio cifrato locale, separato da cloud, ricerca e backup ordinario.'),
    );
    expect(
      localization,
      contains('Sincronizzazione, disconnessione ed eliminazione definitiva'),
    );
  });
}
