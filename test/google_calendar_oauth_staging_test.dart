import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import '../staging/google_calendar_direct/oauth_staging.dart';

class DeterministicEntropy implements GcalOAuthEntropy {
  int _next = 1;

  @override
  String randomBase64Url(int bytes) {
    final current = _next++;
    return base64Url.encode(
        List<int>.generate(bytes, (index) => (current + index) % 256),
    ).replaceAll('=', '');
  }
}

const stagingClientId = 'mock-client.apps.googleusercontent.com';
final stagingRedirect =
    Uri.parse('https://staging.example.org/oauth/google-calendar/callback');

GcalOAuthStagingHandshake newHandshake({
  GcalOAuthStagingConfig? config,
  DateTime Function()? now,
  GcalOAuthEntropy? entropy,
}) => GcalOAuthStagingHandshake(
  config: config ?? GcalOAuthStagingConfig(
    clientId: stagingClientId, redirectUri: stagingRedirect),
  now: now,
  entropy: entropy ?? DeterministicEntropy(),
);

Uri callbackFor(GcalOAuthAuthorizationRequest request, {
  String? state,
  String? code = 'mock-only-authorization-code',
  String? error,
  Uri? redirect,
}) {
  final query = request.url.queryParameters;
  return (redirect ?? stagingRedirect).replace(queryParameters: {
    'state': state ?? query['state']!,
    if (code != null) 'code': code,
    if (error != null) 'error': error,
  });
}

void main() {
  test('authorization request is account-isolated, narrow and PKCE S256', () {
    final flow = newHandshake();
    final request = flow.begin(appAccountId: 'anna-local-user');
    final query = request.url.queryParameters;

    expect(request.url.toString(),
        startsWith(googleCalendarOAuthAuthorizeEndpoint));
    expect(query['client_id'], stagingClientId);
    expect(query['redirect_uri'], stagingRedirect.toString());
    expect(query['response_type'], 'code');
    expect(query['scope'], contains('calendar.events.owned'));
    expect(query['scope'], contains('calendar.calendarlist.readonly'));
    expect(query['scope'], isNot(contains('https://www.googleapis.com/auth/calendar ')));
    expect(query['code_challenge_method'], 'S256');
    expect(query['code_challenge'], matches(RegExp(r'^[A-Za-z0-9_-]{43}$')));
    expect(query['state']?.length, greaterThanOrEqualTo(43));
    expect(query['nonce']?.length, greaterThanOrEqualTo(43));
    expect(query['prompt'], 'select_account consent');
    expect(query['access_type'], 'offline');
    expect(query.containsKey('client_secret'), false);
    expect(query.containsKey('code_verifier'), false);

    final grant = flow.acceptCallback(
      callbackFor(request), currentAppAccountId: 'anna-local-user');
    expect(grant.code, 'mock-only-authorization-code');
    expect(grant.appAccountId, 'anna-local-user');
    expect(grant.redirectUri, stagingRedirect);
    expect(grant.nonce, query['nonce']);
    expect(grant.codeVerifier, isNot(query['code_challenge']));
    expect(grant.toString(), isNot(contains(grant.code)));
    expect(grant.toString(), isNot(contains(grant.codeVerifier)));
    expect(flow.hasPendingConsent, false);
  });

  test('callbacks require one-time state and reject replays', () {
    final flow = newHandshake();
    final request = flow.begin(appAccountId: 'account-a');
    final url = callbackFor(request);
    flow.acceptCallback(url, currentAppAccountId: 'account-a');
    expect(
      () => flow.acceptCallback(url, currentAppAccountId: 'account-a'),
      throwsA(isA<GcalOAuthStagingException>().having(
        (e) => e.kind, 'kind', GcalOAuthStagingFailure.notPending)),
    );
  });

  test('callback with wrong state invalidates pending flow', () {
    final flow = newHandshake();
    final request = flow.begin(appAccountId: 'account-a');
    expect(
      () => flow.acceptCallback(
          callbackFor(request, state: 'wrong-state'),
          currentAppAccountId: 'account-a'),
      throwsA(isA<GcalOAuthStagingException>().having(
        (e) => e.kind, 'kind', GcalOAuthStagingFailure.badState)),
    );
    expect(flow.hasPendingConsent, false);
  });

  test('account changes between start and callback are rejected', () {
    final flow = newHandshake();
    final request = flow.begin(appAccountId: 'account-a');
    expect(
      () => flow.acceptCallback(callbackFor(request),
          currentAppAccountId: 'account-b'),
      throwsA(isA<GcalOAuthStagingException>().having(
        (e) => e.kind, 'kind', GcalOAuthStagingFailure.accountChanged)),
    );
    expect(flow.hasPendingConsent, false);
  });

  test('callback must match configured HTTPS endpoint exactly', () {
    final flow = newHandshake();
    final request = flow.begin(appAccountId: 'account-a');
    final wrong = Uri.parse('https://other.example.org/oauth/google-calendar/callback');
    expect(
      () => flow.acceptCallback(
          callbackFor(request, redirect: wrong),
          currentAppAccountId: 'account-a'),
      throwsA(isA<GcalOAuthStagingException>().having(
        (e) => e.kind, 'kind', GcalOAuthStagingFailure.wrongRedirect)),
    );
  });

  test('ten minute deadline blocks late callbacks and clock rollback', () {
    var time = DateTime.utc(2026, 11, 3, 10, 0);
    final flow = newHandshake(now: () => time);
    final request = flow.begin(appAccountId: 'account-a');
    time = time.add(const Duration(minutes: 11));
    expect(
      () => flow.acceptCallback(
          callbackFor(request), currentAppAccountId: 'account-a'),
      throwsA(isA<GcalOAuthStagingException>().having(
        (e) => e.kind, 'kind', GcalOAuthStagingFailure.expired)),
    );
    time = DateTime.utc(2026, 11, 3, 10, 0);
    final retry = flow.begin(appAccountId: 'account-a');
    time = time.subtract(const Duration(seconds: 1));
    expect(
      () => flow.acceptCallback(
          callbackFor(retry), currentAppAccountId: 'account-a'),
      throwsA(isA<GcalOAuthStagingException>().having(
        (e) => e.kind, 'kind', GcalOAuthStagingFailure.expired)),
    );
  });

  test('Google denial cannot yield a code and cannot be retried', () {
    final flow = newHandshake();
    final request = flow.begin(appAccountId: 'account-a');
    expect(
      () => flow.acceptCallback(
        callbackFor(request, code: null, error: 'access_denied'),
        currentAppAccountId: 'account-a'),
      throwsA(isA<GcalOAuthStagingException>().having(
        (e) => e.kind, 'kind', GcalOAuthStagingFailure.accessDenied)),
    );
    expect(flow.hasPendingConsent, false);
  });

  test('mixed code/error and URL fragments fail closed', () {
    final flow = newHandshake();
    final req = flow.begin(appAccountId: 'account-a');
    expect(
      () => flow.acceptCallback(
          callbackFor(req, error: 'access_denied'),
          currentAppAccountId: 'account-a'),
      throwsA(isA<GcalOAuthStagingException>().having(
        (e) => e.kind, 'kind', GcalOAuthStagingFailure.malformedResponse)),
    );
    final retry = flow.begin(appAccountId: 'account-a');
    expect(
      () => flow.acceptCallback(
          callbackFor(retry).replace(fragment: 'access_token=leak'),
          currentAppAccountId: 'account-a'),
      throwsA(isA<GcalOAuthStagingException>().having(
        (e) => e.kind, 'kind', GcalOAuthStagingFailure.wrongRedirect)),
    );
  });

  test('two simultaneous consents and empty account ID are rejected', () {
    final flow = newHandshake();
    expect(() => flow.begin(appAccountId: ' '),
        throwsA(isA<GcalOAuthStagingException>()));
    flow.begin(appAccountId: 'account-a');
    expect(() => flow.begin(appAccountId: 'account-b'),
        throwsA(isA<GcalOAuthStagingException>().having(
          (e) => e.kind, 'kind', GcalOAuthStagingFailure.alreadyPending)));
    flow.cancel();
    expect(flow.hasPendingConsent, false);
    expect(() => flow.begin(appAccountId: 'account-b'), returnsNormally);
  });

  test('invalid callback settings are rejected, no production fallback', () {
    final invalid = [
      Uri.parse('http://staging.example.org/oauth/callback'),
      Uri.parse('io.supabase.annasdiary://login-callback/'),
      Uri.parse('https://staging.example.org/oauth/callback?token=secret'),
    ];
    for (final uri in invalid) {
      expect(
        () => newHandshake(config: GcalOAuthStagingConfig(
          clientId: stagingClientId, redirectUri: uri)),
        throwsA(isA<GcalOAuthStagingException>().having(
          (e) => e.kind, 'kind', GcalOAuthStagingFailure.invalidConfiguration)),
      );
    }
  });

  test('invalid entropy is rejected before creating authorization URL', () {
    final flow = newHandshake(entropy: _PredictableEntropy());
    expect(() => flow.begin(appAccountId: 'account-a'),
      throwsA(isA<GcalOAuthStagingException>().having(
        (e) => e.kind, 'kind', GcalOAuthStagingFailure.invalidConfiguration)));
    expect(flow.hasPendingConsent, false);
  });

  test('no production OAuth route or actual token endpoint is involved', () {
    final flow = newHandshake();
    final request = flow.begin(appAccountId: 'account-a');
    expect(request.url.toString(), isNot(
        contains('pxsxlorntswypdbeerzw.supabase.co')));
    expect(request.url.queryParameters.containsKey('client_secret'), false);
    expect(request.url.queryParameters.containsKey('access_token'), false);
  });
}

class _PredictableEntropy implements GcalOAuthEntropy {
  @override
  String randomBase64Url(int bytes) => 'predictable';
}
