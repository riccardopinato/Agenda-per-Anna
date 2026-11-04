import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../staging/google_calendar_direct/two_phase_flutter_client.dart';
import '../staging/google_calendar_direct/two_phase_flutter_transport.dart';

void main() {
  test('staging HTTPS transport sends only production app JWT to pinned host',
      () async {
    var calls = 0;
    final client = MockClient((request) async {
      calls++;
      expect(request.url.scheme, 'https');
      expect(request.url.host, 'pdanpljacyozslrutsor.supabase.co');
      expect(request.url.path,
          '/functions/v1/gcal-oauth-callback/start');
      expect(request.method, 'POST');
      expect(request.followRedirects, false);
      expect(request.headers['authorization'], 'Bearer MOCK_APP_JWT');
      expect(request.url.queryParameters, isEmpty);
      expect(request.body, '{}');
      expect(request.body, isNot(contains('MOCK_APP_JWT')));
      return http.Response(jsonEncode(<String, Object?>{
        'authorizationUrl': 'https://accounts.google.com/o/oauth2/v2/auth',
        'handle': 'opaque',
        'expiresAt': 1793710600,
      }), 200);
    });
    final port = GcalStagingEdgeTransport.forStaging(client);
    final result = await port.post('/start', 'MOCK_APP_JWT', const {});
    expect(result.status, 200);
    expect(result.json['handle'], 'opaque');
    expect(calls, 1);
    client.close();
  });

  test('invalid route is rejected without sending any network request',
      () async {
    var requests = 0;
    final port = GcalStagingEdgeTransport.forStaging(
        MockClient((_) async { requests++; return http.Response('{}', 200); }));
    await expectLater(
        port.post('/callback?code=SECRET', 'MOCK_APP_JWT', const {}),
        throwsA(isA<GcalStageClientException>()));
    expect(requests, 0);
  });

  test('redirect replies are rejected without following bearer to other hosts',
      () async {
    var requests = 0;
    final port = GcalStagingEdgeTransport.forStaging(MockClient((_) async {
      requests++;
      return http.Response('', 302,
          headers: {'location': 'https://evil.invalid/steal'});
    }));
    await expectLater(port.post('/preview', 'MOCK_APP_JWT', const {
      'handle': 'redacted',
    }), throwsA(isA<GcalStageClientException>()));
    expect(requests, 1);
  });

  test('oversized JSON and non JSON responses fail closed', () async {
    final oversized = GcalStagingEdgeTransport.forStaging(MockClient((_) async =>
        http.Response(List<String>.filled(9000, 'X').join(), 200)));
    await expectLater(oversized.post('/preview', 'JWT', const {}),
        throwsA(isA<GcalStageClientException>()));
    final malformed = GcalStagingEdgeTransport.forStaging(MockClient((_) async =>
        http.Response('[]', 200)));
    await expectLater(malformed.post('/preview', 'JWT', const {}),
        throwsA(isA<GcalStageClientException>()));
  });
}
