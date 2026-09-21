import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _available = true;
  bool _permissionsRequested = false;

  Future<void> initialize() async {
    if (_initialized || !_available) return;

    tz_data.initializeTimeZones();

    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // timezone.local resta UTC se il device/browser non restituisce un ID valido.
    }

    const android = AndroidInitializationSettings('launcher_icon');
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
      await _plugin.initialize(settings: settings);
      _initialized = true;
    } catch (_) {
      _available = false;
    }
  }

  Future<void> requestPermissions() async {
    await initialize();
    if (!_available || _permissionsRequested) return;
    _permissionsRequested = true;

    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (_) {}

    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } catch (_) {}

    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
              WebFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (_) {}
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

    await requestPermissions();

    final id = _notificationId(stableId);
    final scheduled = tz.TZDateTime.from(when, tz.local);

    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduled,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'agenda_reminders',
            'Promemoria Agenda',
            channelDescription: 'Promemoria per appuntamenti e cose da fare',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
          macOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: stableId,
      );
    } catch (_) {
      // Alcuni browser non supportano la schedulazione futura: il salvataggio
      // dell'evento deve comunque riuscire senza bloccare l'app.
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
