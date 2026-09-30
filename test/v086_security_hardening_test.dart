import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agenda_per_anna/local_state_store.dart';
import 'package:agenda_per_anna/main.dart';
import 'package:agenda_per_anna/vault_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrivateVaultService.instance.resetMemoryForTesting();
    await LocalStateStore.instance.resetForTesting();
  });

  tearDown(() async {
    if (PrivateVaultService.instance.initialized) {
      await PrivateVaultService.instance.destroy();
    }
    PrivateVaultService.instance.resetMemoryForTesting();
    await LocalStateStore.instance.resetForTesting();
  });

  test('v0.86 creates new Vault wraps with PBKDF2 600k', () async {
    final vault = PrivateVaultService.instance;
    await vault.initialize();

    await expectLater(
      vault.setup(
        password: '12345678901',
        enableBiometric: false,
      ),
      throwsA(isA<FormatException>()),
    );

    await vault.setup(
      password: 'correct-horse-battery-staple',
      enableBiometric: false,
    );

    final state = await LocalStateStore.instance.open(
      legacyPreferences: await SharedPreferences.getInstance(),
    );
    final rawMeta = state.getString('private_vault_meta_v1');
    final rawPayload = state.getString('private_vault_payload_v1');

    expect(rawMeta, isNotNull);
    expect(rawPayload, isNotNull);
    final meta = Map<String, dynamic>.from(
      jsonDecode(rawMeta!) as Map,
    );
    expect(meta['iterations'], 600000);
    expect(
      File('lib/vault_service.dart').readAsStringSync(),
      contains('_legacyIterations = 180000'),
    );
    expect(
      File('lib/vault_service.dart').readAsStringSync(),
      contains('_upgradePasswordWrap'),
    );
    expect(rawMeta, isNot(contains('correct-horse-battery-staple')));
    expect(rawPayload, isNot(contains('correct-horse-battery-staple')));
  });

  test('shared credential mirror revision survives encrypted Vault roundtrip',
      () async {
    final vault = PrivateVaultService.instance;
    await vault.initialize();
    await vault.setup(
      password: 'correct-horse-battery-staple',
      enableBiometric: false,
    );
    await vault.ensureSharedPasswordKey('space-revision');
    await vault.upsertSharedCredentialMirror(
      spaceId: 'space-revision',
      credentialId: 'credential-revision',
      service: 'Example',
      username: 'user',
      email: 'user@example.test',
      password: 'secret-value',
      notes: 'revision contract',
      updatedAt: DateTime(2026, 9, 30, 12),
      sharedRevision: 7,
    );

    vault.lock();
    expect(
      await vault.unlockWithPassword('correct-horse-battery-staple'),
      isTrue,
    );

    final mirror = vault.sharedCredentialEntries('space-revision').single;
    expect(mirror.sharedRevision, 7);
    expect(mirror.password, 'secret-value');
  });

  test('v0.86 server contract is atomic and revision safe', () {
    final migration = File(
      'supabase/migrations/027_shared_password_hardening_v086.sql',
    ).readAsStringSync();
    final cloud = File('lib/cloud_sync_service.dart').readAsStringSync();
    final service =
        File('lib/shared_password_service.dart').readAsStringSync();
    final backendContract = File(
      'supabase/tests/027_shared_password_hardening_contract.sql',
    ).readAsStringSync();

    expect(migration, contains('claim_shared_password_key_meta'));
    expect(migration, contains('on conflict (record_key) do nothing'));
    expect(migration, contains('for update'));
    expect(migration, contains('shared_password_revision_conflict'));
    expect(migration, contains("'revision'"));
    expect(migration, contains('shared_password_ciphertext_payload_invalid'));
    expect(migration, contains("array['service', 'username', 'email', 'password', 'notes']"));
    expect(migration, contains('agenda_records_shared_password_guard'));
    expect(migration, contains('shared_password_dedicated_rpc_required'));
    expect(migration, contains('consume_shared_password_key_envelope'));
    expect(migration, contains('v_at timestamptz := clock_timestamp()'));

    expect(cloud, contains('claimSharedPasswordKeyMeta'));
    expect(cloud, contains('upsertSharedPasswordCredential'));
    expect(cloud, contains('deleteSharedPasswordCredential'));
    expect(cloud, contains('consumeSharedPasswordKeyEnvelope'));
    expect(cloud, contains('pullSharedRecordsByType'));

    expect(service, contains('expectedRevision'));
    expect(service, contains('SharedPasswordConflictException'));
    expect(service, contains('createRecoveryPackage'));
    expect(service, contains('importRecoveryPackage'));
    expect(service, contains('_recoveryIterations = 600000'));
    expect(service, contains('pullSharedRecordsByType'));
    expect(service, isNot(contains('pullSharedRecords(spaceId')));
    expect(service, contains('authoritativeUpdatedAt: record.clientUpdatedAt'));
    expect(service, contains('authoritativeUpdatedBy: record.updatedBy'));
    expect(service, contains('authoritativeUpdatedAt: change.clientUpdatedAt'));
    expect(service, contains('authoritativeUpdatedBy: change.updatedBy'));
    expect(service, contains('updatedAt: authoritativeUpdatedAt.toLocal()'));
    expect(service, isNot(contains('updatedAt: base.updatedAt,')));

    expect(backendContract, contains('stale_update_was_not_rejected'));
    expect(backendContract, contains('stale_delete_was_not_rejected'));
    expect(backendContract, contains('generic_merge_bypass_was_not_rejected'));
    expect(backendContract, contains('removed_member_was_not_rejected'));
    expect(backendContract, contains('pairing_envelope_was_consumed_twice'));
    expect(
      backendContract,
      contains('shared_password_timestamp_not_server_authoritative'),
    );
    expect(backendContract, contains('rollback;'));
  });

  test('v0.86 UI carries revisions and reconciles membership immediately', () {
    final sharedScreen =
        File('lib/src/screens/shared_passwords_screen.dart').readAsStringSync();
    final privateVault =
        File('lib/src/screens/private_vault.dart').readAsStringSync();
    final store = File('lib/src/agenda_store.dart').readAsStringSync();

    expect(
      sharedScreen,
      contains('expectedRevision: existing?.revision ?? 0'),
    );
    expect(
      sharedScreen,
      contains('expectedRevision: credential.revision'),
    );
    expect(sharedScreen, contains('SharedPasswordConflictException'));
    expect(sharedScreen, contains('_showRecoveryBackup'));
    expect(sharedScreen, contains('_importRecoveryBackup'));
    expect(sharedScreen, contains('vaultWebSecurityWarning'));

    expect(privateVault, contains('expectedRevision: entry.sharedRevision'));
    expect(privateVault, contains('refreshAllAvailableSpacesSafe()'));
    expect(privateVault, contains('vaultWebSecurityWarning'));

    expect(store, contains('remoteSpacesLoaded && PrivateVaultService.instance.unlocked'));
    expect(store, contains('reconcileMembershipWithSpaceIds(activeSpaceIds)'));
  });

  test('v0.86 localizes new Vault and conflict vocabulary', () {
    expect(const AnnaStrings('en').vaultPasswordTooShort, contains('12'));
    expect(const AnnaStrings('it').sharedPasswordsConflict, contains('altro dispositivo'));
    expect(const AnnaStrings('es').sharedPasswordsRecoveryBackup, isNotEmpty);
    expect(const AnnaStrings('fr').vaultWebSecurityWarning, isNotEmpty);
    expect(const AnnaStrings('pt').sharedPasswordsImportRecovery, isNotEmpty);
  });
}
