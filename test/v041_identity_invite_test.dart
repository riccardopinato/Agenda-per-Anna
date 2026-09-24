import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:agenda_per_anna/cloud_sync_service.dart';

void main() {
  test('shared invite RPC payload keeps code, expiry and reuse state', () {
    final invite = SharedSpaceInvite.fromRpc({
      'code': 'a1b2c3d4',
      'expires_at': '2026-09-25T12:00:00Z',
      'reused': true,
    });

    expect(invite.code, 'A1B2C3D4');
    expect(invite.reused, isTrue);
    expect(invite.expiresAt.toUtc(), DateTime.utc(2026, 9, 25, 12));
  });

  test('v0.41 universal identity is outside Noi and uses Google OAuth', () {
    final cloud = File('lib/cloud_sync_service.dart').readAsStringSync();
    final shell = File('lib/src/app_shell.dart').readAsStringSync();
    final account =
        File('lib/src/screens/cloud_account.dart').readAsStringSync();

    expect(cloud, contains('OAuthProvider.google'));
    expect(
      cloud,
      contains('com.riccardopinato.agenda-per-anna://login-callback'),
    );
    expect(shell, contains('class _UniversalIdentityGate'));
    expect(shell, contains('Continua con Google'));
    expect(account, isNot(contains('Crea account')));
    expect(account, isNot(contains('passwordController')));
  });

  test('invite v2 is reusable until expiry and only rotates explicitly', () {
    final migration = File(
      'supabase/migrations/016_persistent_multi_member_invites_v041.sql',
    ).readAsStringSync();

    expect(migration, contains("now() + interval '24 hours'"));
    expect(migration, contains('p_force_new boolean default false'));
    expect(
      migration,
      contains('and revoked_at is null'),
    );
    expect(
      migration,
      isNot(contains('set consumed_at = now()')),
    );
    expect(
      migration,
      contains('on conflict (space_id, user_id) do nothing'),
    );
  });
}
