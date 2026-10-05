import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agenda_per_anna/ecosystem_service.dart';
import 'package:agenda_per_anna/main.dart';

void main() {
  test('ecosystem registry keeps stable unique app identities', () {
    final ids = EcosystemHubRegistry.apps.map((app) => app.appId).toList();

    expect(ids.toSet().length, ids.length);
    expect(
      EcosystemHubRegistry.byAppId('annas_diary')?.integrationStatus,
      EcosystemHubIntegrationStatus.active,
    );
    expect(
      EcosystemHubRegistry.byAppId('wonderlog')?.integrationStatus,
      EcosystemHubIntegrationStatus.certifiedCompatible,
    );
    expect(
      EcosystemHubRegistry.byAppId('notes')?.integrationStatus,
      EcosystemHubIntegrationStatus.planned,
    );
    expect(
      EcosystemHubRegistry.byAppId('trailpath')?.integrationStatus,
      EcosystemHubIntegrationStatus.planned,
    );
    expect(
      EcosystemHubRegistry.byAppId('sleepmax')?.integrationStatus,
      EcosystemHubIntegrationStatus.planned,
    );
    expect(
      EcosystemHubRegistry.byAppId('cashmate')?.integrationStatus,
      EcosystemHubIntegrationStatus.planned,
    );
  });

  test('Wonderlog registry reflects certified E1 without inventing root route', () {
    final wonderlog = EcosystemHubRegistry.byAppId('WONDERLOG');

    expect(wonderlog, isNotNull);
    expect(wonderlog!.protocolVersions, contains('1.0'));
    expect(wonderlog.contractLabel, contains('E1'));
    expect(wonderlog.receives, containsAll(<String>{'note', 'photo'}));
    expect(Uri.parse(wonderlog.probeUri!).scheme, 'wonderlog');
    expect(
      wonderlog.launchUri,
      isNull,
      reason:
          'Hub must open canonical source object links, not invent a Wonderlog root route.',
    );
  });

  test('Anna registry capabilities match certified Shared Core receive contract', () {
    final anna = EcosystemHubRegistry.byAppId('annas_diary')!;

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
    expect(anna.sends, containsAll(<String>{'note', 'photo'}));
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

  test('launcher opens an explicit canonical source deep link', () async {
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

    final wonderlog = EcosystemHubRegistry.byAppId('wonderlog')!;
    final result = await launcher.availabilityFor(wonderlog);

    expect(result, EcosystemAvailability.available);
    expect(launched, isFalse);
  });

  test('planned apps without a native probe remain unknown', () async {
    final launcher = EcosystemLauncher(
      canLaunch: (_) async => false,
    );

    for (final appId in <String>['notes', 'trailpath', 'sleepmax', 'cashmate']) {
      final app = EcosystemHubRegistry.byAppId(appId)!;
      expect(
        await launcher.availabilityFor(app),
        EcosystemAvailability.unknown,
      );
    }
  });

  test('Life Bridge state projects active links and history per source app', () {
    final now = DateTime(2026, 10, 5, 10);
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
          idempotencyKey: 'bridge-1:1:link',
          sourceAppId: 'wonderlog',
          sourceDeepLink: 'wonderlog://journey/journey-42',
          objectType: 'journey',
          transferMode: LifeBridgeTransferMode.link,
          destinationType: 'diary_block',
          destinationId: 'local-1',
          importedAt: now,
        ),
        LifeBridgeImportRecord(
          id: 'history-2',
          bridgeId: 'bridge-2',
          idempotencyKey: 'bridge-2:1:copy',
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
    expect(
      state.historyForApp('Wonderlog').single.sourceDeepLink,
      'wonderlog://journey/journey-42',
    );
  });

  test('history source deep link is backward-compatible and portable', () {
    final now = DateTime.utc(2026, 10, 5, 8);
    final record = LifeBridgeImportRecord(
      id: 'history-1',
      bridgeId: 'ecosystem:v1:wonderlog:journey:journey-42',
      idempotencyKey:
          'ecosystem:v1:wonderlog:journey:journey-42:7:copy',
      sourceAppId: 'wonderlog',
      sourceDeepLink: 'wonderlog://journey/journey-42',
      objectType: 'journey',
      transferMode: LifeBridgeTransferMode.copy,
      destinationType: 'diary_block',
      destinationId: 'local-1',
      importedAt: now,
    );

    final restored = LifeBridgeImportRecord.fromJson(record.toJson());
    expect(restored.sourceDeepLink, record.sourceDeepLink);

    final legacy = LifeBridgeImportRecord.fromJson(<String, dynamic>{
      'id': 'legacy',
      'bridgeId': 'legacy-bridge',
      'idempotencyKey': 'legacy-bridge',
      'sourceAppId': 'wonderlog',
      'objectType': 'journey',
      'transferMode': 'copy',
      'destinationType': 'diary_block',
      'destinationId': 'legacy-local',
      'importedAt': now.toIso8601String(),
    });
    expect(legacy.sourceDeepLink, isNull);
  });
}
