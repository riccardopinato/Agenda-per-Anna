import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agenda_per_anna/local_state_store.dart';
import 'package:agenda_per_anna/vault_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStateStore.instance.resetForTesting();
  });

  tearDown(() async {
    await PrivateVaultService.instance.destroy();
    await LocalStateStore.instance.resetForTesting();
  });

  test('v0.42 vault encrypts plaintext and requires the correct password',
      () async {
    final vault = PrivateVaultService.instance;
    await vault.initialize();
    await vault.setup(
      password: 'correct-horse-battery',
      enableBiometric: false,
    );
    await vault.upsert(
      title: 'Segreto',
      body: 'contenuto-super-riservato-42',
    );

    final state = await LocalStateStore.instance.open(
      legacyPreferences: await SharedPreferences.getInstance(),
    );
    final raw = state.getString('private_vault_payload_v1');

    expect(raw, isNotNull);
    expect(raw, isNot(contains('Segreto')));
    expect(raw, isNot(contains('contenuto-super-riservato-42')));

    vault.lock();
    expect(vault.unlocked, isFalse);
    expect(vault.entries, isEmpty);

    expect(await vault.unlockWithPassword('password-sbagliata'), isFalse);
    expect(vault.unlocked, isFalse);

    expect(await vault.unlockWithPassword('correct-horse-battery'), isTrue);
    expect(vault.entries, hasLength(1));
    expect(vault.entries.single.title, 'Segreto');
    expect(vault.entries.single.body, 'contenuto-super-riservato-42');
  });

  test('vault storage is excluded from ordinary backup state keys', () async {
    final vault = PrivateVaultService.instance;
    await vault.initialize();
    await vault.setup(
      password: 'another-strong-password',
      enableBiometric: false,
    );
    await vault.upsert(
      title: 'Solo locale',
      body: 'mai nel cloud o backup agenda',
    );

    final state = await LocalStateStore.instance.open(
      legacyPreferences: await SharedPreferences.getInstance(),
    );
    expect(state.getKeys(), contains('private_vault_meta_v1'));
    expect(state.getKeys(), contains('private_vault_payload_v1'));

    final ordinaryKeys = state.getKeys().where(
          (key) =>
              key.startsWith('items_') ||
              key.startsWith('journals_') ||
              key.startsWith('inbox_') ||
              key.startsWith('cloud_'),
        );
    expect(
      ordinaryKeys.any((key) => key.startsWith('private_vault_')),
      isFalse,
    );
  });
}
