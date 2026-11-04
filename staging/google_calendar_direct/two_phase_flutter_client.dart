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

typedef GcalStageProbeServer = Future<GcalStageServerHealth> Function();

class GcalStageServerHealth {
  final String status;
  final bool googleOauthActive;
  const GcalStageServerHealth(this.status, this.googleOauthActive);
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
  networkUnavailable,
  requestTimedOut,
  invalidServerResponse,
  serverUnavailable,
  rateLimited,
  stagingLocked,
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

class GcalStageCalendar {
  final String id;
  final String name;
  final bool primary;
  final String accessRole;
  const GcalStageCalendar({
    required this.id,
    required this.name,
    required this.primary,
    required this.accessRole,
  });
}

class GcalStageEvent {
  final String calendarId;
  final String eventId;
  final String title;
  final DateTime start;
  final DateTime end; // All-day end is exclusive.
  final bool allDay;
  final String? recurringEventId;
  final String? iCalUid;

  const GcalStageEvent({
    required this.calendarId, required this.eventId, required this.title,
    required this.start, required this.end, required this.allDay,
    this.recurringEventId, this.iCalUid,
  });

  /// A stable unambiguous source key, never a canonical local diary ID.
  String get sourceKey => '${calendarId.length}:$calendarId:'
      '${eventId.length}:$eventId';
}

class GcalStageEventBatch {
  final List<GcalStageEvent> events;
  final bool truncated;
  const GcalStageEventBatch(this.events, this.truncated);
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
        // Only the server's exact, known kill-switch response means this
        // expected QA state; do not conflate it with network/auth failures.
        if (response.status == 503 &&
            response.json['error'] == 'STAGING_NOT_ACTIVATED') {
          throw const GcalStageClientException(
              GcalStageClientFault.stagingLocked);
        }
        if (response.status == 429) {
          throw const GcalStageClientException(GcalStageClientFault.rateLimited);
        }
        if (response.status >= 500) {
          throw const GcalStageClientException(
              GcalStageClientFault.serverUnavailable);
        }
        if (response.status == 401) {
          throw const GcalStageClientException(
              GcalStageClientFault.authenticationRequired);
        }
        throw const GcalStageClientException(
            GcalStageClientFault.requestRejected);
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

  /// Read-only Google Calendar inventory. Only the server receives
  /// provider tokens; no Android Calendar write permission is requested.
  Future<List<GcalStageCalendar>> readCalendars() =>
      _serial(() async {
        final auth = await _requireAuth();
        final subject = _connectedSubject;
        if (subject == null) {
          throw const GcalStageClientException(
              GcalStageClientFault.notConnected);
        }
        final response = await _post('/calendars', auth,
            <String, Object?>{'googleSubject': subject});
        if (response.json['readonly'] != true ||
            response.json['calendars'] is! List) {
          throw const GcalStageClientException(
              GcalStageClientFault.malformedBackendResponse);
        }
        final rows = response.json['calendars'] as List;
        if (rows.length > 25) {
          throw const GcalStageClientException(
              GcalStageClientFault.malformedBackendResponse);
        }
        final seen = <String>{};
        final calendars = <GcalStageCalendar>[];
        for (final row in rows) {
          if (row is! Map ||
              row['id'] is! String ||
              (row['id'] as String).isEmpty ||
              (row['id'] as String).length > 1024 ||
              row['name'] is! String ||
              (row['name'] as String).length > 300 ||
              row['primary'] is! bool ||
              row['accessRole'] is! String) {
            throw const GcalStageClientException(
                GcalStageClientFault.malformedBackendResponse);
          }
          final id = row['id'] as String;
          if (!seen.add(id)) {
            throw const GcalStageClientException(
                GcalStageClientFault.malformedBackendResponse);
          }
          calendars.add(GcalStageCalendar(
            id: id,
            name: row['name'] as String,
            primary: row['primary'] as bool,
            accessRole: row['accessRole'] as String,
          ));
        }
        return List.unmodifiable(calendars);
      });

  /// Explicit, ephemeral owner-only Google event read (maximum 32 days).
  /// No event data is persisted, synchronized or written to Google.
  Future<GcalStageEventBatch> readEvents({
    required String calendarId, required DateTime from, required DateTime until,
  }) => _serial(() async {
    final auth = await _requireAuth();
    final subject = _connectedSubject;
    if (subject == null) {
      throw const GcalStageClientException(GcalStageClientFault.notConnected);
    }
    final low = from.toUtc(), high = until.toUtc();
    if (calendarId.isEmpty || calendarId.length > 1024 ||
        !high.isAfter(low) ||
        high.difference(low) > const Duration(days: 32)) {
      throw const GcalStageClientException(
          GcalStageClientFault.malformedBackendResponse);
    }
    final startIso = low.toIso8601String();
    final endIso = high.toIso8601String();
    final response = await _post('/events', auth, {
      'googleSubject': subject,
      'calendarId': calendarId,
      'timeMin': startIso,
      'timeMax': endIso,
    });
    if (response.json['readonly'] != true ||
        response.json['calendarId'] != calendarId ||
        response.json['truncated'] is! bool ||
        response.json['windowStart'] != startIso ||
        response.json['windowEnd'] != endIso ||
        response.json['events'] is! List) {
      throw const GcalStageClientException(
          GcalStageClientFault.malformedBackendResponse);
    }
    final raw = response.json['events'] as List;
    if (raw.length > 60) {
      throw const GcalStageClientException(
          GcalStageClientFault.malformedBackendResponse);
    }
    final output = <GcalStageEvent>[];
    final seen = <String>{};
    for (final item in raw) {
      if (item is! Map ||
          item['eventId'] is! String ||
          (item['eventId'] as String).isEmpty ||
          (item['eventId'] as String).length > 1024 ||
          item['title'] is! String ||
          (item['title'] as String).length > 300 ||
          item['start'] is! String || item['end'] is! String ||
          item['allDay'] is! bool ||
          item['recurringEventId'] != null &&
              (item['recurringEventId'] is! String ||
               (item['recurringEventId'] as String).length > 1024) ||
          item['iCalUID'] != null &&
              (item['iCalUID'] is! String ||
               (item['iCalUID'] as String).length > 1024)) {
        throw const GcalStageClientException(
            GcalStageClientFault.malformedBackendResponse);
      }
      final id = item['eventId'] as String;
      if (!seen.add(id)) {
        throw const GcalStageClientException(
            GcalStageClientFault.malformedBackendResponse);
      }
      final begins = DateTime.tryParse(item['start'] as String);
      final ends = DateTime.tryParse(item['end'] as String);
      if (begins == null || ends == null || !ends.isAfter(begins)) {
        throw const GcalStageClientException(
            GcalStageClientFault.malformedBackendResponse);
      }
      output.add(GcalStageEvent(
        calendarId: calendarId, eventId: id,
        title: item['title'] as String, start: begins, end: ends,
        allDay: item['allDay'] as bool,
        recurringEventId: item['recurringEventId'] as String?,
        iCalUid: item['iCalUID'] as String?,
      ));
    }
    return GcalStageEventBatch(
        List.unmodifiable(output), response.json['truncated'] as bool);
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
