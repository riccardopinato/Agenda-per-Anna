import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/qa/google_calendar/two_phase_flutter_client.dart';
import '../lib/qa/google_calendar/two_phase_flutter_panel.dart';

void main() {
  test('known staging 503 is not misreported as generic request rejection',
      () async {
    final client = GcalTwoPhaseFlutterStagingClient(
      currentAuth: () async => const GcalStageAppAuth(
          'test-account', 'TEST_APP_JWT'),
      post: (route, jwt, body) async {
        expect(route, '/start');
        expect(jwt, 'TEST_APP_JWT');
        return const GcalStageResponse(
            503, {'error': 'STAGING_NOT_ACTIVATED'});
      },
      openBrowser: (_) async => fail('Backend is locked; no Google browser'),
    );
    await expectLater(
        client.begin(),
        throwsA(isA<GcalStageClientException>().having(
          (e) => e.kind, 'kind', GcalStageClientFault.stagingLocked,
        )));
    expect(client.awaitingGoogleConsent, false);
    expect(client.connectedThisSession, false);
  });

  test('other 503 responses stay general, not incorrectly marked locked',
      () async {
    final client = GcalTwoPhaseFlutterStagingClient(
      currentAuth: () async => const GcalStageAppAuth('id', 'jwt'),
      post: (route, jwt, body) async =>
          const GcalStageResponse(503, {'error': 'DB_UNAVAILABLE'}),
      openBrowser: (_) async => fail('Must not launch Google'),
    );
    await expectLater(client.begin(),
        throwsA(isA<GcalStageClientException>().having(
            (e) => e.kind, 'kind', GcalStageClientFault.requestRejected)));
  });

  test('expired production JWT is distinct from backend kill switch',
      () async {
    final client = GcalTwoPhaseFlutterStagingClient(
      currentAuth: () async => const GcalStageAppAuth('id', 'jwt'),
      post: (route, jwt, body) async =>
          const GcalStageResponse(401, {'error': 'UNAUTHORIZED'}),
      openBrowser: (_) async => fail('No consent'),
    );
    await expectLater(client.begin(),
        throwsA(isA<GcalStageClientException>().having(
            (e) => e.kind, 'kind', GcalStageClientFault.authenticationRequired)));
  });

  testWidgets('QA card explains staging safety block without red generic error',
      (tester) async {
    final client = GcalTwoPhaseFlutterStagingClient(
      currentAuth: () async => const GcalStageAppAuth('id', 'jwt'),
      post: (route, jwt, body) async =>
          const GcalStageResponse(503, {'error': 'STAGING_NOT_ACTIVATED'}),
      openBrowser: (_) async => fail('Locked backend must not open Google'),
    );
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: GcalStagingTestPanel(client: client),
    )));
    await tester.tap(find.text('Collega Google Calendar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('blocco di sicurezza è attivo'), findsOneWidget);
    expect(find.textContaining('requestRejected'), findsNothing);
    expect(find.text('Collega Google Calendar'), findsOneWidget);
  });
}
