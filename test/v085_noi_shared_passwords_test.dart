import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agenda_per_anna/local_state_store.dart';
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

  test('v0.85 keeps shared keys and mirrors inside the existing encrypted Vault',
      () async {
    final vault = PrivateVaultService.instance;
    await vault.initialize();
    await vault.setup(
      password: 'correct-horse-battery',
      enableBiometric: false,
    );

    final key = await vault.ensureSharedPasswordKey('space-1');
    final encodedKey = base64UrlEncode(key);

    await vault.upsertSharedCredentialMirror(
      spaceId: 'space-1',
      credentialId: 'credential-1',
      service: 'Netflix',
      username: 'anna',
      email: 'anna@example.test',
      password: 'shared-secret-85',
      notes: 'Profilo famiglia',
      updatedAt: DateTime(2026, 9, 30, 9),
    );

    final state = await LocalStateStore.instance.open(
      legacyPreferences: await SharedPreferences.getInstance(),
    );
    final raw = state.getString('private_vault_payload_v1');

    expect(raw, isNotNull);
    for (final plaintext in [
      'Netflix',
      'anna@example.test',
      'shared-secret-85',
      'Profilo famiglia',
      encodedKey,
    ]) {
      expect(raw, isNot(contains(plaintext)));
    }

    expect(
      state.getKeys().where((key) => key.startsWith('private_vault_')).toSet(),
      {'private_vault_meta_v1', 'private_vault_payload_v1'},
    );

    vault.lock();
    expect(vault.hasSharedPasswordKey('space-1'), isFalse);
    expect(vault.credentialEntries, isEmpty);

    expect(await vault.unlockWithPassword('correct-horse-battery'), isTrue);
    expect(vault.hasSharedPasswordKey('space-1'), isTrue);

    final mirror = vault.sharedCredentialEntries('space-1').single;
    expect(mirror.isSharedCredential, isTrue);
    expect(mirror.sharedCredentialId, 'credential-1');
    expect(mirror.service, 'Netflix');
    expect(mirror.password, 'shared-secret-85');
  });

  test('Noi mirrors cannot diverge through personal Vault APIs', () async {
    final vault = PrivateVaultService.instance;
    await vault.initialize();
    await vault.setup(
      password: 'correct-horse-battery',
      enableBiometric: false,
    );
    await vault.ensureSharedPasswordKey('space-1');
    await vault.upsertSharedCredentialMirror(
      spaceId: 'space-1',
      credentialId: 'credential-1',
      service: 'Google',
      username: 'anna',
      email: '',
      password: 'secret',
      notes: '',
      updatedAt: DateTime(2026, 9, 30, 9),
    );

    final mirror = vault.sharedCredentialEntries('space-1').single;

    expect(
      () => vault.upsertCredential(
        id: mirror.id,
        service: 'Google changed locally',
        username: 'anna',
        email: '',
        password: 'different-secret',
        notes: '',
      ),
      throwsA(isA<StateError>()),
    );
    expect(
      () => vault.delete(mirror.id),
      throwsA(isA<StateError>()),
    );

    await vault.deleteSharedCredentialMirror('space-1', 'credential-1');
    expect(vault.sharedCredentialEntries('space-1'), isEmpty);
  });

  test('membership reconcile purges shared key and credential mirrors', () async {
    final vault = PrivateVaultService.instance;
    await vault.initialize();
    await vault.setup(
      password: 'correct-horse-battery',
      enableBiometric: false,
    );
    await vault.ensureSharedPasswordKey('space-stale');
    await vault.upsertSharedCredentialMirror(
      spaceId: 'space-stale',
      credentialId: 'credential-1',
      service: 'Amazon',
      username: '',
      email: 'anna@example.test',
      password: 'secret',
      notes: '',
      updatedAt: DateTime(2026, 9, 30, 9),
    );

    await vault.reconcileSharedPasswordSpaces({'space-active'});

    expect(vault.hasSharedPasswordKey('space-stale'), isFalse);
    expect(vault.sharedCredentialEntries('space-stale'), isEmpty);
  });

  test('v0.85 source contract keeps shared credentials E2EE and authoritative',
      () {
    final service =
        File('lib/shared_password_service.dart').readAsStringSync();
    final vault = File('lib/vault_service.dart').readAsStringSync();
    final privateVault =
        File('lib/src/screens/private_vault.dart').readAsStringSync();
    final sharedScreen =
        File('lib/src/screens/shared_passwords_screen.dart').readAsStringSync();
    final sharedSpace =
        File('lib/src/screens/shared_space.dart').readAsStringSync();
    final store = File('lib/src/agenda_store.dart').readAsStringSync();

    expect(service, contains("'shared_credential'"));
    expect(service, contains('upsertSharedPasswordKeyEnvelope'));
    expect(service, contains("'shared_password_key_meta'"));
    expect(service, contains("'AES-256-GCM'"));
    expect(service, contains('GCMBlockCipher(AESEngine())'));
    expect(service, contains('PBKDF2KeyDerivator'));
    expect(service, contains('sha256.convert(key).toString()'));
    expect(
      service,
      contains("'annas-diary-noi-password:\$spaceId:\$credentialId:v1'"),
    );
    expect(service, contains('payload: payload'));
    expect(
      service,
      isNot(contains('payload: credential.toJson()')),
    );

    expect(vault, contains("'sharedPasswordKeys'"));
    expect(vault, contains('isSharedCredential'));
    expect(vault, contains('deleteSharedCredentialMirror'));
    expect(vault, isNot(contains('private_vault_shared_passwords')));

    expect(privateVault, contains('passwordUpdatedAt('));
    expect(privateVault, contains("'d MMMM yyyy · HH:mm'"));
    expect(privateVault, contains('entry.updatedAt'));

    expect(sharedScreen, contains('SharedPasswordsScreen'));
    expect(sharedScreen, contains('service.upsertCredential('));
    expect(sharedScreen, contains('service.deleteCredential('));
    expect(sharedScreen, contains('Duration(seconds: 30)'));
    expect(sharedScreen, contains('Duration(seconds: 60)'));
    expect(sharedScreen, contains('passwordUpdatedAt('));
    expect(sharedScreen, contains("'d MMMM yyyy · HH:mm'"));
    expect(sharedScreen, contains('credential.updatedAt'));

    expect(sharedSpace, contains('_openSharedPasswords'));
    expect(sharedSpace, contains('revokeLocalSpace'));
    expect(store, contains("change.entityType == 'shared_credential'"));
    expect(
      store,
      contains('SharedPasswordService.instance.applyRealtimeChange(change)'),
    );
  });
}
