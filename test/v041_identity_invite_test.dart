import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agenda_per_anna/cloud_sync_service.dart';
import 'package:agenda_per_anna/local_state_store.dart';
import 'package:agenda_per_anna/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await LocalStateStore.instance.resetForTesting();
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    await LocalStateStore.instance.resetForTesting();
  });

  test('first universal account claims legacy guest data exactly once', () async {
    final store = AgendaStore();
    await store.load();

    await store.addInboxEntry('Dato precedente al login');
    expect(store.activeAccountId, isNull);

    await store.activateCloudAccount('google-user-a');

    expect(store.activeAccountId, 'google-user-a');
    expect(
      store.inbox.map((entry) => entry.text),
      contains('Dato precedente al login'),
    );

    await store.activateCloudAccount(null);
    expect(store.inbox, isEmpty);

    await store.activateCloudAccount('google-user-a');
    expect(
      store.inbox.map((entry) => entry.text),
      contains('Dato precedente al login'),
    );

    store.dispose();
  });

  test('SpaceInvite exposes a bounded persistent 24h-style lifetime', () {
    final expires = DateTime.now().toUtc().add(const Duration(hours: 24));
    final invite = SpaceInvite.fromJson({
      'code': 'a1b2c3d4',
      'expires_at': expires.toIso8601String(),
      'reused': true,
    });

    expect(invite.code, 'A1B2C3D4');
    expect(invite.reused, isTrue);
    expect(invite.expired, isFalse);
    expect(invite.remaining().inHours, inInclusiveRange(23, 24));
  });

  test('v0.41 repository locks universal identity and persistent invite contract',
      () {
    final authGate =
        File('lib/src/auth/universal_auth_gate.dart').readAsStringSync();
    final cloud = File('lib/cloud_sync_service.dart').readAsStringSync();
    final account =
        File('lib/src/screens/cloud_account.dart').readAsStringSync();
    final shared =
        File('lib/src/screens/shared_space.dart').readAsStringSync();
    final android =
        File('tool/prepare_android_platform.py').readAsStringSync();
    final migration = File(
      'supabase/migrations/016_persistent_multi_member_invites_v041.sql',
    ).readAsStringSync();
    final appLab = File('.github/workflows/applab.yml').readAsStringSync();

    expect(authGate, contains('Continua con Google'));
    expect(authGate, contains('Hai già un account email/password?'));
    expect(authGate, contains("bool.fromEnvironment('FLUTTER_TEST')"));
    expect(cloud, contains('OAuthProvider.google'));
    expect(
      cloud,
      contains('com.riccardopinato.agenda_per_anna://login-callback/'),
    );

    expect(account, isNot(contains('Crea un nuovo account')));
    expect(shared, isNot(contains('Account e sincronizzazione')));
    expect(shared, contains('resta identico per 24 ore'));
    expect(shared, contains('forceNew: true'));

    expect(
      android,
      contains('android:scheme="com.riccardopinato.agenda_per_anna"'),
    );
    expect(android, contains('android:host="login-callback"'));

    expect(migration, contains('get_or_create_space_invite'));
    expect(migration, contains('code_value'));
    expect(migration, contains('revoked_at'));
    expect(migration, contains('multi-use for their full 24-hour TTL'));
    expect(
      migration,
      isNot(contains('set consumed_at = now()')),
    );

    expect(
      appLab,
      contains('ANNAS_DIARY_APPLAB_AUTH_BYPASS=true'),
    );
  });
}
