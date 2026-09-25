import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:agenda_per_anna/notification_service.dart';

void main() {
  group('v0.43 notification reliability', () {
    test('local readiness requires app permission and reminder channel', () {
      const ready = NotificationHealth(
        available: true,
        notificationsEnabled: true,
        exactAlarmsEnabled: true,
        reminderChannelEnabled: true,
        sharedChannelEnabled: true,
        pendingCount: 2,
      );
      expect(ready.reminderDeliveryReady, isTrue);
      expect(ready.sharedDeliveryReady, isTrue);

      const blockedChannel = NotificationHealth(
        available: true,
        notificationsEnabled: true,
        exactAlarmsEnabled: true,
        reminderChannelEnabled: false,
        sharedChannelEnabled: true,
        pendingCount: 0,
      );
      expect(blockedChannel.reminderDeliveryReady, isFalse);
      expect(blockedChannel.sharedDeliveryReady, isTrue);

      const blockedApp = NotificationHealth(
        available: true,
        notificationsEnabled: false,
        exactAlarmsEnabled: false,
        reminderChannelEnabled: true,
        sharedChannelEnabled: true,
        pendingCount: 0,
      );
      expect(blockedApp.reminderDeliveryReady, isFalse);
      expect(blockedApp.sharedDeliveryReady, isFalse);
    });

    test('diagnostic is successful only after immediate and scheduled paths', () {
      const health = NotificationHealth(
        available: true,
        notificationsEnabled: true,
        exactAlarmsEnabled: false,
        reminderChannelEnabled: true,
        sharedChannelEnabled: true,
        pendingCount: 1,
      );

      const success = LocalNotificationDiagnostic(
        permissionGranted: true,
        immediateShown: true,
        scheduledCreated: true,
        scheduledDelaySeconds: 12,
        health: health,
      );
      expect(success.ok, isTrue);

      const missingScheduled = LocalNotificationDiagnostic(
        permissionGranted: true,
        immediateShown: true,
        scheduledCreated: false,
        scheduledDelaySeconds: 12,
        health: health,
      );
      expect(missingScheduled.ok, isFalse);
    });

    test('Realtime fallback waits for actual push receipt, not token presence', () {
      final storeSource =
          File('lib/src/agenda_store.dart').readAsStringSync();
      final pushSource =
          File('lib/push_notification_service.dart').readAsStringSync();

      expect(
        storeSource,
        contains('_scheduleSharedNotificationFallback(space)'),
      );
      expect(
        storeSource,
        contains('push.hasRecentSharedPush(space.id)'),
      );
      expect(
        storeSource,
        isNot(contains(
          '!PushNotificationService.instance.remotePushActive',
        )),
      );
      expect(
        pushSource,
        contains('_lastSharedPushReceivedAt'),
      );
      expect(
        pushSource,
        contains('_hasRecentRealtimeFallback'),
      );
    });

    test('settings run a full local diagnostic and expose blocked channels', () {
      final settings =
          File('lib/src/screens/backup_settings.dart').readAsStringSync();
      expect(settings, contains('runLocalDiagnostic()'));
      expect(settings, contains('canale Promemoria: BLOCCATO'));
      expect(settings, contains('canale Noi ♡: BLOCCATO'));
      expect(settings, contains('Test locale completo'));
    });

    test('push backend records real delivery outcomes', () {
      final function = File(
        'supabase/functions/send-shared-push/index.ts',
      ).readAsStringSync();
      final migration = File(
        'supabase/migrations/018_push_delivery_observability_v043.sql',
      ).readAsStringSync();

      expect(function, contains('finalizeDeliveryEvent'));
      expect(function, contains('delivery_status'));
      expect(function, contains('delivered_count'));
      expect(function, contains('push_delivery_failed'));
      expect(migration, contains('device_count'));
      expect(migration, contains('failed_count'));
      expect(migration, contains('completed_at'));
    });
  });
}
