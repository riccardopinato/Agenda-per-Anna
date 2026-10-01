import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agenda_per_anna/local_state_store.dart';
import 'package:agenda_per_anna/vault_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final vault = PrivateVaultService.instance;

  Future<void> resetTestState() async {
    vault.resetMemoryForTesting();
    await LocalStateStore.instance.resetForTesting();
    SharedPreferences.setMockInitialValues({});

    // In Chrome this opens the real IndexedDB-backed store. If a previous test
    // left a Vault behind, destroy only that isolated test state before the
    // next scenario. On the VM the same helper uses the in-memory test backend.
    await vault.initialize();
    if (vault.configured) {
      await vault.destroy();
    }
    vault.resetMemoryForTesting();
    await LocalStateStore.instance.resetForTesting();
    SharedPreferences.setMockInitialValues({});
  }

  setUp(resetTestState);
  tearDown(resetTestState);

  test(
    'Web Vault survives browser-style reload and unlocks the encrypted payload',
    () async {
      await vault.initialize();
      await vault.setup(
        password: 'browser-vault-password-123',
        enableBiometric: false,
      );
      await vault.upsert(
        title: 'Nota privata',
        body: 'contenuto cifrato persistente',
      );
      await vault.upsertCredential(
        service: 'Servizio test',
        username: 'utente',
        email: 'utente@example.test',
        password: 'password-segreta',
        notes: 'nota credenziale',
      );

      vault.lock();

      // Simulate a browser/PWA reload: discard every in-memory Vault object and
      // reopen the persisted IndexedDB-backed state.
      vault.resetMemoryForTesting();
      await LocalStateStore.instance.resetForTesting();
      await vault.initialize();

      expect(vault.configured, isTrue);
      expect(vault.unlocked, isFalse);
      expect(vault.entries, isEmpty);

      var browserEventLoopProgressed = false;
      final browserTick = Future<void>.delayed(
        Duration.zero,
        () => browserEventLoopProgressed = true,
      );
      final unlock = vault.unlockWithPassword('browser-vault-password-123');

      await browserTick;
      expect(browserEventLoopProgressed, isTrue);
      expect(await unlock, isTrue);

      expect(vault.entries, hasLength(2));
      expect(
        vault.noteEntries.single.body,
        'contenuto cifrato persistente',
      );
      expect(
        vault.credentialEntries.single.password,
        'password-segreta',
      );
    },
  );

  test('Web Vault rejects a wrong password without losing persisted data',
      () async {
    await vault.initialize();
    await vault.setup(
      password: 'browser-vault-password-456',
      enableBiometric: false,
    );
    await vault.upsert(
      title: 'Persistente',
      body: 'non deve sparire',
    );
    vault.lock();

    expect(await vault.unlockWithPassword('password-errata-123'), isFalse);
    expect(vault.unlocked, isFalse);

    expect(await vault.unlockWithPassword('browser-vault-password-456'), isTrue);
    expect(vault.noteEntries.single.body, 'non deve sparire');
  });
}
