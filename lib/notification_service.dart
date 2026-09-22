import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationHealth {
  final bool available;
  final bool notificationsEnabled;
  final bool exactAlarmsEnabled;
  final int pendingCount;

  const NotificationHealth({
    required this.available,
    required this.notificationsEnabled,
    required this.exactAlarmsEnabled,
    required this.pendingCount,
  });
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const String reminderChannelId = 'annas_diary_reminders_v2';
  static const String sharedChannelId = 'annas_diary_shared_v1';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _available = true;
  bool _permissionsRequested = false;

  bool get available => _available;

  Future<void> initialize() async {
    if (_initialized || !_available) return;

    tz_data.initializeTimeZones();

    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // TZDateTime.from() continua a rispettare l'istante del DateTime anche
      // se il device non espone un timezone IANA valido.
    }

    const android = AndroidInitializationSettings('notification_icon');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: android,
      iOS: darwin,
      macOS: darwin,
    );

    try {
      final initialized = await _plugin.initialize(settings: settings);
      if (initialized == false) {
        _available = false;
        return;
      }

      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          reminderChannelId,
          'Promemoria',
          description:
              'Promemoria di Anna\'s Diary per appuntamenti e cose da fare',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        ),
      );

      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          sharedChannelId,
          'Noi ♡',
          description:
              'Novità e aggiornamenti dello spazio condiviso Noi ♡',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        ),
      );

      _initialized = true;
    } catch (_) {
      _available = false;
    }
  }

  Future<bool> requestPermissions({
    bool requestExactAlarm = false,
  }) async {
    await initialize();
    if (!_available) return false;

    bool granted = true;

    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (!_permissionsRequested) {
        final result = await android?.requestNotificationsPermission();
        if (result != null) granted = result;
      }

      if (requestExactAlarm) {
        final exact = await android?.canScheduleExactNotifications();
        if (exact == false) {
          await android?.requestExactAlarmsPermission();
        }
      }
    } catch (_) {}

    try {
      if (!_permissionsRequested) {
        final result = await _plugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
        if (result != null) granted = granted && result;
      }
    } catch (_) {}

    try {
      if (!_permissionsRequested) {
        final result = await _plugin
            .resolvePlatformSpecificImplementation<
                WebFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
        if (result != null) granted = granted && result;
      }
    } catch (_) {}

    _permissionsRequested = true;
    return granted;
  }

  Future<NotificationHealth> health() async {
    await initialize();
    if (!_available) {
      return const NotificationHealth(
        available: false,
        notificationsEnabled: false,
        exactAlarmsEnabled: false,
        pendingCount: 0,
      );
    }

    var enabled = true;
    var exact = true;
    var pending = 0;

    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final androidEnabled = await android?.areNotificationsEnabled();
      if (androidEnabled != null) enabled = androidEnabled;
      final androidExact = await android?.canScheduleExactNotifications();
      if (androidExact != null) exact = androidExact;
    } catch (_) {}

    try {
      pending = (await _plugin.pendingNotificationRequests()).length;
    } catch (_) {}

    return NotificationHealth(
      available: true,
      notificationsEnabled: enabled,
      exactAlarmsEnabled: exact,
      pendingCount: pending,
    );
  }

  Future<void> openSystemSettings() async {
    await initialize();
    if (!_available) return;
    try {
      await _plugin.openAppNotificationSettings();
    } catch (_) {}
  }

  Future<void> showTestNotification() async {
    await initialize();
    if (!_available) return;
    await requestPermissions();

    await _plugin.show(
      id: _notificationId('annas-diary:test'),
      title: 'Anna\'s Diary',
      body: 'Le notifiche funzionano correttamente ♡',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          reminderChannelId,
          'Promemoria',
          channelDescription:
              'Promemoria di Anna\'s Diary per appuntamenti e cose da fare',
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          enableVibration: true,
          category: AndroidNotificationCategory.reminder,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        macOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'test',
    );
  }

  Future<void> showSharedUpdate({
    required String spaceId,
    String? spaceName,
  }) async {
    await initialize();
    if (!_available) return;

    final enabled = await requestPermissions();
    if (!enabled) return;

    final label =
        (spaceName ?? '').trim().isEmpty ? 'Noi ♡' : spaceName!.trim();

    await _plugin.show(
      id: _notificationId(
        'shared:$spaceId:${DateTime.now().millisecondsSinceEpoch ~/ 1000}',
      ),
      title: 'Novità in $label',
      body: 'C’è un nuovo aggiornamento condiviso da leggere.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          sharedChannelId,
          'Noi ♡',
          channelDescription:
              'Novità e aggiornamenti dello spazio condiviso Noi ♡',
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          enableVibration: true,
          category: AndroidNotificationCategory.message,
          color: Color(0xFFE84A7F),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        macOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'shared:$spaceId',
    );
  }

  Future<void> schedule({
    required String stableId,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    await initialize();
    if (!_available) return;

    if (!when.isAfter(DateTime.now())) {
      await cancel(stableId);
      return;
    }

    final enabled = await requestPermissions();
    if (!enabled) return;

    final id = _notificationId(stableId);
    final scheduled = tz.TZDateTime.from(when, tz.local);

    var mode = AndroidScheduleMode.inexactAllowWhileIdle;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final exact = await android?.canScheduleExactNotifications();
      if (exact == true) {
        mode = AndroidScheduleMode.exactAllowWhileIdle;
      }
    } catch (_) {}

    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduled,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            reminderChannelId,
            'Promemoria',
            channelDescription:
                'Promemoria di Anna\'s Diary per appuntamenti e cose da fare',
            importance: Importance.max,
            priority: Priority.max,
            playSound: true,
            enableVibration: true,
            category: AndroidNotificationCategory.reminder,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
          macOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: mode,
        payload: stableId,
      );
    } catch (_) {
      // Il salvataggio dell'impegno non deve fallire se il sistema blocca
      // temporaneamente la schedulazione.
    }
  }

  Future<void> cancel(String stableId) async {
    await initialize();
    if (!_available) return;
    try {
      await _plugin.cancel(id: _notificationId(stableId));
    } catch (_) {}
  }

  int _notificationId(String value) {
    var hash = 0;
    for (final code in value.codeUnits) {
      hash = 0x1fffffff & (hash * 31 + code);
    }
    return hash;
  }
}
