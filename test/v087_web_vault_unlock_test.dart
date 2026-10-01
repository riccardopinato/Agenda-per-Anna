import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('v0.87 keeps Web Vault KDF asynchronous and compatible', () {
    final service = File('lib/vault_service.dart').readAsStringSync();
    final web =
        File('lib/src/security/vault_password_kdf_web.dart').readAsStringSync();

    expect(service, contains('await deriveVaultPasswordKey('));
    expect(service, isNot(contains('Uint8List _derivePasswordKey(')));
    expect(web, contains('web.window.crypto.subtle'));
    expect(web, contains('.deriveBits('));
    expect(web, contains("'PBKDF2'"));
    expect(web, contains("'SHA-256'"));
  });

  test('v0.87 Vault unlock UI cannot remain busy after completion', () {
    final screen =
        File('lib/src/screens/private_vault.dart').readAsStringSync();

    expect(screen, contains('submittedPassword.isEmpty || busy'));
    expect(screen, contains('vaultUnlocking'));
    expect(screen, contains('vaultUnlockFailed'));
    expect(screen, contains('finally {'));
    expect(screen, contains('if (mounted) setState(() => busy = false);'));
  });
}
