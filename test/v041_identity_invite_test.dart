import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:agenda_per_anna/cloud_sync_service.dart';

void main() {
  test('persistent invite details preserve server expiry and reuse count', () {
    final invite = SpaceInviteDetails.fromJson({
      'code': 'a1b2c3d4',
      'expires_at': '2026-09-25T12:00:00Z',
      'created_at': '2026-09-24T12:00:00Z',
      'uses_count': 3,
    });

    expect(invite.code, 'A1B2C3D4');
    expect(invite.expiresAt.toUtc(), DateTime.utc(2026, 9, 25, 12));
    expect(invite.usesCount, 3);
    expect(invite.toJson()['code'], 'A1B2C3D4');
  });

  test('v0.41 keeps a server-owned 24h multi-use invite contract', () {
    final migration = File(
      'supabase/migrations/016_universal_identity_invites_v041.sql',
    ).readAsStringSync();

    expect(migration, contains("now() + interval '24 hours'"));
    expect(migration, contains('code_value text'));
    expect(migration, contains('create_or_get_space_invite'));
    expect(migration, contains('regenerate_space_invite'));
    expect(migration, contains('uses_count = uses_count + 1'));
    expect(migration, contains('for update;'));
    expect(migration, contains('get diagnostics v_inserted = row_count'));
    expect(
      migration,
      isNot(contains('set consumed_at = now()')),
    );
  });

  test('identity is global and Noi no longer owns an auth form', () {
    final identity =
        File('lib/src/screens/universal_identity.dart').readAsStringSync();
    final shared =
        File('lib/src/screens/shared_space.dart').readAsStringSync();
    final cloud =
        File('lib/cloud_sync_service.dart').readAsStringSync();

    expect(identity, contains('Continua con Google'));
    expect(identity, contains('Ho già un account email/password'));
    expect(cloud, contains('signInWithGoogle'));
    expect(cloud, contains('LaunchMode.externalApplication'));
    expect(
      cloud,
      contains('https://riccardopinato.github.io/Agenda-per-Anna/'),
    );

    expect(shared, contains('Non esiste più un login separato qui.'));
    expect(shared, isNot(contains('Account e sincronizzazione')));
  });

  test('Android release scaffold contains the Supabase OAuth callback', () {
    final prepare =
        File('tool/prepare_android_platform.py').readAsStringSync();
    final appLab =
        File('.github/workflows/applab.yml').readAsStringSync();

    expect(prepare, contains('io.supabase.annasdiary'));
    expect(prepare, contains('login-callback'));
    expect(
      appLab,
      contains('--dart-define=ANNAS_DIARY_INTEGRATION_TEST=true'),
    );
  });
}
