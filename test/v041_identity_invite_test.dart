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

  test(
    'first universal account claims legacy guest data exactly once',
    () async {
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
    },
  );

  test('SpaceInvite exposes a bounded persistent 24h-style lifetime', () {
    final expires = DateTime.now().toUtc().add(const Duration(hours: 24));
    final invite = SpaceInvite.fromJson({
      'code': 'a1b2c3d4',
      'expires_at': expires.toIso8601String(),
      'reused': true,
      'uses_count': 2,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });

    expect(invite.code, 'A1B2C3D4');
    expect(invite.reused, isTrue);
    expect(invite.expired, isFalse);
    expect(invite.usesCount, 2);
    expect(invite.createdAt, isNotNull);
    expect(invite.remaining().inHours, inInclusiveRange(23, 24));
  });

  test(
    'v0.41 repository locks universal identity and persistent invite contract',
    () {
      final authGate = File(
        'lib/src/auth/universal_auth_gate.dart',
      ).readAsStringSync();
      final cloud = File('lib/cloud_sync_service.dart').readAsStringSync();
      final account = File(
        'lib/src/screens/cloud_account.dart',
      ).readAsStringSync();
      final shared = File(
        'lib/src/screens/shared_space.dart',
      ).readAsStringSync();
      final android = File(
        'tool/prepare_android_platform.py',
      ).readAsStringSync();
      final migration = File(
        'supabase/migrations/016_persistent_multi_member_invites_v041.sql',
      ).readAsStringSync();
      final identityMigration = File(
        'supabase/migrations/017_universal_identity_invites_v041.sql',
      ).readAsStringSync();
      final concurrencyMigration = File(
        'supabase/migrations/018_invite_concurrency_hardening_v041.sql',
      ).readAsStringSync();
      final appLab = File('.github/workflows/applab.yml').readAsStringSync();

      expect(authGate, contains('Continua con Google'));
      expect(authGate, contains('Hai già un account email/password?'));
      expect(authGate, contains('ANNAS_DIARY_APPLAB_AUTH_BYPASS'));
      expect(authGate, contains('final bool bypass;'));
      expect(cloud, contains('OAuthProvider.google'));
      expect(
        cloud,
        contains('com.riccardopinato.agendaperanna://login-callback/'),
      );

      expect(account, isNot(contains('Crea un nuovo account')));
      expect(shared, isNot(contains('Account e sincronizzazione')));
      expect(shared, contains('resta identico per 24 ore'));
      expect(shared, contains('forceNew: true'));

      expect(
        android,
        contains('android:scheme="com.riccardopinato.agendaperanna"'),
      );
      expect(android, contains('android:host="login-callback"'));

      expect(migration, contains('get_or_create_space_invite'));
      expect(migration, contains('code_value'));
      expect(migration, contains('revoked_at'));
      expect(migration, contains('multi-use for their full 24-hour TTL'));
      expect(migration, isNot(contains('set consumed_at = now()')));

      expect(identityMigration, contains('create_or_get_space_invite'));
      expect(identityMigration, contains('uses_count'));
      expect(identityMigration, contains('regenerate_space_invite'));
      expect(concurrencyMigration, contains('for update'));
      expect(
        concurrencyMigration,
        contains('get diagnostics v_inserted = row_count'),
      );
      expect(cloud, contains("'create_or_get_space_invite'"));
      expect(cloud, contains("'regenerate_space_invite'"));

      expect(appLab, contains('ANNAS_DIARY_APPLAB_AUTH_BYPASS=true'));
    },
  );
}
