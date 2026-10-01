import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agenda_per_anna/cycle_tracker_domain.dart';
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

  test('encrypted recovery round-trips the complete private Vault', () async {
    final vault = PrivateVaultService.instance;
    const unlockPhrase = 'fixture-recovery-phrase-090';

    await vault.initialize();
    await vault.setup(
      password: unlockPhrase,
      enableBiometric: false,
    );
    await vault.upsert(
      title: 'Fixture note',
      body: 'fixture-private-body-090',
    );
    await vault.upsertCredential(
      service: 'Fixture service',
      username: 'fixture-user',
      email: 'fixture@example.invalid',
      password: 'fixture-secret-value-090',
      notes: 'fixture credential note',
    );
    await vault.upsertCycleDayLog(
      CycleDayLog(
        date: DateTime(2026, 9, 30),
        flow: CycleFlow.medium,
        painLevel: 3,
        symptoms: const ['cramps', 'custom:Fixture'],
        moods: const ['sensitive'],
        discharge: 'eggWhite',
        basalTemperature: 36.55,
        ovulationTest: 'positive',
        notes: 'fixture-cycle-note-090',
        createdAt: DateTime(2026, 9, 30, 8),
        updatedAt: DateTime(2026, 9, 30, 8),
      ),
    );

    final recoveryPackage = await vault.exportRecoveryPackage();
    final decoded = utf8.decode(base64Url.decode(recoveryPackage));

    expect(decoded, contains('annas_diary_private_vault_recovery'));
    expect(decoded, isNot(contains('fixture-private-body-090')));
    expect(decoded, isNot(contains('fixture-secret-value-090')));
    expect(decoded, isNot(contains('fixture-cycle-note-090')));

    final packageJson =
        Map<String, dynamic>.from(jsonDecode(decoded) as Map);
    final meta = Map<String, dynamic>.from(packageJson['meta'] as Map);
    expect(meta['biometricWrap'], isNull);

    await vault.destroy();
    expect(vault.configured, isFalse);

    expect(
      await vault.restoreRecoveryPackage(
        recoveryPackage: recoveryPackage,
        password: 'fixture-wrong-phrase-090',
      ),
      isFalse,
    );
    expect(vault.configured, isFalse);

    expect(
      await vault.restoreRecoveryPackage(
        recoveryPackage: recoveryPackage,
        password: unlockPhrase,
      ),
      isTrue,
    );
    expect(vault.configured, isTrue);
    expect(vault.unlocked, isTrue);
    expect(vault.noteEntries.single.body, 'fixture-private-body-090');
    expect(
      vault.credentialEntries.single.password,
      'fixture-secret-value-090',
    );
    final cycleLog = vault.cycleTrackerState.logFor(DateTime(2026, 9, 30));
    expect(cycleLog?.basalTemperature, 36.55);
    expect(cycleLog?.notes, 'fixture-cycle-note-090');
  });

  test('invalid recovery never overwrites the active local Vault', () async {
    final vault = PrivateVaultService.instance;

    await vault.initialize();
    await vault.setup(
      password: 'fixture-source-phrase-090',
      enableBiometric: false,
    );
    await vault.upsert(title: 'Source', body: 'source fixture');
    final sourcePackage = await vault.exportRecoveryPackage();

    await vault.destroy();
    await vault.setup(
      password: 'fixture-current-phrase-090',
      enableBiometric: false,
    );
    await vault.upsert(title: 'Current', body: 'must remain');

    final restored = await vault.restoreRecoveryPackage(
      recoveryPackage: sourcePackage,
      password: 'fixture-invalid-source-phrase',
    );

    expect(restored, isFalse);
    expect(vault.unlocked, isTrue);
    expect(vault.noteEntries.single.title, 'Current');
    expect(vault.noteEntries.single.body, 'must remain');
  });

  test('recovery and cycle privacy hardening stay explicit in UI', () {
    final vaultScreen =
        File('lib/src/screens/private_vault.dart').readAsStringSync();
    final cycleScreen =
        File('lib/src/screens/cycle_tracker_screen.dart').readAsStringSync();

    expect(vaultScreen, contains('vaultRecoveryImportExisting'));
    expect(vaultScreen, contains('vaultRecoveryRestoreLocked'));
    expect(vaultScreen, contains('_showVaultRecoveryOptions'));
    expect(vaultScreen, contains('Duration(seconds: 60)'));
    expect(cycleScreen, contains('Duration(seconds: 60)'));
    expect(cycleScreen, contains('Semantics('));
  });
}
