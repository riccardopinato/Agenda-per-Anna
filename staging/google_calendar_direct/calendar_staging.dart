// STAGING ONLY — NOT IMPORTED BY lib/main.dart OR PRODUCTION ROUTES.
// Google Calendar direct API adapter. Deliberately no token acquisition,
// transport implementation, persistence implementation or automatic runner.
// Activation requires a later, separately reviewed integration PR.
import 'dart:convert';
import 'package:crypto/crypto.dart';

const googleCalendarOwnedEventsScope =
    'https://www.googleapis.com/auth/calendar.events.owned';
const googleCalendarListReadScope =
    'https://www.googleapis.com/auth/calendar.calendarlist.readonly';

enum GcalFaultKind {
  consentRequired,
  androidWriterStillEnabled,
  migrationReviewRequired,
  invalidEvent,
  ownershipConflict,
  authorization,
  permission,
  rateLimited,
  transient,
  unexpected,
}

class GcalFault implements Exception {
  final GcalFaultKind kind;
  final int? httpStatus;
  const GcalFault(this.kind, [this.httpStatus]);
  bool get retryable =>
      kind == GcalFaultKind.transient || kind == GcalFaultKind.rateLimited;
  @override
  String toString() => 'Google Calendar staging error: ${kind.name}';
}

class GcalHttpResult {
  final int status;
  final Map<String, dynamic> json;
  final Map<String, String> headers;
  const GcalHttpResult(this.status, this.json,
      [this.headers = const <String, String>{}]);
}

/// Integration seam: Flutter Web/Android/iOS will supply a vetted client.
/// Staging NEVER makes a network request without an explicitly supplied port.
abstract class GcalHttpPort {
  Future<GcalHttpResult> request(
    String method,
    Uri endpoint, {
    required Map<String, String> headers,
    Map<String, dynamic>? body,
  });
}

/// Google provider ACCESS token, not the Supabase session token.
/// Actual OAuth consent and secure refresh-token lifecycle remain gated.
abstract class GcalAccessTokenPort {
  Future<String> readValidProviderAccessToken();
}

/// Persist in encrypted, account-separated storage when activated.
/// NEVER use shared preferences for Google refresh tokens.
abstract class GcalLinkPort {
  Future<GcalLink?> read(String scopeHash);
  Future<void> write(GcalLink link);
}

class GcalLink {
  final String scopeHash;
  final String remoteEventId;
  final String etag;
  final String contentHash;

  const GcalLink({
    required this.scopeHash,
    required this.remoteEventId,
    required this.etag,
    required this.contentHash,
  });

  Map<String, String> toJson() => <String, String>{
        'scopeHash': scopeHash,
        'remoteEventId': remoteEventId,
        'etag': etag,
        'contentHash': contentHash,
      };

  factory GcalLink.fromJson(Map<String, dynamic> data) => GcalLink(
        scopeHash: data['scopeHash'] as String,
        remoteEventId: data['remoteEventId'] as String,
        etag: data['etag'] as String,
        contentHash: data['contentHash'] as String,
      );
}

/// Only a private, single appointment, NOT an entire AgendaStore snapshot.
/// No notes, attendees, Vault, shared-space data or media fields exist here.
class GcalDraft {
  final String localId;
  final String title;
  final DateTime date;
  final int? startMinutes;
  final int? endMinutes;
  final String timeZone;

  const GcalDraft({
    required this.localId,
    required this.title,
    required this.date,
    required this.startMinutes,
    required this.endMinutes,
    required this.timeZone,
  });

  bool get isAllDay => startMinutes == null && endMinutes == null;
}

class GcalCalendar {
  final String id;
  final String title;
  final String accessRole;
  final bool primary;
  const GcalCalendar(this.id, this.title, this.accessRole, this.primary);
}

/// Safe deterministic event identity: 2-letter prefix + 64 hex chars.
/// Hex is a valid subset of Google's base32hex event-ID alphabet.
String gcalOwnerHash({
  required String accountId,
  required String calendarId,
  required String localEventId,
}) {
  if (accountId.trim().isEmpty ||
      calendarId.trim().isEmpty ||
      localEventId.trim().isEmpty) {
    throw const GcalFault(GcalFaultKind.invalidEvent);
  }
  return sha256
      .convert(utf8.encode(
          jsonEncode(<String>['annas-diary-gcal-v1', accountId, calendarId,
            localEventId])))
      .toString();
}

String _civilDate(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

String _civilTime(DateTime day, int minutes) =>
    '${_civilDate(day)}T${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}:00';

/// Local civil time + an explicit IANA zone; Google resolves DST correctly.
/// For all-day events the end is exclusive, as required by Calendar API.
Map<String, dynamic> gcalEventBody(GcalDraft item, String ownerHash) {
  if (ownerHash.length != 64 ||
      !RegExp(r'^[0-9a-f]{64}$').hasMatch(ownerHash) ||
      item.title.trim().isEmpty ||
      item.title.length > 400 ||
      item.localId.trim().isEmpty ||
      item.date.year < 1970 ||
      item.date.year > 2100 ||
      (item.timeZone != 'UTC' &&
          !RegExp(r'^[A-Za-z_]+(?:/[A-Za-z0-9_.+-]+)+$')
              .hasMatch(item.timeZone)) ||
      (item.startMinutes == null) != (item.endMinutes == null)) {
    throw const GcalFault(GcalFaultKind.invalidEvent);
  }
  final allDay = item.isAllDay;
  if (!allDay &&
      (item.startMinutes! < 0 ||
          item.startMinutes! >= 1440 ||
          item.endMinutes! < 0 ||
          item.endMinutes! >= 1440)) {
    throw const GcalFault(GcalFaultKind.invalidEvent);
  }
  final nextDay =
      DateTime.utc(item.date.year, item.date.month, item.date.day + 1);
  final endDay = allDay ||
          (item.endMinutes! <= item.startMinutes!)
      ? nextDay
      : item.date;
  final Map<String, dynamic> begin = allDay
      ? <String, dynamic>{'date': _civilDate(item.date)}
      : <String, dynamic>{
          'dateTime': _civilTime(item.date, item.startMinutes!),
          'timeZone': item.timeZone,
        };
  final Map<String, dynamic> finish = allDay
      ? <String, dynamic>{'date': _civilDate(nextDay)}
      : <String, dynamic>{
          'dateTime': _civilTime(endDay, item.endMinutes!),
          'timeZone': item.timeZone,
        };
  return <String, dynamic>{
    'id': 'ad$ownerHash',
    'summary': item.title.trim(),
    'start': begin,
    'end': finish,
    'visibility': 'private',
    'reminders': <String, dynamic>{
      'useDefault': false,
      'overrides': <dynamic>[],
    },
    'extendedProperties': <String, dynamic>{
      'private': <String, String>{
        'annasDiarySourceHash': ownerHash,
        'annasDiarySchema': '1',
      }
    },
  };
}

enum GcalWriteState { created, updated, unchanged, recovered }

class GcalWriteOutcome {
  final GcalWriteState state;
  final String remoteEventId;
  const GcalWriteOutcome(this.state, this.remoteEventId);
}

/// Deliberately manual: there is no scheduler, listener or app import.
/// The call fails closed unless both consent and Android-B3 deactivation
/// are attested by the future application integration layer.
class GcalStagedWriter {
  final GcalHttpPort transport;
  final GcalAccessTokenPort tokens;
  final GcalLinkPort links;
  const GcalStagedWriter({
    required this.transport,
    required this.tokens,
    required this.links,
  });

  Uri _url(String calendarId, [String? eventId]) => Uri(
        scheme: 'https',
        host: 'www.googleapis.com',
        pathSegments: <String>[
          'calendar', 'v3', 'calendars', calendarId, 'events',
          if (eventId != null) eventId,
        ],
      );

  Future<GcalHttpResult> _send(
    String method,
    Uri url, {
    Map<String, dynamic>? body,
    String? ifMatch,
  }) async {
    final accessToken = await tokens.readValidProviderAccessToken();
    if (accessToken.trim().isEmpty) {
      throw const GcalFault(GcalFaultKind.authorization);
    }
    final headers = <String, String>{
      'Authorization': 'Bearer $accessToken',
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json; charset=utf-8',
      if (ifMatch != null) 'If-Match': ifMatch,
    };
    // Never log bearer token, OAuth responses, private event summaries.
    try {
      final response = await transport.request(
        method, url, headers: headers, body: body);
      switch (response.status) {
        case 200:
        case 201:
        case 204:
        case 404:
        case 409:
        case 412:
          return response;
        case 401:
          throw const GcalFault(GcalFaultKind.authorization, 401);
        case 403:
          throw const GcalFault(GcalFaultKind.permission, 403);
        case 429:
          throw const GcalFault(GcalFaultKind.rateLimited, 429);
        case 500:
        case 502:
        case 503:
        case 504:
          throw GcalFault(GcalFaultKind.transient, response.status);
        default:
          throw GcalFault(GcalFaultKind.unexpected, response.status);
      }
    } on GcalFault {
      rethrow;
    } catch (_) {
      throw const GcalFault(GcalFaultKind.transient);
    }
  }

  String _etag(Map<String, dynamic> remote) {
    final value = remote['etag'];
    if (value is! String || value.isEmpty) {
      throw const GcalFault(GcalFaultKind.unexpected);
    }
    return value;
  }

  bool _ours(Map<String, dynamic> remote, String marker) {
    final properties = remote['extendedProperties'];
    if (properties is! Map) return false;
    final private = properties['private'];
    return private is Map &&
        private['annasDiarySourceHash'] == marker;
  }

  bool _sameContent(
    Map<String, dynamic> remote,
    Map<String, dynamic> payload,
  ) {
    bool sameEndpoint(dynamic actual, dynamic expected) {
      if (actual is! Map || expected is! Map) return false;
      if (expected['date'] != null) {
        return actual['date'] == expected['date'];
      }
      final incoming = actual['dateTime'];
      final wanted = expected['dateTime'];
      // Google normally returns an RFC3339 offset even if a civil datetime
      // plus explicit timeZone was provided in the write.
      return incoming is String && wanted is String &&
          incoming.length >= 19 && wanted.length >= 19 &&
          incoming.substring(0, 19) == wanted.substring(0, 19);
    }
    return remote['summary'] == payload['summary'] &&
        sameEndpoint(remote['start'], payload['start']) &&
        sameEndpoint(remote['end'], payload['end']);
  }

  /// Restrict the surface to owned/writable calendars. The chosen scopes
  /// need explicit Google OAuth consent when integration is activated.
  Future<List<GcalCalendar>> listWritableCalendars() async {
    final result = <GcalCalendar>[];
    String? page;
    for (var i = 0; i < 10; i++) {
      final params = <String, String>{
        'minAccessRole': 'writer',
        'maxResults': '250',
        if (page != null) 'pageToken': page,
      };
      final url = Uri(
        scheme: 'https',
        host: 'www.googleapis.com',
        pathSegments: const <String>[
          'calendar', 'v3', 'users', 'me', 'calendarList',
        ],
        queryParameters: params,
      );
      final response = await _send('GET', url);
      if (response.status != 200) {
        throw const GcalFault(GcalFaultKind.unexpected);
      }
      final raw = response.json['items'];
      if (raw is List) {
        for (final value in raw.whereType<Map>()) {
          final id = value['id'];
          final role = value['accessRole'];
          if (id is String &&
              (role == 'writer' || role == 'owner')) {
            result.add(GcalCalendar(
              id, (value['summary'] as String?) ?? id,
              role as String, value['primary'] == true));
          }
        }
      }
      final next = response.json['nextPageToken'];
      if (next is! String || next.isEmpty) return result;
      page = next;
    }
    throw const GcalFault(GcalFaultKind.unexpected);
  }

  Future<GcalWriteOutcome> upsertOne({
    required String accountId,
    required String calendarId,
    required GcalDraft event,
    required bool googleConsentGranted,
    required bool androidB3Disabled,
    required bool existingAndroidExportsReviewed,
  }) async {
    if (!googleConsentGranted) {
      throw const GcalFault(GcalFaultKind.consentRequired);
    }
    if (!androidB3Disabled) {
      throw const GcalFault(GcalFaultKind.androidWriterStillEnabled);
    }
    if (!existingAndroidExportsReviewed) {
      // Android-B3 can already have propagated the same appointments through
      // Google's sync adapter. User-assisted migration/dedupe review is vital.
      throw const GcalFault(GcalFaultKind.migrationReviewRequired);
    }
    final hash = gcalOwnerHash(
      accountId: accountId,
      calendarId: calendarId,
      localEventId: event.localId,
    );
    final desired = gcalEventBody(event, hash);
    final desiredContent = sha256.convert(utf8.encode(jsonEncode(<dynamic>[
      desired['summary'], desired['start'], desired['end'],
    ]))).toString();
    final remoteId = 'ad$hash';
    final link = await links.read(hash);
    if (link != null &&
        (link.scopeHash != hash || link.remoteEventId != remoteId ||
            link.etag.isEmpty)) {
      throw const GcalFault(GcalFaultKind.ownershipConflict);
    }

    // GET by deterministic ID. This is race/idempotency safe even if the
    // previous insert worked on Google but local mapping write failed.
    final remoteResponse = await _send(
      'GET', _url(calendarId, remoteId));
    if (remoteResponse.status == 200) {
      final remote = remoteResponse.json;
      if (remote['id'] != remoteId || !_ours(remote, hash)) {
        throw const GcalFault(GcalFaultKind.ownershipConflict);
      }
      final remoteEtag = _etag(remote);
      if (link == null) {
        // Recover only identical content. A Google-side edit is a conflict.
        if (!_sameContent(remote, desired)) {
          throw const GcalFault(GcalFaultKind.ownershipConflict);
        }
        await links.write(GcalLink(
          scopeHash: hash,
          remoteEventId: remoteId,
          etag: remoteEtag,
          contentHash: desiredContent,
        ));
        return GcalWriteOutcome(GcalWriteState.recovered, remoteId);
      }
      if (remoteEtag != link.etag) {
        throw const GcalFault(GcalFaultKind.ownershipConflict);
      }
      if (link.contentHash == desiredContent) {
        return GcalWriteOutcome(GcalWriteState.unchanged, remoteId);
      }
      final patch = Map<String, dynamic>.of(desired)..remove('id');
      final updated = await _send(
        'PATCH', _url(calendarId, remoteId),
        body: patch, ifMatch: link.etag,
      );
      if (updated.status == 412 || updated.status == 409) {
        throw const GcalFault(GcalFaultKind.ownershipConflict);
      }
      if (updated.status != 200) {
        throw const GcalFault(GcalFaultKind.unexpected);
      }
      await links.write(GcalLink(
        scopeHash: hash, remoteEventId: remoteId,
        etag: _etag(updated.json), contentHash: desiredContent,
      ));
      return GcalWriteOutcome(GcalWriteState.updated, remoteId);
    }
    if (remoteResponse.status != 404) {
      throw const GcalFault(GcalFaultKind.unexpected);
    }
    if (link != null) {
      // An event was deleted or moved externally. Do not resurrect silently.
      throw const GcalFault(GcalFaultKind.ownershipConflict);
    }
    final inserted = await _send(
      'POST', _url(calendarId), body: desired);
    if (inserted.status == 409) {
      // Another device won the race. Caller retries: GET then recover.
      throw const GcalFault(GcalFaultKind.ownershipConflict);
    }
    if (inserted.status != 200 && inserted.status != 201) {
      throw const GcalFault(GcalFaultKind.unexpected);
    }
    if (inserted.json['id'] != remoteId ||
        !_ours(inserted.json, hash)) {
      throw const GcalFault(GcalFaultKind.ownershipConflict);
    }
    await links.write(GcalLink(
      scopeHash: hash, remoteEventId: remoteId,
      etag: _etag(inserted.json), contentHash: desiredContent,
    ));
    return GcalWriteOutcome(GcalWriteState.created, remoteId);
  }
}
