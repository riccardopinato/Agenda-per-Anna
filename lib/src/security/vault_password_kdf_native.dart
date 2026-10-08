import 'dart:typed_data';

import 'pbkdf2_worker.dart';

Future<Uint8List> deriveVaultPasswordKey({
  required String password,
  required Uint8List salt,
  required int iterations,
  required int length,
}) =>
    derivePbkdf2Sha256Key(
      secret: password,
      salt: salt,
      iterations: iterations,
      length: length,
    );
