import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/ecosystem_service.dart';

void main() {
  test('ecosystem registry keeps stable unique app identities', () {
    final ids = EcosystemRegistry.apps.map((app) => app.appId).toList();

    expect(ids.toSet().length, ids.length);
    expect(EcosystemRegistry.byAppId('annas_diary')?.integrationStatus,
        EcosystemIntegrationStatus.active);
    expect(EcosystemRegistry.byAppId('wonderlog')?.integrationStatus,
        EcosystemIntegrationStatus.contractReady);
    expect(EcosystemRegistry.byAppId('sleepmax')?.integrationStatus,
        EcosystemIntegrationStatus.planned);
    expect(EcosystemRegistry.byAppId('cashmate')?.integrationStatus,
        EcosystemIntegrationStatus.planned);
  });

  test('Wonderlog contract probe matches the v0.96 deep-link scheme', () {
    final wonderlog = EcosystemRegistry.byAppId('WONDERLOG');

    expect(wonderlog, isNotNull);
    expect(wonderlog!.protocolVersions, contains('1.0'));
    expect(Uri.parse(wonderlog.probeUri!).scheme, 'wonderlog');
    expect(wonderlog.launchUri, isNull,
        reason:
            'v0.97 must not assume a stable Wonderlog root destination yet.');
  });

  test('Anna registry capabilities match Life Bridge v1 receive contract', () {
    final anna = EcosystemRegistry.byAppId('annas_diary')!;

    expect(
      anna.receives,
      containsAll(<String>{
        'moment',
        'travel_memory',
        'journey',
        'photo',
        'place',
        'event',
      }),
    );
    expect(anna.protocolVersions, contains('1.0'));
  });

  test('launcher rejects malformed deep links without invoking platform', () async {
    var invoked = false;
    final launcher = EcosystemLauncher(
      launch: (_) async {
        invoked = true;
        return true;
      },
    );

    final result = await launcher.openDeepLink('not a uri');

    expect(result, EcosystemLaunchOutcome.invalidUri);
    expect(invoked, isFalse);
  });

  test('launcher opens an explicit source deep link', () async {
    Uri? opened;
    final launcher = EcosystemLauncher(
      launch: (uri) async {
        opened = uri;
        return true;
      },
    );

    final result =
        await launcher.openDeepLink('wonderlog://journey/journey-42');

    expect(result, EcosystemLaunchOutcome.opened);
    expect(opened.toString(), 'wonderlog://journey/journey-42');
  });

  test('Android availability probe is best-effort and does not launch', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    var launched = false;
    final launcher = EcosystemLauncher(
      canLaunch: (uri) async => uri.scheme == 'wonderlog',
      launch: (_) async {
        launched = true;
        return true;
      },
    );

    final wonderlog = EcosystemRegistry.byAppId('wonderlog')!;
    final result = await launcher.availabilityFor(wonderlog);

    expect(result, EcosystemAvailability.available);
    expect(launched, isFalse);
  });

  test('apps without a probe remain unknown instead of being guessed absent',
      () async {
    final launcher = EcosystemLauncher(
      canLaunch: (_) async => false,
    );
    final sleepMax = EcosystemRegistry.byAppId('sleepmax')!;

    expect(
      await launcher.availabilityFor(sleepMax),
      EcosystemAvailability.unknown,
    );
  });
}
