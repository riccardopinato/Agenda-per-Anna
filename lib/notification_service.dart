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
  final bool reminderChannelEnabled;
  final bool sharedChannelEnabled;
  final int pendingCount;
  final String? lastError;

  const NotificationHealth({
    required this.available,
    required this.notificationsEnabled,
    required this.exactAlarmsEnabled,
    required this.reminderChannelEnabled,
    required this.sharedChannelEnabled,
    required this.pendingCount,
    this.lastError,
  });

  bool get reminderDeliveryReady =>
      available && notificationsEnabled && reminderChannelEnabled;

  bool get sharedDeliveryReady =>
      available && notificationsEnabled && sharedChannelEnabled;
}

class LocalNotificationDiagnostic {
  final bool permissionGranted;
  final bool immediateShown;
  final bool scheduledCreated;
  final int scheduledDelaySeconds;
  final NotificationHealth health;
  final String? error;

  const LocalNotificationDiagnostic({
    required this.permissionGranted,
    required this.immediateShown,
    required this.scheduledCreated,
    required this.scheduledDelaySeconds,
    required this.health,
    this.error,
  });

  bool get ok =>
      permissionGranted &&
      immediateShown &&
      scheduledCreated &&
      health.reminderDeliveryReady;
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
  String? _lastError;
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
      _lastError = 'plugin_initialization_failed';
      return;
    }

    _initialized = true;
    _available = true;
    _lastError = null;

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
    } catch (error) {
      _lastError = 'permission_android: $error';
      granted = false;
    }

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
    } catch (error) {
      _lastError = 'permission_ios: $error';
      granted = false;
    }

    try {
      final result = await _plugin
          .resolvePlatformSpecificImplementation<
              WebFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      if (result != null) granted = granted && result;
    } catch (error) {
      _lastError = 'permission_web: $error';
      granted = false;
    }

    if (granted) _lastError = null;
    return granted;
  }

  Future<NotificationHealth> health() async {
    await initialize(force: !_initialized || !_available);
    if (!_available) {
      return NotificationHealth(
        available: false,
        notificationsEnabled: false,
        exactAlarmsEnabled: false,
        reminderChannelEnabled: false,
        sharedChannelEnabled: false,
        pendingCount: 0,
        lastError: _lastError,
      );
    }

    var enabled = true;
    var exact = true;
    final isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    var reminderChannelEnabled = !isAndroid;
    var sharedChannelEnabled = !isAndroid;
    var pending = 0;

    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final androidEnabled = await android?.areNotificationsEnabled();
      if (androidEnabled != null) enabled = androidEnabled;
      final androidExact = await android?.canScheduleExactNotifications();
      if (androidExact != null) exact = androidExact;

      final channels = await android?.getNotificationChannels();
      if (channels != null) {
        for (final channel in channels) {
          if (channel.id == reminderChannelId) {
            reminderChannelEnabled = channel.importance != Importance.none;
          } else if (channel.id == sharedChannelId) {
            sharedChannelEnabled = channel.importance != Importance.none;
          }
        }
      }
    } catch (error) {
      _lastError = 'health_android: $error';
    }

    try {
      pending = (await _plugin.pendingNotificationRequests()).length;
    } catch (error) {
      _lastError = 'pending_notifications: $error';
    }

    return NotificationHealth(
      available: true,
      notificationsEnabled: enabled,
      exactAlarmsEnabled: exact,
      reminderChannelEnabled: reminderChannelEnabled,
      sharedChannelEnabled: sharedChannelEnabled,
      pendingCount: pending,
      lastError: _lastError,
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

    final permissionGranted = await requestPermissions();
    final status = await health();
    if (!permissionGranted || !status.notificationsEnabled) {
      throw StateError('notification_permission_denied');
    }
    if (!status.reminderChannelEnabled) {
      throw StateError('reminder_channel_disabled');
    }

    try {
      await _plugin.show(
        id: _notificationId('annas-diary:test'),
        title: 'Anna\'s Diary',
        body: 'Test immediato: notifiche locali attive ♡',
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
        payload: 'test:local:immediate',
      );
      _lastError = null;
    } catch (error) {
      _lastError = 'local_show: $error';
      rethrow;
    }
  }

  Future<LocalNotificationDiagnostic> runLocalDiagnostic({
    Duration scheduledDelay = const Duration(seconds: 12),
  }) async {
    await initialize(force: true);
    final delaySeconds = scheduledDelay.inSeconds.clamp(5, 60).toInt();

    if (!_available) {
      final status = await health();
      return LocalNotificationDiagnostic(
        permissionGranted: false,
        immediateShown: false,
        scheduledCreated: false,
        scheduledDelaySeconds: delaySeconds,
        health: status,
        error: _lastError ?? 'notification_service_unavailable',
      );
    }

    final permissionGranted = await requestPermissions();
    var immediateShown = false;
    var scheduledCreated = false;
    String? diagnosticError;

    final before = await health();
    if (permissionGranted &&
        before.notificationsEnabled &&
        before.reminderChannelEnabled) {
      try {
        await showTestNotification();
        immediateShown = true;
      } catch (error) {
        diagnosticError = 'immediate: $error';
      }

      try {
        final when = DateTime.now().add(Duration(seconds: delaySeconds));
        final scheduled = tz.TZDateTime.from(when, tz.local);
        var mode = AndroidScheduleMode.inexactAllowWhileIdle;
        if (before.exactAlarmsEnabled) {
          mode = AndroidScheduleMode.exactAllowWhileIdle;
        }

        await _plugin.zonedSchedule(
          id: _notificationId('annas-diary:test:scheduled'),
          title: 'Anna\'s Diary · Test programmato',
          body: 'Il promemoria programmato è arrivato correttamente ♡',
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
          payload: 'test:local:scheduled',
        );
        scheduledCreated = true;
      } catch (error) {
        diagnosticError =
            diagnosticError == null
                ? 'scheduled: $error'
                : '$diagnosticError · scheduled: $error';
      }
    } else if (!permissionGranted || !before.notificationsEnabled) {
      diagnosticError = 'notification_permission_denied';
    } else if (!before.reminderChannelEnabled) {
      diagnosticError = 'reminder_channel_disabled';
    }

    if (diagnosticError != null) {
      _lastError = diagnosticError;
    } else {
      _lastError = null;
    }

    final after = await health();
    return LocalNotificationDiagnostic(
      permissionGranted: permissionGranted,
      immediateShown: immediateShown,
      scheduledCreated: scheduledCreated,
      scheduledDelaySeconds: delaySeconds,
      health: after,
      error: diagnosticError,
    );
  }

  Future<void> showPushSelfTestReceived() async {
    await initialize(force: !_initialized || !_available);
    if (!_available) return;
    final status = await health();
    if (!status.sharedDeliveryReady) {
      _lastError = 'shared_notification_channel_not_ready';
      return;
    }
    try {
      await _plugin.show(
        id: _notificationId(
          'annas-diary:fcm-test:${DateTime.now().millisecondsSinceEpoch}',
        ),
        title: 'Anna\'s Diary · Test push',
        body: 'Push Firebase ricevuta correttamente ♡',
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
            category: AndroidNotificationCategory.status,
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
        payload: 'test:fcm',
      );
      _lastError = null;
    } catch (error) {
      _lastError = 'push_test_show: $error';
    }
  }

  Future<void> showSharedUpdate({
    required String spaceId,
    String? spaceName,
  }) async {
    await initialize();
    if (!_available) return;

    final status = await health();
    if (!status.sharedDeliveryReady) return;

    final label =
        (spaceName ?? '').trim().isEmpty ? 'Noi ♡' : spaceName!.trim();

    try {
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
      _lastError = null;
    } catch (error) {
      _lastError = 'shared_show: $error';
    }
  }

  Future<void> schedule({
    required String stableId,
    required String title,
    required String body,
    required DateTime when,
    bool requestPermission = true,
  }) async {
    await initialize();
    if (!_available) return;

    if (!when.isAfter(DateTime.now())) {
      await cancel(stableId);
      return;
    }

    final enabled = requestPermission
        ? await requestPermissions()
        : (await health()).notificationsEnabled;
    if (!enabled) {
      _lastError = 'notification_permission_denied';
      return;
    }

    final status = await health();
    if (!status.reminderChannelEnabled) {
      _lastError = 'reminder_channel_disabled';
      return;
    }

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
      _lastError = null;
    } catch (error) {
      _lastError = 'schedule:$stableId: $error';
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
