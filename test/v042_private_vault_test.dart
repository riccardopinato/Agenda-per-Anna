import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:agenda_per_anna/private_vault_service.dart';

void main() {
  test('vault crypto roundtrip keeps plaintext authenticated and encrypted', () {
    final salt = Uint8List.fromList(List<int>.generate(16, (i) => i + 1));
    final key = VaultCrypto.deriveKey(
      '7359',
      salt,
      iterations: 1000,
    );
    final plaintext = Uint8List.fromList(
      utf8.encode('dato molto privato'),
    );

    final envelope = VaultCrypto.encrypt(
      key,
      plaintext,
      aad: 'test-vault',
    );
    final encodedEnvelope = jsonEncode(envelope);

    expect(encodedEnvelope, isNot(contains('dato molto privato')));

    final decrypted = VaultCrypto.decrypt(
      key,
      Map<String, dynamic>.from(envelope),
      aad: 'test-vault',
    );
    expect(utf8.decode(decrypted), 'dato molto privato');
  });

  test('wrong derived key cannot decrypt authenticated vault payload', () {
    final salt = Uint8List.fromList(List<int>.filled(16, 7));
    final rightKey = VaultCrypto.deriveKey(
      'password-corretta',
      salt,
      iterations: 1000,
    );
    final wrongKey = VaultCrypto.deriveKey(
      'password-sbagliata',
      salt,
      iterations: 1000,
    );
    final envelope = VaultCrypto.encrypt(
      rightKey,
      Uint8List.fromList(utf8.encode('segreto')),
      aad: 'test-vault',
    );

    expect(
      () => VaultCrypto.decrypt(
        wrongKey,
        Map<String, dynamic>.from(envelope),
        aad: 'test-vault',
      ),
      throwsA(anything),
    );
  });

  test('master key can be rewrapped without re-encrypting payload', () {
    final master = Uint8List.fromList(List<int>.generate(32, (i) => i));
    final oldSalt = Uint8List.fromList(List<int>.filled(16, 4));
    final newSalt = Uint8List.fromList(List<int>.filled(16, 9));
    final oldKey = VaultCrypto.deriveKey('1234', oldSalt, iterations: 1000);
    final newKey =
        VaultCrypto.deriveKey('nuova-password', newSalt, iterations: 1000);

    final oldWrapped = VaultCrypto.wrapMasterKey(oldKey, master);
    final recovered = VaultCrypto.unwrapMasterKey(
      oldKey,
      Map<String, dynamic>.from(oldWrapped),
    );
    final newWrapped = VaultCrypto.wrapMasterKey(newKey, recovered);
    final recoveredAgain = VaultCrypto.unwrapMasterKey(
      newKey,
      Map<String, dynamic>.from(newWrapped),
    );

    expect(recoveredAgain, orderedEquals(master));
  });

  test('v0.42 vault stays outside cloud and standard backup domains', () {
    final backup =
        File('lib/src/store/backup_domain.dart').readAsStringSync();
    final cloud = File('lib/cloud_sync_service.dart').readAsStringSync();
    final home =
        File('lib/src/screens/home_inbox_search.dart').readAsStringSync();
    final screen =
        File('lib/src/screens/private_vault.dart').readAsStringSync();
    final service = File('lib/private_vault_service.dart').readAsStringSync();
    final prepare =
        File('tool/prepare_android_platform.py').readAsStringSync();

    expect(backup, isNot(contains('private_vault')));
    expect(cloud, isNot(contains('private_vault')));
    expect(home, contains('Cassaforte privata'));
    expect(home, contains('PrivateVaultScreen'));
    expect(screen, contains('vault.lock()'));
    expect(screen, contains('AppLifecycleState.paused'));
    expect(service, contains('GCMBlockCipher(AESEngine())'));
    expect(service, contains('180000'));
    expect(service, contains('biometricOnly: true'));
    expect(prepare, contains('annas_diary/private_vault'));
    expect(prepare, contains('AndroidKeyStore'));
    expect(prepare, contains('android:allowBackup="false"'));
  });

  test('vault secret accepts PIN or passphrase with minimum strength', () {
    expect(PrivateVaultService.validateSecret('1234'), isNull);
    expect(PrivateVaultService.validateSecret('abc123'), isNull);
    expect(PrivateVaultService.validateSecret('12'), isNotNull);
    expect(PrivateVaultService.validateSecret('abc'), isNotNull);
  });
}
