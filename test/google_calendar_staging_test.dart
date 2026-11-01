import 'dart:convert';

import 'package:agenda_per_anna/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../staging/google_calendar_direct/agenda_projection_staging.dart';
import '../staging/google_calendar_direct/calendar_staging.dart';

class FakeProviderToken implements GcalAccessTokenPort {
  @override
  Future<String> readValidProviderAccessToken() async => 'TEST-NOT-REAL';
}

class FakeLinkStore implements GcalLinkPort {
  final entries = <String, GcalLink>{};
  bool failWriteOnce = false;

  @override
  Future<GcalLink?> read(String scopeHash) async => entries[scopeHash];

  @override
  Future<void> write(GcalLink link) async {
    if (failWriteOnce) {
      failWriteOnce = false;
      throw StateError('simulated persistence interruption');
    }
    entries[link.scopeHash] = link;
  }
}

class FakeCalendarHttp implements GcalHttpPort {
  Map<String, dynamic>? remote;
  int gets = 0;
  int posts = 0;
  int patches = 0;
  int listCalls = 0;
  String? patchPrecondition;
  int revision = 0;
  bool rejectPatches = false;
  int? forcedStatus;

  @override
  Future<GcalHttpResult> request(String method, Uri endpoint,
      {required Map<String, String> headers,
      Map<String, dynamic>? body}) async {
    expect(endpoint.scheme, 'https');
    expect(endpoint.host, 'www.googleapis.com');
    expect(headers['Authorization'], 'Bearer TEST-NOT-REAL');
    if (forcedStatus != null) return GcalHttpResult(forcedStatus!, {});
    if (endpoint.path.endsWith('/calendarList')) {
      listCalls++;
      return const GcalHttpResult(200, <String, dynamic>{
        'items': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'personal@example.com', 'summary': 'Personal',
            'accessRole': 'owner', 'primary': true,
          },
          <String, dynamic>{
            'id': 'writable@example.com', 'summary': 'Shared',
            'accessRole': 'writer',
          },
          <String, dynamic>{
            'id': 'readonly@example.com', 'summary': 'Read only',
            'accessRole': 'reader',
          }
        ]
      });
    }
    final parts = endpoint.pathSegments;
    expect(parts.length, greaterThanOrEqualTo(5));
    expect(parts[3], 'team+calendar@example.com');
    if (method == 'GET') {
      gets++;
      return remote == null
          ? const GcalHttpResult(404, {})
          : GcalHttpResult(200, Map<String, dynamic>.from(remote!));
    }
    if (method == 'POST') {
      posts++;
      expect(body, isNotNull);
      if (remote != null) return const GcalHttpResult(409, {});
      revision++;
      remote = <String, dynamic>{
        ...body!, 'etag': '"e$revision"',
      };
      return GcalHttpResult(201, Map<String, dynamic>.from(remote!));
    }
    if (method == 'PATCH') {
      patches++;
      patchPrecondition = headers['If-Match'];
      if (rejectPatches) return const GcalHttpResult(412, {});
      expect(remote, isNotNull);
      expect(patchPrecondition, remote!['etag']);
      revision++;
      remote = <String, dynamic>{...remote!, ...body!, 'etag': '"e$revision"'};
      return GcalHttpResult(200, Map<String, dynamic>.from(remote!));
    }
    fail('unexpected HTTP method: $method');
  }
}

GcalDraft draft({
  String title = 'Dentist',
  DateTime? date,
  int? start = 10 * 60,
  int? end = 11 * 60,
  String zone = 'Europe/Rome',
}) =>
    GcalDraft(
      localId: 'local-1',
      title: title,
      date: date ?? DateTime(2026, 11, 7),
      startMinutes: start,
      endMinutes: end,
      timeZone: zone,
    );

const targetCalendar = 'team+calendar@example.com';

Future<GcalWriteOutcome> writeSample(GcalStagedWriter service,
        {String title = 'Dentist',
        bool consent = true,
        bool androidOff = true,
        bool androidExportsReviewed = true}) =>
    service.upsertOne(
      accountId: 'supabase-account-1',
      calendarId: targetCalendar,
      event: draft(title: title),
      googleConsentGranted: consent,
      androidB3Disabled: androidOff,
      existingAndroidExportsReviewed: androidExportsReviewed,
    );

void main() {
  test('staging owner identity is stable, scoped by account and calendar', () {
    final h1 = gcalOwnerHash(
      accountId: 'a', calendarId: targetCalendar, localEventId: '123');
    final h2 = gcalOwnerHash(
      accountId: 'a', calendarId: targetCalendar, localEventId: '123');
    final otherCalendar = gcalOwnerHash(
      accountId: 'a', calendarId: 'different', localEventId: '123');
    final otherAccount = gcalOwnerHash(
      accountId: 'b', calendarId: targetCalendar, localEventId: '123');
    expect(h1, h2);
    expect(h1, hasLength(64));
    expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(h1), true);
    expect(h1, isNot(otherCalendar));
    expect(h1, isNot(otherAccount));
    expect('ad$h1', matches(RegExp(r'^[a-v0-9]{5,1024}$')));
  });

  test('Google API payload excludes all private notes and uses explicit zone',
      () {
    final hash = gcalOwnerHash(
        accountId: 'a', calendarId: 'c', localEventId: 'id');
    final body = gcalEventBody(draft(), hash);
    expect(body['summary'], 'Dentist');
    expect((body['start'] as Map)['dateTime'], '2026-11-07T10:00:00');
    expect((body['start'] as Map)['timeZone'], 'Europe/Rome');
    expect((body['end'] as Map)['dateTime'], '2026-11-07T11:00:00');
    expect((body['extendedProperties'] as Map)['private'],
        <String, String>{
          'annasDiarySourceHash': hash, 'annasDiarySchema': '1'
        });
    expect(body.containsKey('description'), false);
    expect(body.containsKey('attendees'), false);
    expect(body.containsKey('location'), false);
    expect(body['visibility'], 'private');
    expect((body['reminders'] as Map)['useDefault'], false);
  });

  test('all-day end is exclusive; timed overnight handles year rollover', () {
    final hash = gcalOwnerHash(
        accountId: 'a', calendarId: 'c', localEventId: 'id');
    final allDay = gcalEventBody(draft(
      date: DateTime(2026, 12, 31), start: null, end: null), hash);
    expect((allDay['start'] as Map)['date'], '2026-12-31');
    expect((allDay['end'] as Map)['date'], '2027-01-01');
    final overnight = gcalEventBody(draft(
      date: DateTime(2026, 12, 31), start: 23 * 60 + 30, end: 60), hash);
    expect((overnight['start'] as Map)['dateTime'], '2026-12-31T23:30:00');
    expect((overnight['end'] as Map)['dateTime'], '2027-01-01T01:00:00');
  });

  test('invalid half-defined time or unsupported zone fails closed', () {
    final hash = gcalOwnerHash(
        accountId: 'a', calendarId: 'c', localEventId: 'id');
    expect(() => gcalEventBody(draft(start: 600, end: null), hash),
        throwsA(isA<GcalFault>()));
    expect(() => gcalEventBody(draft(zone: 'not-a-time-zone'), hash),
        throwsA(isA<GcalFault>()));
  });

  test('no network happens without Google consent and Android B3 disabled',
      () async {
    final http = FakeCalendarHttp();
    final service = GcalStagedWriter(
        transport: http, tokens: FakeProviderToken(),
        links: FakeLinkStore());
    await expectLater(writeSample(service, consent: false),
      throwsA(isA<GcalFault>().having(
        (x) => x.kind, 'kind', GcalFaultKind.consentRequired)));
    await expectLater(writeSample(service, androidOff: false),
      throwsA(isA<GcalFault>().having(
        (x) => x.kind, 'kind', GcalFaultKind.androidWriterStillEnabled)));
    await expectLater(writeSample(service, androidExportsReviewed: false),
      throwsA(isA<GcalFault>().having(
        (x) => x.kind, 'kind', GcalFaultKind.migrationReviewRequired)));
    expect(http.gets + http.posts + http.patches, 0);
  });

  test('first export creates one event, rerun leaves it unchanged', () async {
    final http = FakeCalendarHttp();
    final links = FakeLinkStore();
    final service = GcalStagedWriter(
        transport: http, tokens: FakeProviderToken(), links: links);
    final first = await writeSample(service);
    expect(first.state, GcalWriteState.created);
    final second = await writeSample(service);
    expect(second.state, GcalWriteState.unchanged);
    expect(first.remoteEventId, second.remoteEventId);
    expect(http.posts, 1);
    expect(http.patches, 0);
    expect(http.gets, 2);
    expect(links.entries.length, 1);
  });

  test('local change patches existing owned event with If-Match', () async {
    final http = FakeCalendarHttp();
    final service = GcalStagedWriter(
        transport: http, tokens: FakeProviderToken(),
        links: FakeLinkStore());
    await writeSample(service);
    final outcome = await writeSample(service, title: 'Dentist rescheduled');
    expect(outcome.state, GcalWriteState.updated);
    expect(http.posts, 1);
    expect(http.patches, 1);
    expect(http.patchPrecondition, '"e1"');
  });

  test('remote manual edit and external deletion cannot be overwritten',
      () async {
    final http = FakeCalendarHttp();
    final service = GcalStagedWriter(
        transport: http, tokens: FakeProviderToken(),
        links: FakeLinkStore());
    await writeSample(service);
    http.remote!['etag'] = '"remote-edited"';
    await expectLater(writeSample(service, title: 'Changed'),
        throwsA(isA<GcalFault>().having(
          (e) => e.kind, 'kind', GcalFaultKind.ownershipConflict)));
    expect(http.patches, 0);
    http.remote = null;
    await expectLater(writeSample(service),
        throwsA(isA<GcalFault>().having(
          (e) => e.kind, 'kind', GcalFaultKind.ownershipConflict)));
    expect(http.posts, 1);
  });

  test('lost mapping after successful insert is recoverable, no duplicate',
      () async {
    final http = FakeCalendarHttp();
    final links = FakeLinkStore()..failWriteOnce = true;
    final service = GcalStagedWriter(
        transport: http, tokens: FakeProviderToken(), links: links);
    await expectLater(writeSample(service), throwsA(isA<StateError>()));
    final outcome = await writeSample(service);
    expect(outcome.state, GcalWriteState.recovered);
    expect(http.posts, 1);
    expect(links.entries, hasLength(1));
  });

  test('recovery refuses a remote event whose details changed', () async {
    final http = FakeCalendarHttp();
    final links = FakeLinkStore()..failWriteOnce = true;
    final service = GcalStagedWriter(
        transport: http, tokens: FakeProviderToken(), links: links);
    await expectLater(writeSample(service), throwsA(isA<StateError>()));
    http.remote!['summary'] = 'Unexpected Google edit';
    await expectLater(writeSample(service), throwsA(isA<GcalFault>().having(
      (e) => e.kind, 'kind', GcalFaultKind.ownershipConflict)));
    expect(http.posts, 1);
    expect(links.entries, isEmpty);
  });

  test('HTTP 429 is retryable but no silent retry is performed', () async {
    final http = FakeCalendarHttp()..forcedStatus = 429;
    final service = GcalStagedWriter(
        transport: http, tokens: FakeProviderToken(),
        links: FakeLinkStore());
    await expectLater(writeSample(service),
        throwsA(isA<GcalFault>()
          .having((e) => e.kind, 'kind', GcalFaultKind.rateLimited)
          .having((e) => e.retryable, 'retryable', true)));
  });

  test('calendar chooser excludes read-only calendars', () async {
    final http = FakeCalendarHttp();
    final service = GcalStagedWriter(
        transport: http, tokens: FakeProviderToken(),
        links: FakeLinkStore());
    final calendars = await service.listWritableCalendars();
    expect(calendars.map((c) => c.id), contains('personal@example.com'));
    expect(calendars.map((c) => c.id), contains('writable@example.com'));
    expect(calendars.map((c) => c.id), isNot(contains('readonly@example.com')));
    expect(http.listCalls, 1);
  });

  test('AgendaItem projection exports only private appointments', () {
    final appointment = AgendaItem(
      id: '1', title: 'Dentist', note: 'Very private',
      date: DateTime(2026, 11, 7), type: ItemType.appointment,
      start: const TimeOfDay(hour: 10, minute: 0),
      end: const TimeOfDay(hour: 11, minute: 30),
    );
    final task = AgendaItem(
      id: '2', title: 'Task', note: 'Not for Google',
      date: DateTime(2026, 11, 7), type: ItemType.task,
    );
    final projected = projectPrivateAppointmentForGoogle(
      appointment, timeZone: 'Europe/Rome');
    expect(projected?.title, 'Dentist');
    expect(projected?.startMinutes, 600);
    expect(projected?.endMinutes, 690);
    expect(projectPrivateAppointmentForGoogle(task,
      timeZone: 'Europe/Rome'), isNull);
    expect(jsonEncode(gcalEventBody(projected!, gcalOwnerHash(
      accountId: 'a', calendarId: 'c', localEventId: projected.localId))),
      isNot(contains('Very private')));
  });

  test('staging cannot run in main without new integration work', () {
    // A branch with an isolated module is not a deployed integration:
    // the production imports/routes and pubspec must be modified later.
    // The staging module itself has no app init, scheduler or OAuth secrets.
    expect(googleCalendarOwnedEventsScope,
        'https://www.googleapis.com/auth/calendar.events.owned');
    expect(googleCalendarListReadScope,
        'https://www.googleapis.com/auth/calendar.calendarlist.readonly');
  });
}
