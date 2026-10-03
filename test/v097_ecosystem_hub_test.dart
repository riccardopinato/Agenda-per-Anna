import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agenda_per_anna/ecosystem_service.dart';
import 'package:agenda_per_anna/main.dart';

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
  test('Life Bridge state projects links and history per source app', () {
    final now = DateTime(2026, 10, 3, 10);
    final wonderlogLink = LifeBridgeLinkRecord(
      id: 'link-wonderlog',
      source: const LifeBridgeSource(
        appId: 'wonderlog',
        objectId: 'journey-42',
        deepLink: 'wonderlog://journey/journey-42',
      ),
      localObjectType: 'diary_block',
      localObjectId: 'local-1',
      status: LifeBridgeLinkStatus.active,
      cachedPayload: const <String, dynamic>{'objectType': 'journey'},
      createdAt: now,
      updatedAt: now,
    );
    final sleepLink = LifeBridgeLinkRecord(
      id: 'link-sleepmax',
      source: const LifeBridgeSource(
        appId: 'sleepmax',
        objectId: 'sleep-1',
      ),
      localObjectType: 'diary_block',
      localObjectId: 'local-2',
      status: LifeBridgeLinkStatus.sourceUnavailable,
      cachedPayload: const <String, dynamic>{'objectType': 'moment'},
      createdAt: now,
      updatedAt: now,
    );
    final unlinkedWonderlog = LifeBridgeLinkRecord(
      id: 'link-old',
      source: const LifeBridgeSource(
        appId: 'WONDERLOG',
        objectId: 'journey-old',
      ),
      localObjectType: 'diary_block',
      localObjectId: 'local-3',
      status: LifeBridgeLinkStatus.unlinked,
      cachedPayload: const <String, dynamic>{'objectType': 'journey'},
      createdAt: now,
      updatedAt: now,
    );

    final state = LifeBridgeState(
      links: <LifeBridgeLinkRecord>[
        wonderlogLink,
        sleepLink,
        unlinkedWonderlog,
      ],
      history: <LifeBridgeImportRecord>[
        LifeBridgeImportRecord(
          id: 'history-1',
          bridgeId: 'bridge-1',
          sourceAppId: 'wonderlog',
          objectType: 'journey',
          transferMode: LifeBridgeTransferMode.link,
          destinationType: 'diary_block',
          destinationId: 'local-1',
          importedAt: now,
        ),
        LifeBridgeImportRecord(
          id: 'history-2',
          bridgeId: 'bridge-2',
          sourceAppId: 'sleepmax',
          objectType: 'moment',
          transferMode: LifeBridgeTransferMode.copy,
          destinationType: 'diary_block',
          destinationId: 'local-2',
          importedAt: now,
        ),
      ],
    );

    expect(state.activeLinksForApp('WONDERLOG'), <LifeBridgeLinkRecord>[
      wonderlogLink,
    ]);
    expect(state.activeLinksForApp('sleepmax'), <LifeBridgeLinkRecord>[
      sleepLink,
    ]);
    expect(state.historyForApp('Wonderlog').length, 1);
    expect(state.historyForApp('Wonderlog').single.bridgeId, 'bridge-1');
  });

}
