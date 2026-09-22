import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cloud_sync_service.dart';
import 'notification_service.dart';

typedef SharedPushReceivedCallback = Future<void> Function(
  String spaceId,
  String eventId,
);
typedef SharedPushOpenedCallback = Future<void> Function(String spaceId);

@pragma('vm:entry-point')
Future<void> annasDiaryFirebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  if (!PushNotificationService.firebaseEnabled) return;
  await Firebase.initializeApp();
  await PushNotificationService.persistBackgroundSharedMessage(message);
}

class PushNotificationHealth {
  final bool configured;
  final bool initialized;
  final bool permissionGranted;
  final String permissionStatus;
  final bool tokenAvailable;
  final bool deviceRegistered;
  final bool remotePushActive;
  final bool signedIn;
  final String? lastError;

  const PushNotificationHealth({
    required this.configured,
    required this.initialized,
    required this.permissionGranted,
    required this.permissionStatus,
    required this.tokenAvailable,
    required this.deviceRegistered,
    required this.remotePushActive,
    required this.signedIn,
    this.lastError,
  });
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance =
      PushNotificationService._();

  static const bool firebaseEnabled = bool.fromEnvironment(
    'FIREBASE_ENABLED',
    defaultValue: false,
  );

  static const String _pendingEventsKey =
      'annas_diary_pending_shared_push_events_v1';
  static const String _seenEventsKey =
      'annas_diary_seen_shared_push_events_v1';

  bool _initialized = false;
  bool _remotePushActive = false;
  String? _lastError;
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _messageSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  StreamSubscription<String>? _localTapSubscription;
  SharedPushReceivedCallback? _onSharedPushReceived;
  SharedPushOpenedCallback? _onSharedPushOpened;

  bool get configured =>
      firebaseEnabled &&
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android;

  bool get remotePushActive => _remotePushActive;

  static void configureBackgroundHandling() {
    if (!firebaseEnabled || kIsWeb) return;
    if (defaultTargetPlatform != TargetPlatform.android) return;
    FirebaseMessaging.onBackgroundMessage(
      annasDiaryFirebaseMessagingBackgroundHandler,
    );
  }

  static Future<void> persistBackgroundSharedMessage(
    RemoteMessage message,
  ) async {
    if (message.data['kind'] != 'shared_update') return;
    final spaceId = message.data['space_id']?.toString().trim();
    if (spaceId == null || spaceId.isEmpty) return;

    final eventId = _eventIdFor(message, spaceId);
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getStringList(_pendingEventsKey) ?? <String>[];

    bool alreadyQueued = false;
    for (final raw in pending) {
      try {
        final decoded = Map<String, dynamic>.from(jsonDecode(raw) as Map);
        if (decoded['event_id']?.toString() == eventId) {
          alreadyQueued = true;
          break;
        }
      } catch (_) {}
    }
    if (alreadyQueued) return;

    pending.add(
      jsonEncode({
        'space_id': spaceId,
        'event_id': eventId,
      }),
    );
    if (pending.length > 100) {
      pending.removeRange(0, pending.length - 100);
    }
    await prefs.setStringList(_pendingEventsKey, pending);
  }

  Future<void> initialize({
    SharedPushReceivedCallback? onSharedPushReceived,
    SharedPushOpenedCallback? onSharedPushOpened,
  }) async {
    if (onSharedPushReceived != null) {
      _onSharedPushReceived = onSharedPushReceived;
    }
    if (onSharedPushOpened != null) {
      _onSharedPushOpened = onSharedPushOpened;
    }

    if (_initialized || !configured) return;

    try {
      _lastError = null;
      await Firebase.initializeApp();
      await FirebaseMessaging.instance.setAutoInitEnabled(true);
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      _tokenSubscription =
          FirebaseMessaging.instance.onTokenRefresh.listen((token) {
        unawaited(_registerToken(token));
      });

      _messageSubscription = FirebaseMessaging.onMessage.listen((message) {
        unawaited(_handleForegroundMessage(message));
      });

      _openedSubscription =
          FirebaseMessaging.onMessageOpenedApp.listen((message) {
        unawaited(_handleOpenedMessage(message));
      });

      _localTapSubscription =
          NotificationService.instance.notificationTapStream.listen((payload) {
        unawaited(_handleLocalNotificationTap(payload));
      });

      _initialized = true;

      await _drainBackgroundEvents();

      final localInitialPayload =
          NotificationService.instance.takeInitialPayload();
      if (localInitialPayload != null) {
        await _handleLocalNotificationTap(localInitialPayload);
      }

      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        await _handleOpenedMessage(initialMessage);
      }

      await registerCurrentToken();
    } catch (error) {
      _lastError = error.toString();
      _remotePushActive = false;
    }
  }

  Future<void> registerCurrentToken() async {
    if (!configured) return;
    if (!_initialized) {
      await initialize();
      return;
    }
    if (!CloudSyncService.instance.signedIn) {
      _remotePushActive = false;
      return;
    }

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) {
        _remotePushActive = false;
        return;
      }
      await _registerToken(token);
    } catch (error) {
      _lastError = error.toString();
      _remotePushActive = false;
    }
  }

  Future<void> _registerToken(String token) async {
    if (!CloudSyncService.instance.signedIn) {
      _remotePushActive = false;
      return;
    }
    try {
      await CloudSyncService.instance.registerPushDevice(
        token: token,
        platform: 'android',
        appVersion: '0.31.0',
      );
      _remotePushActive = true;
    } catch (error) {
      _lastError = error.toString();
      _remotePushActive = false;
    }
  }

  Future<PushNotificationHealth> health() async {
    if (!configured) {
      return PushNotificationHealth(
        configured: false,
        initialized: _initialized,
        permissionGranted: false,
        permissionStatus: 'non configurato',
        tokenAvailable: false,
        deviceRegistered: false,
        remotePushActive: false,
        signedIn: CloudSyncService.instance.signedIn,
        lastError: _lastError,
      );
    }

    if (!_initialized) {
      await initialize();
    }

    var permissionStatus = 'sconosciuto';
    var permissionGranted = false;
    String? token;
    var registered = false;

    try {
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      permissionStatus = settings.authorizationStatus.name;
      permissionGranted =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus ==
                  AuthorizationStatus.provisional;
    } catch (error) {
      _lastError = error.toString();
    }

    try {
      token = await FirebaseMessaging.instance.getToken();
      if (token != null &&
          token.isNotEmpty &&
          CloudSyncService.instance.signedIn) {
        registered =
            await CloudSyncService.instance.isPushDeviceRegistered(token);
      }
    } catch (error) {
      _lastError = error.toString();
    }

    return PushNotificationHealth(
      configured: configured,
      initialized: _initialized,
      permissionGranted: permissionGranted,
      permissionStatus: permissionStatus,
      tokenAvailable: token?.isNotEmpty == true,
      deviceRegistered: registered,
      remotePushActive: _remotePushActive,
      signedIn: CloudSyncService.instance.signedIn,
      lastError: _lastError,
    );
  }

  Future<PushNotificationHealth> repair() async {
    if (!configured) return health();
    try {
      await Firebase.initializeApp();
    } catch (_) {}
    try {
      await FirebaseMessaging.instance.setAutoInitEnabled(true);
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (!_initialized) {
        await initialize();
      }
      await registerCurrentToken();
      _lastError = null;
    } catch (error) {
      _lastError = error.toString();
    }
    return health();
  }

  Future<Map<String, dynamic>> sendSelfTest() async {
    if (!configured) {
      throw StateError('firebase_not_configured');
    }
    if (!CloudSyncService.instance.signedIn) {
      throw StateError('cloud_sign_in_required');
    }

    await repair();
    final status = await health();
    if (!status.tokenAvailable || !status.deviceRegistered) {
      throw StateError('push_device_not_registered');
    }

    return CloudSyncService.instance.sendPushSelfTest(
      eventId:
          'self-test:${DateTime.now().toUtc().microsecondsSinceEpoch}',
    );
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (message.data['kind'] == 'push_self_test') {
      await NotificationService.instance.showPushSelfTestReceived();
      return;
    }

    final parsed = _parseSharedMessage(message);
    if (parsed == null) return;

    await _recordUnreadIfNeeded(
      spaceId: parsed.$1,
      eventId: parsed.$2,
    );

    await NotificationService.instance.showSharedUpdate(
      spaceId: parsed.$1,
      spaceName: 'Noi ♡',
    );
  }

  Future<void> _handleOpenedMessage(RemoteMessage message) async {
    final parsed = _parseSharedMessage(message);
    if (parsed == null) return;

    await _recordUnreadIfNeeded(
      spaceId: parsed.$1,
      eventId: parsed.$2,
    );
    await _onSharedPushOpened?.call(parsed.$1);
  }

  Future<void> _handleLocalNotificationTap(String payload) async {
    final value = payload.trim();
    if (!value.startsWith('shared:')) return;
    final spaceId = value.substring('shared:'.length).trim();
    if (spaceId.isEmpty) return;
    await _onSharedPushOpened?.call(spaceId);
  }

  Future<void> _drainBackgroundEvents() async {
    final callback = _onSharedPushReceived;
    if (callback == null) return;

    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getStringList(_pendingEventsKey) ?? <String>[];
    if (pending.isEmpty) return;

    await prefs.remove(_pendingEventsKey);

    for (final raw in pending) {
      try {
        final decoded = Map<String, dynamic>.from(jsonDecode(raw) as Map);
        final spaceId = decoded['space_id']?.toString().trim() ?? '';
        final eventId = decoded['event_id']?.toString().trim() ?? '';
        if (spaceId.isEmpty || eventId.isEmpty) continue;
        await _recordUnreadIfNeeded(
          spaceId: spaceId,
          eventId: eventId,
        );
      } catch (_) {}
    }
  }

  Future<void> _recordUnreadIfNeeded({
    required String spaceId,
    required String eventId,
  }) async {
    final callback = _onSharedPushReceived;
    if (callback == null) return;
    if (!await _claimEvent(eventId)) return;
    await callback(spaceId, eventId);
  }

  Future<bool> _claimEvent(String eventId) async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getStringList(_seenEventsKey) ?? <String>[];
    if (seen.contains(eventId)) return false;

    seen.add(eventId);
    if (seen.length > 200) {
      seen.removeRange(0, seen.length - 200);
    }
    await prefs.setStringList(_seenEventsKey, seen);
    return true;
  }

  static (String, String)? _parseSharedMessage(RemoteMessage message) {
    if (message.data['kind'] != 'shared_update') return null;
    final spaceId = message.data['space_id']?.toString().trim();
    if (spaceId == null || spaceId.isEmpty) return null;
    return (spaceId, _eventIdFor(message, spaceId));
  }

  static String _eventIdFor(RemoteMessage message, String spaceId) {
    final explicit = message.data['event_id']?.toString().trim();
    if (explicit != null && explicit.isNotEmpty) return explicit;

    final messageId = message.messageId?.trim();
    if (messageId != null && messageId.isNotEmpty) {
      return 'fcm:$messageId';
    }

    final sentAt = message.sentTime?.toUtc().toIso8601String() ??
        DateTime.now().toUtc().toIso8601String();
    return 'fallback:$spaceId:$sentAt';
  }

  Future<void> unregisterCurrentToken() async {
    if (!configured || !_initialized) {
      _remotePushActive = false;
      return;
    }

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null &&
          token.isNotEmpty &&
          CloudSyncService.instance.signedIn) {
        await CloudSyncService.instance.unregisterPushDevice(token);
      }
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {
      // Logout must not be blocked by push cleanup.
    } finally {
      _remotePushActive = false;
    }
  }

  Future<void> dispose() async {
    await _tokenSubscription?.cancel();
    await _messageSubscription?.cancel();
    await _openedSubscription?.cancel();
    await _localTapSubscription?.cancel();
    _tokenSubscription = null;
    _messageSubscription = null;
    _openedSubscription = null;
    _localTapSubscription = null;
    _initialized = false;
    _remotePushActive = false;
    _onSharedPushReceived = null;
    _onSharedPushOpened = null;
  }
}
