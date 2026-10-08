import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

Future<Uint8List> derivePbkdf2Sha256Key({
  required String secret,
  required Uint8List salt,
  required int iterations,
  required int length,
}) {
  if (iterations <= 0) {
    throw ArgumentError.value(iterations, 'iterations', 'must be positive');
  }
  if (length <= 0) {
    throw ArgumentError.value(length, 'length', 'must be positive');
  }

  final saltCopy = Uint8List.fromList(salt);
  return Isolate.run<Uint8List>(
    () => _derivePbkdf2Sha256KeySync(
      secret,
      saltCopy,
      iterations,
      length,
    ),
  );
}

Uint8List _derivePbkdf2Sha256KeySync(
  String secret,
  Uint8List salt,
  int iterations,
  int length,
) {
  final secretBytes = Uint8List.fromList(utf8.encode(secret));
  try {
    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, iterations, length));
    return derivator.process(secretBytes);
  } finally {
    secretBytes.fillRange(0, secretBytes.length, 0);
    salt.fillRange(0, salt.length, 0);
  }
}
