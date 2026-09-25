import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'app_version.dart';
import 'cloud_sync_service.dart';
import 'web_push_bridge_stub.dart'
    if (dart.library.html) 'web_push_bridge_web.dart' as bridge;

class WebPushHealth {
  final bool supported;
  final bool secureContext;
  final bool installedPwa;
  final bool isIos;
  final String permissionStatus;
  final bool subscribed;
  final bool backendRegistered;
  final String? endpoint;
  final String? lastError;

  const WebPushHealth({
    required this.supported,
    required this.secureContext,
    required this.installedPwa,
    required this.isIos,
    required this.permissionStatus,
    required this.subscribed,
    required this.backendRegistered,
    required this.endpoint,
    this.lastError,
  });

  bool get permissionGranted => permissionStatus == 'granted';

  bool get ready =>
      supported &&
      secureContext &&
      permissionGranted &&
      subscribed &&
      backendRegistered &&
      (!isIos || installedPwa);
}

class WebPushService extends ChangeNotifier {
  WebPushService._();

  static final WebPushService instance = WebPushService._();

  bool _initialized = false;
  String? _lastError;
  WebPushHealth? _lastHealth;

  WebPushHealth? get lastHealth => _lastHealth;
  bool get configured => kIsWeb;

  Future<void> initialize({bool force = false}) async {
    if (!kIsWeb) return;
    if (_initialized && !force) return;

    _initialized = true;
    _lastError = null;

    try {
      final decoded = _decodeMap(await bridge.webPushHealthJson());
      final subscription = _subscription(decoded);
      if (subscription != null && CloudSyncService.instance.signedIn) {
        await _registerSubscription(subscription);
      }
    } catch (error) {
      _lastError = error.toString();
    }

    await health();
  }

  Future<WebPushHealth> health() async {
    if (!kIsWeb) {
      return const WebPushHealth(
        supported: false,
        secureContext: false,
        installedPwa: false,
        isIos: false,
        permissionStatus: 'unsupported',
        subscribed: false,
        backendRegistered: false,
        endpoint: null,
      );
    }

    Map<String, dynamic> decoded = const {};
    try {
      decoded = _decodeMap(await bridge.webPushHealthJson());
    } catch (error) {
      _lastError = error.toString();
    }

    final subscription = _subscription(decoded);
    final endpoint = subscription?['endpoint']?.toString();
    var backendRegistered = false;

    if (endpoint != null &&
        endpoint.isNotEmpty &&
        CloudSyncService.instance.signedIn) {
      try {
        backendRegistered =
            await CloudSyncService.instance.isWebPushSubscriptionRegistered(
          endpoint,
        );
      } catch (error) {
        _lastError = error.toString();
      }
    }

    final result = WebPushHealth(
      supported: decoded['supported'] == true,
      secureContext: decoded['secureContext'] == true,
      installedPwa: decoded['installedPwa'] == true,
      isIos: decoded['isIos'] == true,
      permissionStatus: decoded['permission']?.toString() ?? 'unknown',
      subscribed: endpoint?.isNotEmpty == true,
      backendRegistered: backendRegistered,
      endpoint: endpoint,
      lastError: _lastError ?? decoded['error']?.toString(),
    );
    _lastHealth = result;
    notifyListeners();
    return result;
  }

  Future<WebPushHealth> enable() async {
    if (!kIsWeb) return health();
    if (!CloudSyncService.instance.signedIn) {
      _lastError = 'cloud_sign_in_required';
      return health();
    }

    try {
      final publicKey =
          await CloudSyncService.instance.getWebPushPublicKey();
      final result = _decodeMap(
        await bridge.webPushSubscribeJson(publicKey),
      );
      if (result['ok'] != true) {
        throw StateError(
          result['error']?.toString() ?? 'web_push_subscription_failed',
        );
      }

      final subscription = _subscription(result);
      if (subscription == null) {
        throw StateError('web_push_subscription_missing');
      }
      await _registerSubscription(subscription);
      _lastError = null;
    } catch (error) {
      _lastError = error.toString();
    }

    return health();
  }

  Future<WebPushHealth> disable() async {
    if (!kIsWeb) return health();

    try {
      final result = _decodeMap(
        await bridge.webPushUnsubscribeJson(),
      );
      final endpoint = result['endpoint']?.toString();
      if (endpoint != null &&
          endpoint.isNotEmpty &&
          CloudSyncService.instance.signedIn) {
        await CloudSyncService.instance
            .unregisterWebPushSubscription(endpoint);
      }
      _lastError = null;
    } catch (error) {
      _lastError = error.toString();
    }
    return health();
  }

  Future<Map<String, dynamic>> sendSelfTest() async {
    if (!kIsWeb) {
      throw StateError('web_push_not_supported');
    }
    if (!CloudSyncService.instance.signedIn) {
      throw StateError('cloud_sign_in_required');
    }

    final status = await enable();
    if (!status.ready) {
      throw StateError(status.lastError ?? 'web_push_not_ready');
    }

    return CloudSyncService.instance.sendPushSelfTest(
      eventId:
          'web-self-test:${DateTime.now().toUtc().microsecondsSinceEpoch}',
    );
  }

  Future<String?> takeInitialSpaceId() async {
    if (!kIsWeb) return null;
    try {
      final decoded = _decodeMap(
        await bridge.webPushTakeInitialSpaceJson(),
      );
      final value = decoded['spaceId']?.toString().trim();
      return value == null || value.isEmpty ? null : value;
    } catch (_) {
      return null;
    }
  }

  Future<void> _registerSubscription(
    Map<String, dynamic> subscription,
  ) async {
    final endpoint = subscription['endpoint']?.toString().trim() ?? '';
    final keys = subscription['keys'] is Map
        ? Map<String, dynamic>.from(subscription['keys'] as Map)
        : <String, dynamic>{};
    final p256dh = keys['p256dh']?.toString().trim() ?? '';
    final auth = keys['auth']?.toString().trim() ?? '';

    if (endpoint.isEmpty || p256dh.isEmpty || auth.isEmpty) {
      throw StateError('invalid_web_push_subscription');
    }

    await CloudSyncService.instance.registerWebPushSubscription(
      endpoint: endpoint,
      p256dh: p256dh,
      auth: auth,
      appVersion: appReleaseVersion,
    );
  }

  static Map<String, dynamic> _decodeMap(String raw) {
    final decoded = jsonDecode(raw);
    return decoded is Map
        ? Map<String, dynamic>.from(decoded)
        : <String, dynamic>{};
  }

  static Map<String, dynamic>? _subscription(
    Map<String, dynamic> decoded,
  ) {
    final value = decoded['subscription'];
    if (value is! Map) return null;
    return Map<String, dynamic>.from(value);
  }
}
