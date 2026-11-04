import 'package:flutter_test/flutter_test.dart';
import '../staging/google_calendar_direct/two_phase_flutter_client.dart';

const owner = 'c16e0ec0-415c-4e53-a488-5c6ed75d2662';
const other = 'a99d34ac-4859-475e-a43c-789c8192651e';
const handle = 'HlhHlhHlhHlhHlhHlhHlhHlhHlhHlhHlhHlhHlhHlhH';
const googleSubject = 'mock-google-user-42';
final fixedTime = DateTime.utc(2026, 11, 4, 12);

class Harness {
  String? currentUser = owner;
  String? token = 'MOCK_PRODUCTION_JWT';
  bool throwOnOpen = false;
  Uri? opened;
  DateTime time = fixedTime;
  final calls = <String>[];
  String previewStatus = 'waiting';
  String authorizationUrl =
      'https://accounts.google.com/o/oauth2/v2/auth'
      '?client_id=mock.apps.googleusercontent.com'
      '&response_type=code&code_challenge_method=S256&state=MOCK';
  late final GcalTwoPhaseFlutterStagingClient client;

  Harness() {
    client = GcalTwoPhaseFlutterStagingClient(
      currentAuth: () async {
        if (currentUser == null || token == null) return null;
        return GcalStageAppAuth(currentUser!, token!);
      },
      now: () => time,
      openBrowser: (url) async {
        if (throwOnOpen) throw StateError('browser sensitive failure');
        opened = url;
      },
      post: (route, jwt, body) async {
        calls.add(route);
        expect(jwt, 'MOCK_PRODUCTION_JWT');
        switch (route) {
          case '/start':
            expect(body, isEmpty);
            return GcalStageResponse(200, {
              'authorizationUrl': authorizationUrl,
              'handle': handle,
              'expiresAt':
                  fixedTime.add(const Duration(minutes: 10)).millisecondsSinceEpoch ~/
                      1000,
            });
          case '/preview':
            expect(body['handle'], handle);
            if (previewStatus == 'waiting') {
              return const GcalStageResponse(200, {'status': 'waiting'});
            }
            return const GcalStageResponse(200, {
              'status': 'awaiting_confirmation',
              'googleSubject': googleSubject,
              'googleEmail': 'verified@example.invalid',
            });
          case '/confirm':
            expect(body['explicitConfirmation'], true);
            expect(body['handle'], handle);
            return const GcalStageResponse(
                200, {'connected': true, 'googleSubject': googleSubject});
          case '/disconnect':
            expect(body['explicitConfirmation'], true);
            expect(body['googleSubject'], googleSubject);
            return const GcalStageResponse(
                200, {'disconnected': true, 'providerRevoked': false});
          default:
            return const GcalStageResponse(503, {'error': 'locked'});
        }
      },
    );
  }
}

Future<void> expectFault(
    Future<void> Function() action, GcalStageClientFault fault) async {
  await expectLater(action(), throwsA(
    isA<GcalStageClientException>().having((x) => x.kind, 'kind', fault)));
}

void main() {
  test('two phase Flutter client never stores Google tokens and requires preview', () async {
    final h = Harness();
    await h.client.begin();
    expect(h.client.awaitingGoogleConsent, true);
    expect(h.opened?.host, 'accounts.google.com');
    expect(h.opened.toString(), isNot(contains(handle)));
    await expectFault(() => h.client.begin(), GcalStageClientFault.alreadyPending);
    final first = await h.client.preview();
    expect(first.waiting, true);
    await expectFault(() => h.client.confirm(explicitConfirmation: true),
        GcalStageClientFault.previewRequired);
    h.previewStatus = 'ready';
    final second = await h.client.preview();
    expect(second.waiting, false);
    expect(second.verifiedEmail, 'verified@example.invalid');
    await expectFault(() => h.client.confirm(explicitConfirmation: false),
        GcalStageClientFault.explicitConfirmationRequired);
    expect(h.calls.where((x) => x == '/confirm'), isEmpty);
    await h.client.confirm(explicitConfirmation: true);
    expect(h.client.connectedThisSession, true);
    expect(h.client.awaitingGoogleConsent, false);
    expect(h.client.connectedGoogleSubject, googleSubject);
    await expectFault(() => h.client.confirm(explicitConfirmation: true),
        GcalStageClientFault.notPending);
    await expectFault(() => h.client.disconnect(explicitConfirmation: false),
        GcalStageClientFault.explicitConfirmationRequired);
    final result = await h.client.disconnect(explicitConfirmation: true);
    expect(result.locallyDisconnected, true);
    expect(result.providerRevoked, false);
    expect(h.client.connectedThisSession, false);
    expect(h.calls, ['/start','/preview','/preview','/confirm','/disconnect']);
  });

  test('app account switch invalidates outstanding in-memory OAuth handle', () async {
    final h = Harness();
    await h.client.begin();
    h.currentUser = other;
    await expectLater(h.client.preview(), throwsA(
      isA<GcalStageClientException>().having(
          (x) => x.kind, 'kind', GcalStageClientFault.accountChanged)));
    expect(h.client.awaitingGoogleConsent, false);
    expect(h.client.connectedThisSession, false);
    expect(h.calls, ['/start']); // No cross-account backend preview.
  });

  test('signed-out app never starts OAuth or sends bearer to staging', () async {
    final h = Harness()..currentUser = null;
    await expectFault(() => h.client.begin(),
        GcalStageClientFault.authenticationRequired);
    expect(h.calls, isEmpty);
  });

  test('host allowlist blocks backend response from an unrelated site', () async {
    final h = Harness()
      ..authorizationUrl = 'https://evil.invalid/phish?response_type=code';
    await expectFault(() => h.client.begin(),
        GcalStageClientFault.malformedBackendResponse);
    expect(h.opened, isNull);
    expect(h.calls, ['/start']);
  });

  test('browser launch error clears pending state without leaking raw error', () async {
    final h = Harness()..throwOnOpen = true;
    await expectFault(() => h.client.begin(),
        GcalStageClientFault.failedToOpenBrowser);
    expect(h.client.awaitingGoogleConsent, false);
  });

  test('expired consent never sends a preview or confirmation request', () async {
    final h = Harness();
    await h.client.begin();
    h.time = fixedTime.add(const Duration(minutes: 11));
    await expectLater(h.client.preview(), throwsA(
      isA<GcalStageClientException>().having(
          (x) => x.kind, 'kind', GcalStageClientFault.expired)));
    expect(h.calls, ['/start']);
    expect(h.client.awaitingGoogleConsent, false);
  });

  test('controller state is memory-only and not reusable across restarts', () async {
    final a = Harness();
    await a.client.begin();
    final b = Harness();
    await expectLater(b.client.preview(), throwsA(
      isA<GcalStageClientException>().having(
          (x) => x.kind, 'kind', GcalStageClientFault.notPending)));
    expect(b.calls, isEmpty);
  });
}
