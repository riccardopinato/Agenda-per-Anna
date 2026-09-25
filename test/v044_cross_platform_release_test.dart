import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:agenda_per_anna/web_push_service.dart';

void main() {
  group('v0.44 cross-platform notification and release hardening', () {
    test('iOS PWA readiness requires Home Screen installation', () {
      const installed = WebPushHealth(
        supported: true,
        secureContext: true,
        installedPwa: true,
        isIos: true,
        permissionStatus: 'granted',
        subscribed: true,
        backendRegistered: true,
        endpoint: 'https://push.example/subscription',
      );
      expect(installed.ready, isTrue);

      const safariTabOnly = WebPushHealth(
        supported: true,
        secureContext: true,
        installedPwa: false,
        isIos: true,
        permissionStatus: 'granted',
        subscribed: true,
        backendRegistered: true,
        endpoint: 'https://push.example/subscription',
      );
      expect(safariTabOnly.ready, isFalse);
    });

    test('desktop Web Push does not require standalone PWA mode', () {
      const desktop = WebPushHealth(
        supported: true,
        secureContext: true,
        installedPwa: false,
        isIos: false,
        permissionStatus: 'granted',
        subscribed: true,
        backendRegistered: true,
        endpoint: 'https://push.example/subscription',
      );
      expect(desktop.ready, isTrue);
    });

    test('Web Push backend keeps private VAPID material server-side', () {
      final migration =
          File('supabase/migrations/019_web_push_pwa_v044.sql')
              .readAsStringSync();
      final reminderMigration =
          File('supabase/migrations/020_web_push_reminders_v044.sql')
              .readAsStringSync();
      final cronHardening =
          File('supabase/migrations/021_web_push_cron_hardening_v044.sql')
              .readAsStringSync();
      final configDeny =
          File('supabase/migrations/022_web_push_config_explicit_deny_v044.sql')
              .readAsStringSync();
      final edge = File(
        'supabase/functions/send-shared-push/index.ts',
      ).readAsStringSync();
      final config = File('supabase/config.toml').readAsStringSync();

      expect(migration, contains('web_push_subscriptions'));
      expect(migration, contains('web_push_config'));
      expect(
        migration,
        contains(
          'revoke all on public.web_push_config from anon, authenticated',
        ),
      );
      expect(edge, contains('ensureWebPushConfig'));
      expect(edge, contains('npm:web-push@'));
      expect(edge, contains('web_push_public_key'));
      expect(edge, contains('web_subscription_count'));
      expect(reminderMigration, contains('web_push_reminders'));
      expect(reminderMigration, contains('cron.schedule'));
      expect(reminderMigration, contains('x-cron-token'));
      expect(cronHardening, contains('cron_token set not null'));
      expect(configDeny, contains('web_push_config_deny_clients'));
      expect(configDeny, contains('using (false)'));
      expect(configDeny, contains('with check (false)'));
      expect(edge, contains('send_due_web_reminders'));
      expect(edge, contains('processDueWebReminders'));
      expect(config, contains('verify_jwt = false'));
    });

    test('Flutter PWA service worker owns both offline cache and Push', () {
      final bridge =
          File('web_push/annas-diary-push.js').readAsStringSync();
      final handlers =
          File('web_push/annas-diary-push-sw.js').readAsStringSync();
      final finalizer =
          File('tool/finalize_web_build.py').readAsStringSync();

      expect(
        bridge,
        contains('flutter_service_worker.js'),
      );
      expect(
        bridge,
        isNot(contains('register(\n        "annas-diary-push-sw.js"')),
      );
      expect(handlers, contains('self.addEventListener("push"'));
      expect(handlers, contains('notificationclick'));
      expect(finalizer, contains('flutter_service_worker.js'));
      expect(finalizer, contains('annas-diary-push-v044'));
    });

    test('direct sideload build uses protected stable signing secrets', () {
      final workflow =
          File('.github/workflows/sideload-arm64.yml').readAsStringSync();

      expect(workflow, contains(r'${{ secrets.ANDROID_KEYSTORE_BASE64 }}'));
      expect(workflow, contains(r'${{ secrets.ANDROID_KEYSTORE_PASSWORD }}'));
      expect(workflow, isNot(contains('keytool -genkeypair')));
      expect(workflow, isNot(contains('annas-diary-sideload')));
      expect(
        workflow,
        contains('prepare_android_platform.py --release-signing'),
      );
    });

    test('Pages release includes PWA Push and public legal pages', () {
      final workflow =
          File('.github/workflows/deploy-pages.yml').readAsStringSync();
      final privacy = File('legal/privacy.html').readAsStringSync();
      final terms = File('legal/terms.html').readAsStringSync();

      expect(workflow, contains('prepare_web_platform.py'));
      expect(workflow, contains('finalize_web_build.py'));
      expect(workflow, contains('cp legal/privacy.html'));
      expect(workflow, contains('cp legal/terms.html'));
      expect(privacy, contains('Web Push'));
      expect(privacy, contains('promemoria PWA'));
      expect(terms, contains('Termini di servizio'));
    });
  });
}
