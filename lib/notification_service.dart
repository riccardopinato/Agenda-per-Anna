import 'dart:async';

import 'package:flutter/foundation.dart';

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
  String? _initialPayload;
  final StreamController<String> _tapController =
      StreamController<String>.broadcast();

  bool get available => _available;
  Stream<String> get notificationTapStream => _tapController.stream;

  String? takeInitialPayload() {
    final payload = _initialPayload;
    _initialPayload = null;
    return payload;
  }

  Future<bool> _initializePlugin(
    AndroidInitializationSettings android,
  ) async {
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    final settings = InitializationSettings(
      android: android,
      iOS: darwin,
      macOS: darwin,
    );

    try {
      final launchDetails = await _plugin.getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp == true) {
        final payload = launchDetails?.notificationResponse?.payload?.trim();
        if (payload != null && payload.isNotEmpty) {
          _initialPayload = payload;
        }
      }
    } catch (_) {
      // Il recupero del tap iniziale è accessorio e non deve impedire
      // l'inizializzazione del plugin.
    }

    final initialized = await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload?.trim();
        if (payload != null && payload.isNotEmpty) {
          _tapController.add(payload);
        }
      },
    );
    return initialized != false;
  }

  Future<void> initialize({bool force = false}) async {
    if (_initialized && !force) return;

    _available = true;
    tz_data.initializeTimeZones();

    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // La schedulazione continua comunque a funzionare con il timezone locale
      // disponibile al runtime.
    }

    var initialized = false;
    try {
      initialized = await _initializePlugin(
        const AndroidInitializationSettings('notification_icon'),
      );
    } catch (_) {
      initialized = false;
    }

    if (!initialized &&
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android) {
      try {
        initialized = await _initializePlugin(
          const AndroidInitializationSettings('@mipmap/ic_launcher'),
        );
      } catch (_) {
        initialized = false;
      }
    }

    if (!initialized) {
      _initialized = false;
      _available = false;
      return;
    }

    _initialized = true;
    _available = true;

    try {
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
    } catch (_) {
      // La creazione/lettura di un singolo canale non deve disabilitare
      // l'intero servizio. Android può ricrearlo al primo show().
    }
  }

  Future<bool> requestPermissions({
    bool requestExactAlarm = false,
  }) async {
    await initialize(force: !_initialized || !_available);
    if (!_available) return false;

    var granted = true;

    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final result = await android?.requestNotificationsPermission();
      if (result != null) granted = result;

      if (requestExactAlarm) {
        final exact = await android?.canScheduleExactNotifications();
        if (exact == false) {
          await android?.requestExactAlarmsPermission();
        }
      }
    } catch (_) {}

    try {
      final result = await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      if (result != null) granted = granted && result;
    } catch (_) {}

    try {
      final result = await _plugin
          .resolvePlatformSpecificImplementation<
              WebFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      if (result != null) granted = granted && result;
    } catch (_) {}

    return granted;
  }

  Future<NotificationHealth> health() async {
    await initialize(force: !_initialized || !_available);
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
    await initialize(force: !_initialized || !_available);
    try {
      await _plugin.openAppNotificationSettings();
    } catch (_) {
      // Non bloccare la UI: alcuni OEM possono rifiutare temporaneamente
      // l'intent delle impostazioni.
    }
  }

  Future<void> showTestNotification() async {
    await initialize(force: !_initialized || !_available);
    if (!_available) {
      throw StateError('notification_service_unavailable');
    }
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
