import 'dart:io';

import 'package:agenda_per_anna/app_version.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('v0.63 expands Sketchbook palette without changing sketch storage', () {
    final source =
        File('lib/src/diary/diary_sketchbook.dart').readAsStringSync();

    final palette = RegExp(
      r'static const _colors = <int>\[(.*?)\];',
      dotAll: true,
    ).firstMatch(source);
    expect(palette, isNotNull);
    expect(
      RegExp(r'0xFF[0-9A-F]{6}')
          .allMatches(palette!.group(1)!)
          .length,
      16,
    );

    expect(source, contains('static const _colorNames = <String>['));
    expect(source, contains('ListView.separated('));
    expect(source, contains("label: 'Colore "));
    expect(source, contains('DiarySketchStroke('));
    expect(source, contains('colorValue: stroke.colorValue'));
  });

  test('v0.63 reminders expose safe Android snooze actions', () {
    final notifications =
        File('lib/notification_service.dart').readAsStringSync();
    final android =
        File('tool/prepare_android_platform.py').readAsStringSync();

    expect(notifications, contains('agenda_reminder_v1'));
    expect(notifications, contains('reminder_done'));
    expect(notifications, contains('reminder_snooze_10'));
    expect(notifications, contains('reminder_snooze_60'));
    expect(notifications, contains('reminder_open'));
    expect(notifications, contains('AndroidNotificationAction('));
    expect(notifications, contains('showsUserInterface: false'));
    expect(
      notifications,
      contains(
        'onDidReceiveBackgroundNotificationResponse: '
        'notificationTapBackground',
      ),
    );
    expect(notifications, contains('actions: _reminderActions'));
    expect(notifications, contains('agendaActions ? _actionableReminderDetails'));
    expect(notifications, contains("return 'reminder_done:"));
    expect(
      notifications,
      contains('AndroidScheduleMode.inexactAllowWhileIdle'),
    );
    final store = File('lib/src/agenda_store.dart').readAsStringSync();
    final main = File('lib/main.dart').readAsStringSync();
    expect(store, contains('agendaActions: true'));
    expect(main, contains('_handleLocalReminderAction'));
    expect(main, contains('reminder_done:'));

    expect(
      android,
      contains(
        'com.dexterous.flutterlocalnotifications.ActionBroadcastReceiver',
      ),
    );
  });

  test('v0.63 release metadata is aligned', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(appReleaseVersion, '0.70.0');
    expect(pubspec, contains('version: 0.70.0+80'));
  });
}
