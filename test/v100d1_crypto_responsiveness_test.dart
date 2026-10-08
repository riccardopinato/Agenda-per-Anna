import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agenda_per_anna/local_state_store.dart';
import 'package:agenda_per_anna/src/security/pbkdf2_worker.dart';
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

  test('D1 keeps the PBKDF2-SHA256 compatibility contract unchanged', () async {
    final derived = await derivePbkdf2Sha256Key(
      secret: 'password',
      salt: Uint8List.fromList(utf8.encode('salt')),
      iterations: 1,
      length: 32,
    );

    final hex = derived
        .map((value) => value.toRadixString(16).padLeft(2, '0'))
        .join();

    expect(
      hex,
      '120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b',
    );
  });

  test('D1 600k PBKDF2 leaves the main event loop responsive', () async {
    final heartbeat = Completer<void>();
    var kdfFinished = false;
    final stopwatch = Stopwatch()..start();

    Timer.run(() {
      if (!heartbeat.isCompleted) heartbeat.complete();
    });

    final derivation = derivePbkdf2Sha256Key(
      secret: 'correct-horse-battery-staple',
      salt: Uint8List.fromList(List<int>.generate(16, (index) => index)),
      iterations: 600000,
      length: 32,
    ).whenComplete(() => kdfFinished = true);

    await heartbeat.future.timeout(const Duration(seconds: 2));
    expect(
      kdfFinished,
      isFalse,
      reason:
          'The 600k derivation completed before the event-loop heartbeat; '
          'this usually means PBKDF2 ran synchronously on the main isolate.',
    );

    final derived = await derivation.timeout(const Duration(seconds: 20));
    stopwatch.stop();

    expect(derived, hasLength(32));
    expect(
      stopwatch.elapsed,
      lessThan(const Duration(seconds: 20)),
      reason: 'PBKDF2 600k exceeded the bounded D1 regression budget.',
    );
    // ignore: avoid_print
    print('D1 PBKDF2 600k: ${stopwatch.elapsedMilliseconds} ms');
  });

  test('D1 Vault 600k unlock stays responsive and data-compatible', () async {
    final vault = PrivateVaultService.instance;
    await vault.initialize();
    await vault.setup(
      password: 'correct-horse-battery-staple',
      enableBiometric: false,
    );
    await vault.upsert(
      title: 'D1 compatibility',
      body: 'payload survives isolate KDF',
    );
    vault.lock();

    final heartbeat = Completer<void>();
    var unlockFinished = false;
    final stopwatch = Stopwatch()..start();

    Timer.run(() {
      if (!heartbeat.isCompleted) heartbeat.complete();
    });

    final unlock = vault
        .unlockWithPassword('correct-horse-battery-staple')
        .whenComplete(() => unlockFinished = true);

    await heartbeat.future.timeout(const Duration(seconds: 2));
    expect(
      unlockFinished,
      isFalse,
      reason: 'Vault unlock must not monopolize the Flutter event loop.',
    );

    expect(
      await unlock.timeout(const Duration(seconds: 20)),
      isTrue,
    );
    stopwatch.stop();

    expect(vault.unlocked, isTrue);
    expect(vault.noteEntries.single.title, 'D1 compatibility');
    expect(vault.noteEntries.single.body, 'payload survives isolate KDF');
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 20)));
  });

  test('D1 routes Vault and Noi pairing/recovery through the async KDF worker',
      () {
    final vaultNative =
        File('lib/src/security/vault_password_kdf_native.dart')
            .readAsStringSync();
    final nativeWorker =
        File('lib/src/security/pbkdf2_worker_native.dart').readAsStringSync();
    final webWorker =
        File('lib/src/security/pbkdf2_worker_web.dart').readAsStringSync();
    final shared =
        File('lib/shared_password_service.dart').readAsStringSync();

    expect(vaultNative, contains('derivePbkdf2Sha256Key'));
    expect(vaultNative, isNot(contains('PBKDF2KeyDerivator')));

    expect(nativeWorker, contains("import 'dart:isolate';"));
    expect(nativeWorker, contains('Isolate.run<Uint8List>'));
    expect(nativeWorker, contains('PBKDF2KeyDerivator'));
    expect(nativeWorker, contains('HMac(SHA256Digest(), 64)'));

    expect(webWorker, contains('web.window.crypto.subtle'));
    expect(webWorker, contains('.deriveBits('));
    expect(webWorker, contains("'PBKDF2'"));
    expect(webWorker, contains("'SHA-256'"));

    expect(shared, contains('_pairingIterations = 180000'));
    expect(shared, contains('_recoveryIterations = 600000'));
    expect(shared, contains('wrappingKey = await _derivePairingKey('));
    expect(shared, contains('final wrappingKey = await _derivePairingKey('));
    expect(shared, contains('wrappingKey = await _deriveSecretKey('));
    expect(shared, contains('derivePbkdf2Sha256Key('));
    expect(shared, isNot(contains('PBKDF2KeyDerivator')));
  });
}
