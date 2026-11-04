// STAGING ONLY — not imported by the production application.
// Two-phase mobile/Web orchestration. Google tokens and OAuth client secrets
// must remain on the Supabase staging backend, never on the device.
// Transport, current production Supabase session and browser are injected.
typedef GcalStageCurrentAuth = Future<GcalStageAppAuth?> Function();
typedef GcalStagePost = Future<GcalStageResponse> Function(
    String route, String productionJwt, Map<String, Object?> json);
typedef GcalStageBrowserOpen = Future<void> Function(Uri url);

class GcalStageAppAuth {
  final String accountId;
  final String accessToken;
  const GcalStageAppAuth(this.accountId, this.accessToken);
}

class GcalStageResponse {
  final int status;
  final Map<String, Object?> json;
  const GcalStageResponse(this.status, this.json);
}

enum GcalStageClientFault {
  authenticationRequired,
  alreadyPending,
  notPending,
  expired,
  accountChanged,
  malformedBackendResponse,
  failedToOpenBrowser,
  requestRejected,
  explicitConfirmationRequired,
  previewRequired,
  notConnected,
  alreadyRunning,
}

class GcalStageClientException implements Exception {
  final GcalStageClientFault kind;
  const GcalStageClientException(this.kind);
  // Never include user tokens, authorization URLs, codes or raw HTTP bodies.
  @override
  String toString() => 'Google Calendar staging: ${kind.name}';
}

class GcalStagePreview {
  final bool waiting;
  final String? googleSubject;
  final String? verifiedEmail;
  const GcalStagePreview._(this.waiting, this.googleSubject, this.verifiedEmail);
}

class GcalStageConnection {
  final String googleSubject;
  final String? verifiedEmail;
  const GcalStageConnection(this.googleSubject, this.verifiedEmail);
}

class GcalStageDisconnected {
  final bool locallyDisconnected;
  final bool? providerRevoked;
  const GcalStageDisconnected(this.locallyDisconnected, this.providerRevoked);
}

/// Does not persist a handle, token, email, or Google subject in local storage.
/// A crash/restart requires a new authorization attempt. The server owns
/// OAuth state, one-use code exchange, nonce validation and encrypted tokens.
class GcalTwoPhaseFlutterStagingClient {
  final GcalStageCurrentAuth currentAuth;
  final GcalStagePost post;
  final GcalStageBrowserOpen openBrowser;
  final DateTime Function() now;

  String? _pendingHandle;
  String? _ownerAccountId;
  DateTime? _expiry;
  String? _previewedSubject;
  String? _connectedSubject;
  List<GcalStageConnection> _knownConnections = const [];
  bool _busy = false;

  GcalTwoPhaseFlutterStagingClient({
    required this.currentAuth,
    required this.post,
    required this.openBrowser,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  bool get awaitingGoogleConsent => _pendingHandle != null;
  bool get hasPreviewedIdentity => _previewedSubject != null;
  bool get connectedThisSession => _connectedSubject != null;
  String? get connectedGoogleSubject => _connectedSubject;
  List<GcalStageConnection> get knownConnections =>
      List.unmodifiable(_knownConnections);

  void clearForAccountSwitch() {
    _pendingHandle = null;
    _ownerAccountId = null;
    _expiry = null;
    _previewedSubject = null;
    _connectedSubject = null;
    _knownConnections = const [];
  }

  Future<GcalStageAppAuth> _requireAuth() async {
    final auth = await currentAuth();
    if (auth == null ||
        auth.accountId.trim().isEmpty ||
        auth.accessToken.trim().isEmpty) {
      clearForAccountSwitch();
      throw const GcalStageClientException(
          GcalStageClientFault.authenticationRequired);
    }
    if (_ownerAccountId != null && _ownerAccountId != auth.accountId) {
      clearForAccountSwitch();
      throw const GcalStageClientException(GcalStageClientFault.accountChanged);
    }
    return auth;
  }

  Future<T> _serial<T>(Future<T> Function() action) async {
    if (_busy) {
      throw const GcalStageClientException(GcalStageClientFault.alreadyRunning);
    }
    _busy = true;
    try {
      return await action();
    } finally {
      _busy = false;
    }
  }

  Future<GcalStageResponse> _post(
      String route, GcalStageAppAuth auth, Map<String, Object?> body) async {
    try {
      final response = await post(route, auth.accessToken, body);
      if (response.status != 200) {
        throw const GcalStageClientException(GcalStageClientFault.requestRejected);
      }
      return response;
    } on GcalStageClientException {
      rethrow;
    } catch (_) {
      throw const GcalStageClientException(GcalStageClientFault.requestRejected);
    }
  }

  void _requirePending() {
    if (_pendingHandle == null || _expiry == null) {
      throw const GcalStageClientException(GcalStageClientFault.notPending);
    }
    if (!now().toUtc().isBefore(_expiry!.toUtc())) {
      _pendingHandle = null;
      _previewedSubject = null;
      _expiry = null;
      throw const GcalStageClientException(GcalStageClientFault.expired);
    }
  }

  Future<void> begin() => _serial(() async {
        if (_pendingHandle != null) {
          throw const GcalStageClientException(
              GcalStageClientFault.alreadyPending);
        }
        final auth = await _requireAuth();
        final response = await _post('/start', auth, const {});
        final rawUrl = response.json['authorizationUrl'];
        final rawHandle = response.json['handle'];
        final rawExpiry = response.json['expiresAt'];
        final authorizationUrl =
            rawUrl is String ? Uri.tryParse(rawUrl) : null;
        if (authorizationUrl == null ||
            authorizationUrl.scheme != 'https' ||
            authorizationUrl.host != 'accounts.google.com' ||
            authorizationUrl.path != '/o/oauth2/v2/auth' ||
            authorizationUrl.userInfo.isNotEmpty ||
            authorizationUrl.queryParameters['response_type'] != 'code' ||
            authorizationUrl.queryParameters['code_challenge_method'] != 'S256' ||
            rawHandle is! String ||
            !RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(rawHandle) ||
            rawExpiry is! int) {
          throw const GcalStageClientException(
              GcalStageClientFault.malformedBackendResponse);
        }
        final expiry =
            DateTime.fromMillisecondsSinceEpoch(rawExpiry * 1000, isUtc: true);
        final seconds = expiry.difference(now().toUtc()).inSeconds;
        if (seconds <= 0 || seconds > 900) {
          throw const GcalStageClientException(
              GcalStageClientFault.malformedBackendResponse);
        }
        _ownerAccountId = auth.accountId;
        _pendingHandle = rawHandle;
        _expiry = expiry;
        _previewedSubject = null;
        try {
          await openBrowser(authorizationUrl);
        } catch (_) {
          clearForAccountSwitch();
          throw const GcalStageClientException(
              GcalStageClientFault.failedToOpenBrowser);
        }
      });

  Future<GcalStagePreview> preview() => _serial(() async {
        final auth = await _requireAuth();
        _requirePending();
        final response = await _post(
            '/preview', auth, <String, Object?>{'handle': _pendingHandle});
        final status = response.json['status'];
        if (status == 'waiting') {
          _previewedSubject = null;
          return const GcalStagePreview._(true, null, null);
        }
        final subject = response.json['googleSubject'];
        final email = response.json['googleEmail'];
        if (status != 'awaiting_confirmation' ||
            subject is! String ||
            subject.isEmpty ||
            subject.length > 256 ||
            (email != null && email is! String)) {
          throw const GcalStageClientException(
              GcalStageClientFault.malformedBackendResponse);
        }
        _previewedSubject = subject;
        return GcalStagePreview._(false, subject, email as String?);
      });

  /// Rehydrates non-secret connection metadata after a process restart.
  /// The server verifies the current production session on every call.
  Future<List<GcalStageConnection>> recoverConnections() =>
      _serial(() async {
        final auth = await _requireAuth();
        if (_pendingHandle != null) {
          throw const GcalStageClientException(
              GcalStageClientFault.alreadyPending);
        }
        final response = await _post('/connections', auth, const {});
        final raw = response.json['connections'];
        if (raw is! List || raw.length > 10) {
          throw const GcalStageClientException(
              GcalStageClientFault.malformedBackendResponse);
        }
        final output = <GcalStageConnection>[];
        final seen = <String>{};
        for (final item in raw) {
          if (item is! Map ||
              item['googleSubject'] is! String ||
              (item['googleSubject'] as String).isEmpty ||
              (item['googleSubject'] as String).length > 256 ||
              item['googleEmail'] != null &&
                  (item['googleEmail'] is! String ||
                      (item['googleEmail'] as String).length > 320)) {
            throw const GcalStageClientException(
                GcalStageClientFault.malformedBackendResponse);
          }
          final subject = item['googleSubject'] as String;
          if (!seen.add(subject)) {
            throw const GcalStageClientException(
                GcalStageClientFault.malformedBackendResponse);
          }
          output.add(GcalStageConnection(
              subject, item['googleEmail'] as String?));
        }
        _ownerAccountId = auth.accountId;
        _knownConnections = List.unmodifiable(output);
        _connectedSubject =
            output.length == 1 ? output.first.googleSubject : null;
        return List.unmodifiable(output);
      });

  void selectConnection(String googleSubject) {
    if (!_knownConnections.any((link) => link.googleSubject == googleSubject)) {
      throw const GcalStageClientException(GcalStageClientFault.notConnected);
    }
    _connectedSubject = googleSubject;
  }

  Future<void> confirm({required bool explicitConfirmation}) =>
      _serial(() async {
        if (!explicitConfirmation) {
          throw const GcalStageClientException(
              GcalStageClientFault.explicitConfirmationRequired);
        }
        final auth = await _requireAuth();
        _requirePending();
        if (_previewedSubject == null) {
          throw const GcalStageClientException(
              GcalStageClientFault.previewRequired);
        }
        final response = await _post('/confirm', auth, <String, Object?>{
          'handle': _pendingHandle,
          'explicitConfirmation': true,
        });
        if (response.json['connected'] != true ||
            response.json['googleSubject'] != _previewedSubject) {
          throw const GcalStageClientException(
              GcalStageClientFault.malformedBackendResponse);
        }
        final subject = _previewedSubject;
        _pendingHandle = null;
        _expiry = null;
        _previewedSubject = null;
        _connectedSubject = subject;
      });

  Future<GcalStageDisconnected> disconnect(
          {required bool explicitConfirmation}) =>
      _serial(() async {
        if (!explicitConfirmation) {
          throw const GcalStageClientException(
              GcalStageClientFault.explicitConfirmationRequired);
        }
        final auth = await _requireAuth();
        final subject = _connectedSubject;
        if (subject == null) {
          throw const GcalStageClientException(
              GcalStageClientFault.notConnected);
        }
        final response = await _post('/disconnect', auth, <String, Object?>{
          'googleSubject': subject,
          'explicitConfirmation': true,
        });
        if (response.json['disconnected'] != true ||
            (response.json['providerRevoked'] != null &&
                response.json['providerRevoked'] is! bool)) {
          throw const GcalStageClientException(
              GcalStageClientFault.malformedBackendResponse);
        }
        final revoked = response.json['providerRevoked'] as bool?;
        clearForAccountSwitch();
        return GcalStageDisconnected(true, revoked);
      });
}
