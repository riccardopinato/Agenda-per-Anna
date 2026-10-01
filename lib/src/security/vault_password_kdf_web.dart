import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Future<Uint8List> deriveVaultPasswordKey({
  required String password,
  required Uint8List salt,
  required int iterations,
  required int length,
}) async {
  final passwordBytes = Uint8List.fromList(utf8.encode(password));
  try {
    final subtle = web.window.crypto.subtle;

    final baseKey = await subtle
        .importKey(
          'raw',
          passwordBytes.toJS,
          <String, Object?>{'name': 'PBKDF2'}.jsify()!,
          false,
          <JSString>['deriveBits'.toJS].toJS,
        )
        .toDart;

    final derived = await subtle
        .deriveBits(
          <String, Object?>{
            'name': 'PBKDF2',
            'salt': salt.toJS,
            'iterations': iterations,
            'hash': 'SHA-256',
          }.jsify()!,
          baseKey,
          length * 8,
        )
        .toDart;

    return Uint8List.view(derived.toDart);
  } finally {
    passwordBytes.fillRange(0, passwordBytes.length, 0);
  }
}
