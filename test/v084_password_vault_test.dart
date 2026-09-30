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

  test('v0.84 credentials reuse the encrypted Vault payload', () async {
    final vault = PrivateVaultService.instance;
    await vault.initialize();
    await vault.setup(
      password: 'correct-horse-battery',
      enableBiometric: false,
    );

    await vault.upsertCredential(
      service: 'Google',
      username: 'anna.user',
      email: 'anna@example.test',
      password: 'super-secret-password-84',
      notes: 'Account principale con 2FA',
    );

    final state = await LocalStateStore.instance.open(
      legacyPreferences: await SharedPreferences.getInstance(),
    );
    final raw = state.getString('private_vault_payload_v1');

    expect(raw, isNotNull);
    for (final plaintext in [
      'Google',
      'anna.user',
      'anna@example.test',
      'super-secret-password-84',
      'Account principale con 2FA',
    ]) {
      expect(raw, isNot(contains(plaintext)));
    }

    expect(
      state.getKeys().where((key) => key.startsWith('private_vault_')).toSet(),
      {'private_vault_meta_v1', 'private_vault_payload_v1'},
    );

    vault.lock();
    expect(vault.entries, isEmpty);
    expect(vault.credentialEntries, isEmpty);

    expect(await vault.unlockWithPassword('correct-horse-battery'), isTrue);
    final credential = vault.credentialEntries.single;
    expect(credential.kind, PrivateVaultEntryKind.credential);
    expect(credential.service, 'Google');
    expect(credential.username, 'anna.user');
    expect(credential.email, 'anna@example.test');
    expect(credential.password, 'super-secret-password-84');
    expect(credential.notes, 'Account principale con 2FA');
  });

  test('legacy Vault notes remain backward compatible', () {
    final legacy = PrivateVaultEntry.fromJson({
      'id': 'legacy-note',
      'title': 'Vecchia nota',
      'body': 'Contenuto esistente',
      'createdAt': '2026-01-01T10:00:00.000Z',
      'updatedAt': '2026-01-02T10:00:00.000Z',
    });

    expect(legacy.kind, PrivateVaultEntryKind.note);
    expect(legacy.isCredential, isFalse);
    expect(legacy.title, 'Vecchia nota');
    expect(legacy.body, 'Contenuto esistente');
    expect(legacy.username, isEmpty);
    expect(legacy.email, isEmpty);
    expect(legacy.password, isEmpty);
  });

  test('credential update and permanent delete stay inside Vault lifecycle', () async {
    final vault = PrivateVaultService.instance;
    await vault.initialize();
    await vault.setup(
      password: 'another-strong-password',
      enableBiometric: false,
    );

    await vault.upsertCredential(
      service: 'Netflix',
      username: 'anna',
      email: '',
      password: 'first-password',
      notes: '',
    );
    final original = vault.credentialEntries.single;

    await vault.upsertCredential(
      id: original.id,
      service: 'Netflix',
      username: 'anna',
      email: 'anna@example.test',
      password: 'changed-password',
      notes: 'Profilo personale',
    );

    final updated = vault.credentialEntries.single;
    expect(updated.id, original.id);
    expect(updated.createdAt, original.createdAt);
    expect(updated.email, 'anna@example.test');
    expect(updated.password, 'changed-password');

    await vault.delete(updated.id);
    expect(vault.credentialEntries, isEmpty);
  });

  test('Password Vault UI keeps secrets behind the existing privacy boundary', () {
    final screen =
        File('lib/src/screens/private_vault.dart').readAsStringSync();
    final service = File('lib/vault_service.dart').readAsStringSync();

    expect(screen, contains('SegmentedButton<_VaultSection>'));
    expect(screen, contains('vault.upsertCredential('));
    expect(screen, contains('obscureText: !revealPassword'));
    expect(screen, contains('Clipboard.setData'));
    expect(screen, contains('Duration(seconds: 30)'));
    expect(screen, contains('current?.text == value'));
    expect(screen, contains('vault.setSecureScreen(true)'));

    expect(service, contains("static const _payloadKey = 'private_vault_payload_v1'"));
    expect(service, isNot(contains('private_vault_credentials_v1')));
    expect(service, isNot(contains('CloudSyncService')));
    expect(service.toLowerCase(), isNot(contains('supabase')));
  });
}