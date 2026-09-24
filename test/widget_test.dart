import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('first-run and universal-auth shell stay wired in the release tree', () {
    final shell = File('lib/src/app_shell.dart').readAsStringSync();
    final auth = File(
      'lib/src/auth/universal_auth_gate.dart',
    ).readAsStringSync();

    expect(shell, contains('_UniversalAuthGate('));
    expect(shell, contains('AgendaRoot(store: store)'));
    expect(shell, contains('La tua agenda, davvero tua.'));
    expect(auth, contains('Continua con Google'));
    expect(auth, contains('Hai già un account email/password?'));
  });
}
