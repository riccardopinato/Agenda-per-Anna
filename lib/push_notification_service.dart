import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'cloud_sync_service.dart';
import 'notification_service.dart';

@pragma('vm:entry-point')
Future<void> annasDiaryFirebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  if (!PushNotificationService.firebaseEnabled) return;
  await Firebase.initializeApp();
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance =
      PushNotificationService._();

  static const bool firebaseEnabled = bool.fromEnvironment(
    'FIREBASE_ENABLED',
    defaultValue: false,
  );

  bool _initialized = false;
  bool _remotePushActive = false;
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _messageSubscription;

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

  Future<void> initialize() async {
    if (_initialized || !configured) return;

    try {
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
        if (message.data['kind'] != 'shared_update') return;
        final spaceId = message.data['space_id']?.toString();
        if (spaceId == null || spaceId.isEmpty) return;
        unawaited(
          NotificationService.instance.showSharedUpdate(
            spaceId: spaceId,
            spaceName: 'Noi ♡',
          ),
        );
      });

      _initialized = true;
      await registerCurrentToken();
    } catch (_) {
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
    } catch (_) {
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
        appVersion: '0.21.1',
      );
      _remotePushActive = true;
    } catch (_) {
      _remotePushActive = false;
    }
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
    _tokenSubscription = null;
    _messageSubscription = null;
    _initialized = false;
    _remotePushActive = false;
  }
}
