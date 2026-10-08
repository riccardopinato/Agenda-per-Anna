import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Future<Uint8List> derivePbkdf2Sha256Key({
  required String secret,
  required Uint8List salt,
  required int iterations,
  required int length,
}) async {
  if (iterations <= 0) {
    throw ArgumentError.value(iterations, 'iterations', 'must be positive');
  }
  if (length <= 0) {
    throw ArgumentError.value(length, 'length', 'must be positive');
  }

  final secretBytes = Uint8List.fromList(utf8.encode(secret));
  try {
    final subtle = web.window.crypto.subtle;
    final baseKey = await subtle
        .importKey(
          'raw',
          secretBytes.toJS,
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
    secretBytes.fillRange(0, secretBytes.length, 0);
  }
}
