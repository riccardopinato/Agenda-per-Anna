import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

Future<Uint8List> deriveVaultPasswordKey({
  required String password,
  required Uint8List salt,
  required int iterations,
  required int length,
}) async {
  final passwordBytes = Uint8List.fromList(utf8.encode(password));
  try {
    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, iterations, length));
    return derivator.process(passwordBytes);
  } finally {
    passwordBytes.fillRange(0, passwordBytes.length, 0);
  }
}
