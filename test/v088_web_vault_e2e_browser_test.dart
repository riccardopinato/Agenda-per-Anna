import 'package:flutter_test/flutter_test.dart';
import 'package:sembast_web/sembast_web.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agenda_per_anna/local_state_store.dart';
import 'package:agenda_per_anna/vault_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const databaseName = 'annas_diary_state_v1';
  final vault = PrivateVaultService.instance;

  Future<void> resetBrowserState() async {
    vault.resetMemoryForTesting();
    await LocalStateStore.instance.resetForTesting();
    await databaseFactoryWeb.deleteDatabase(databaseName);
    SharedPreferences.setMockInitialValues({});
  }

  setUp(resetBrowserState);
  tearDown(resetBrowserState);

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
