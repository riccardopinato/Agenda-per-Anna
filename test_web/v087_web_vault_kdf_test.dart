import 'dart:convert';
import 'dart:typed_data';

import 'package:agenda_per_anna/src/security/vault_password_kdf.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('WebCrypto PBKDF2-SHA256 matches a compatibility vector', () async {
    final derived = await deriveVaultPasswordKey(
      password: 'password',
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
}
