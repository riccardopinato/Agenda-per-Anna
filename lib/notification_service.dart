import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) async {
  await NotificationService.instance.handleNotificationResponse(
    response,
    background: true,
  );
}

class _ReminderActionPayload {
  static const String kind = 'agenda_reminder_v1';

  final String stableId;
  final String title;
  final String body;

  const _ReminderActionPayload({
    required this.stableId,
    required this.title,
    required this.body,
  });

  String encode() => jsonEncode({
        'kind': kind,
        'stableId': stableId,
        'title': title,
        'body': body,
      });

  static _ReminderActionPayload? tryParse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map || decoded['kind'] != kind) return null;
      final stableId = decoded['stableId']?.toString().trim() ?? '';
      final title = decoded['title']?.toString().trim() ?? '';
      final body = decoded['body']?.toString().trim() ?? '';
      if (stableId.isEmpty || title.isEmpty) return null;
      return _ReminderActionPayload(
        stableId: stableId,
        title: title,
        body: body,
      );
    } catch (_) {
      return null;
    }
  }
}

class NotificationLocalization {
  final String done;
  final String snooze10;
  final String snooze60;
  final String open;
  final String reminderChannelName;
  final String reminderChannelDescription;
  final String sharedChannelDescription;
  final String immediateTestBody;
  final String scheduledTestTitle;
  final String scheduledTestBody;
  final String pushTestTitle;
  final String pushTestBody;
  final String sharedTitleTemplate;
  final String sharedBody;
  final String snoozeHourBody;
  final String snoozeMinutesTemplate;

  const NotificationLocalization({
    required this.done,
    required this.snooze10,
    required this.snooze60,
    required this.open,
    required this.reminderChannelName,
    required this.reminderChannelDescription,
    required this.sharedChannelDescription,
    required this.immediateTestBody,
    required this.scheduledTestTitle,
    required this.scheduledTestBody,
    required this.pushTestTitle,
    required this.pushTestBody,
    required this.sharedTitleTemplate,
    required this.sharedBody,
    required this.snoozeHourBody,
    required this.snoozeMinutesTemplate,
  });

  static const english = NotificationLocalization(
    done: 'Done',
    snooze10: '10 min',
    snooze60: '1 hour',
    open: 'Open',
    reminderChannelName: 'Reminders',
    reminderChannelDescription:
        "Anna's Diary reminders for appointments and tasks",
    sharedChannelDescription:
        'News and updates from the shared Noi ♡ space',
    immediateTestBody: 'Immediate test: local notifications are active ♡',
    scheduledTestTitle: "Anna's Diary · Scheduled test",
    scheduledTestBody: 'The scheduled reminder arrived correctly ♡',
    pushTestTitle: "Anna's Diary · Push test",
    pushTestBody: 'Firebase push received correctly ♡',
    sharedTitleTemplate: 'New in {label}',
    sharedBody: 'There is a new shared update to read.',
    snoozeHourBody: 'Reminder postponed by 1 hour.',
    snoozeMinutesTemplate: 'Reminder postponed by {minutes} minutes.',
  );

  String sharedTitle(String label) =>
      sharedTitleTemplate.replaceAll('{label}', label);

  String snoozeMinutes(int minutes) =>
      snoozeMinutesTemplate.replaceAll('{minutes}', '$minutes');
}

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


  static const String reminderDoneActionId = 'reminder_done';
  static const String reminderSnooze10ActionId = 'reminder_snooze_10';
  static const String reminderSnooze60ActionId = 'reminder_snooze_60';
  static const String reminderOpenActionId = 'reminder_open';

  static const List<AndroidNotificationAction> _reminderActions =
      <AndroidNotificationAction>[
    AndroidNotificationAction(
      reminderDoneActionId,
      'Fatto',
      showsUserInterface: true,
      cancelNotification: true,
    ),
    AndroidNotificationAction(
      reminderSnooze10ActionId,
      '10 min',
      showsUserInterface: false,
      cancelNotification: true,
    ),
    AndroidNotificationAction(
      reminderSnooze60ActionId,
      '1 ora',
      showsUserInterface: false,
      cancelNotification: true,
    ),
    AndroidNotificationAction(
      reminderOpenActionId,
      'Apri',
      showsUserInterface: true,
      cancelNotification: true,
    ),
  ];

  static const NotificationDetails _standardReminderDetails =
      NotificationDetails(
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
  );

  static const NotificationDetails _actionableReminderDetails =
      NotificationDetails(
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
      actions: _reminderActions,
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
  );

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
        final response = launchDetails?.notificationResponse;
        if (response != null) {
          _initialPayload = _routingPayload(response);
        }
      }
    } catch (_) {
      // Il recupero del tap iniziale è accessorio e non deve impedire
      // l'inizializzazione del plugin.
    }

    final initialized = await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        unawaited(handleNotificationResponse(response));
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
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

  String? _routingPayload(NotificationResponse response) {
    final rawPayload = response.payload?.trim();
    final reminder = _ReminderActionPayload.tryParse(rawPayload);
    if (reminder != null && response.actionId == reminderDoneActionId) {
      return 'reminder_done:${reminder.stableId}';
    }
    if (reminder != null) return reminder.stableId;
    if (rawPayload == null || rawPayload.isEmpty) return null;
    return rawPayload;
  }

  Future<void> handleNotificationResponse(
    NotificationResponse response, {
    bool background = false,
  }) async {
    final rawPayload = response.payload?.trim();
    final reminder = _ReminderActionPayload.tryParse(rawPayload);
    final actionId = response.actionId;

    if (reminder != null) {
      if (actionId == reminderSnooze10ActionId) {
        await _snoozeReminder(reminder, const Duration(minutes: 10));
        return;
      }
      if (actionId == reminderSnooze60ActionId) {
        await _snoozeReminder(reminder, const Duration(hours: 1));
        return;
      }
    }

    if (!background) {
      final routed = _routingPayload(response);
      if (routed != null && routed.isNotEmpty) {
        _tapController.add(routed);
      }
    }
  }

  Future<void> _snoozeReminder(
    _ReminderActionPayload reminder,
    Duration delay,
  ) async {
    tz_data.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {}

    final minutes = delay.inMinutes;
    final body = minutes >= 60
        ? 'Promemoria posticipato di 1 ora.'
        : 'Promemoria posticipato di $minutes minuti.';
    final payload = _ReminderActionPayload(
      stableId: reminder.stableId,
      title: reminder.title,
      body: body,
    );

    try {
      await _plugin.zonedSchedule(
        id: _notificationId(reminder.stableId),
        title: reminder.title,
        body: body,
        scheduledDate: tz.TZDateTime.now(tz.local).add(delay),
        notificationDetails: _actionableReminderDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload.encode(),
      );
      _lastError = null;
    } catch (error) {
      _lastError = 'snooze:${reminder.stableId}: $error';
    }
  }

  Future<void> schedule({
    required String stableId,
    required String title,
    required String body,
    required DateTime when,
    bool requestPermission = true,
    bool agendaActions = false,
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

    final payload = _ReminderActionPayload(
      stableId: stableId,
      title: title,
      body: body,
    );

    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduled,
        notificationDetails:
            agendaActions ? _actionableReminderDetails : _standardReminderDetails,
        androidScheduleMode: mode,
        payload: agendaActions ? payload.encode() : stableId,
      );
      _lastError = null;
    } catch (error) {
      _lastError = 'schedule:$stableId: $error';
      // Il salvataggio dell'impegno non deve fallire se il sistema blocca
      // temporaneamente la schedulazione.
    }
  }

  Future<void> scheduleDaily({
    required String stableId,
    required String title,
    required String body,
    required int hour,
    required int minute,
    bool requestPermission = true,
  }) async {
    await initialize();
    if (!_available) return;

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

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour.clamp(0, 23),
      minute.clamp(0, 59),
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    try {
      await _plugin.zonedSchedule(
        id: _notificationId(stableId),
        title: title,
        body: body,
        scheduledDate: scheduled,
        notificationDetails: _standardReminderDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: stableId,
      );
      _lastError = null;
    } catch (error) {
      _lastError = 'schedule_daily:$stableId: $error';
    }
  }

  Future<void> cancel(String stableId) async {
    await initialize();
    if (!_available) return;
    try {
      await _plugin.cancel(id: _notificationId(stableId));
    } catch (_) {}
  }

  Future<void> cancelAll() async {
    await initialize();
    if (!_available) return;
    try {
      await _plugin.cancelAll();
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
