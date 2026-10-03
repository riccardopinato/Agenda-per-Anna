import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agenda_per_anna/ecosystem/ecosystem_bridge.dart';
import 'package:agenda_per_anna/local_state_store.dart';
import 'package:agenda_per_anna/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await LocalStateStore.instance.resetForTesting();
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    await LocalStateStore.instance.resetForTesting();
  });

  EcosystemTransferPackage wonderlogJourney({
    EcosystemTransferMode mode = EcosystemTransferMode.copy,
    int revision = 1790929800000,
  }) {
    const deepLink = 'wonderlog://journey/journey-42';
    return EcosystemTransferPackage(
      targetApp: EcosystemAppId.annasDiary,
      createdAtUtc: DateTime.utc(2026, 10, 3, 9),
      envelope: EcosystemEnvelope(
        sourceApp: EcosystemAppId.wonderlog,
        sourceEntityType: EcosystemEntityType.journey,
        sourceEntityId: 'journey-42',
        createdAtUtc: DateTime.utc(2026, 8, 10),
        title: 'Valle Aurina',
        text: 'Diario del viaggio.',
        tags: const ['travel', 'journey'],
        places: const [
          EcosystemPlace(
            name: 'Campo Tures',
            latitude: 46.919,
            longitude: 11.955,
          ),
        ],
        media: const [
          EcosystemMediaReference(
            id: 'photo-1',
            kind: 'photo',
            mimeType: 'image/jpeg',
            fileName: 'photo.jpg',
            handoff: EcosystemMediaHandoff(
              kind: EcosystemMediaHandoffKind.omitted,
              reason: 'explicit_binary_handoff_not_enabled_in_v1',
            ),
          ),
        ],
        sourceDeepLink: deepLink,
        transferMode: mode,
        revision: revision,
        provenance: EcosystemProvenance(
          ownerApp: EcosystemAppId.wonderlog,
          ownerEntityType: EcosystemEntityType.journey,
          ownerEntityId: 'journey-42',
          ownerRevision: revision,
          canonicalDeepLink: deepLink,
        ),
        fallback: const EcosystemFallback(
          plainText: 'Valle Aurina\n\nDiario del viaggio.',
          sourceDeepLink: deepLink,
        ),
      ),
    );
  }

  test('Golden A/B identities match Wonderlog candidate vectors', () {
    final copy = wonderlogJourney();
    final link = wonderlogJourney(mode: EcosystemTransferMode.link);

    expect(
      copy.envelope.bridgeId,
      'ecosystem:v1:wonderlog:journey:journey-42',
    );
    expect(
      copy.envelope.idempotencyKey,
      'ecosystem:v1:wonderlog:journey:journey-42:1790929800000:copy',
    );
    expect(link.envelope.bridgeId, copy.envelope.bridgeId);
    expect(
      link.envelope.idempotencyKey,
      'ecosystem:v1:wonderlog:journey:journey-42:1790929800000:link',
    );
    expect(inspectAnnaEcosystemPackage(copy).ready, isTrue);
    expect(inspectAnnaEcosystemPackage(link).ready, isTrue);
  });

  test('Wonderlog -> Anna URI uses canonical import route and round-trips', () {
    final package = wonderlogJourney();
    final uri = EcosystemLocalTransportCodec.targetUri(package);

    expect(uri.scheme, 'annasdiary');
    expect(uri.host, 'ecosystem');
    expect(uri.path, '/import');
    expect(uri.queryParameters['payload'], isNotEmpty);

    final decoded = EcosystemLocalTransportCodec.decodeTargetUri(uri);
    expect(decoded.targetApp, EcosystemAppId.annasDiary);
    expect(decoded.envelope.bridgeId, package.envelope.bridgeId);
    expect(decoded.envelope.idempotencyKey, package.envelope.idempotencyKey);
  });

  test('Wonderlog COPY materializes once and preserves provenance', () async {
    final store = AgendaStore();
    await store.load();
    final package = wonderlogJourney();

    final first = await store.importEcosystemTransferPackage(package);
    final second = await store.importEcosystemTransferPackage(package);

    expect(first.outcome, LifeBridgeImportOutcome.imported);
    expect(second.outcome, LifeBridgeImportOutcome.duplicate);
    expect(first.destinationType, 'diary_block');

    final state = await store.loadLifeBridgeState();
    expect(state.history, hasLength(1));
    expect(state.history.single.bridgeId, package.envelope.bridgeId);
    expect(
      state.history.single.idempotencyKey,
      package.envelope.idempotencyKey,
    );
    expect(state.history.single.sourceAppId, 'wonderlog');
    expect(state.activeLinks, isEmpty);

    final imported = store
        .journal(DateTime(2026, 8, 10))
        .blocks
        .where((block) => block.id == first.destinationId)
        .single;
    expect(imported.text, contains('Valle Aurina'));
    expect(imported.text, contains('Campo Tures'));
    expect(imported.tags, contains('source:wonderlog'));

    store.dispose();
  });

  test('COPY and LINK remain distinct durable deliveries', () async {
    final store = AgendaStore();
    await store.load();

    final copy = await store.importEcosystemTransferPackage(
      wonderlogJourney(),
    );
    final link = await store.importEcosystemTransferPackage(
      wonderlogJourney(mode: EcosystemTransferMode.link),
    );
    final duplicateLink = await store.importEcosystemTransferPackage(
      wonderlogJourney(mode: EcosystemTransferMode.link),
    );

    expect(copy.outcome, LifeBridgeImportOutcome.imported);
    expect(link.outcome, LifeBridgeImportOutcome.imported);
    expect(duplicateLink.outcome, LifeBridgeImportOutcome.duplicate);

    final state = await store.loadLifeBridgeState();
    expect(state.history, hasLength(2));
    expect(
      state.history.map((record) => record.idempotencyKey).toSet(),
      hasLength(2),
    );
    expect(state.activeLinks, hasLength(1));
    expect(state.activeLinks.single.source.appId, 'wonderlog');
    expect(
      state.activeLinks.single.source.deepLink,
      'wonderlog://journey/journey-42',
    );

    store.dispose();
  });

  test('new Wonderlog revision is not suppressed by old revision', () async {
    final store = AgendaStore();
    await store.load();

    final first = await store.importEcosystemTransferPackage(
      wonderlogJourney(revision: 1790929800000),
    );
    final second = await store.importEcosystemTransferPackage(
      wonderlogJourney(revision: 1790929800001),
    );

    expect(first.outcome, LifeBridgeImportOutcome.imported);
    expect(second.outcome, LifeBridgeImportOutcome.imported);
    expect((await store.loadLifeBridgeState()).history, hasLength(2));

    store.dispose();
  });

  test('Golden D/E reject private media and non-explicit sharing', () {
    final invalidMedia = EcosystemEnvelope(
      sourceApp: EcosystemAppId.wonderlog,
      sourceEntityType: EcosystemEntityType.memory,
      sourceEntityId: 'm1',
      createdAtUtc: DateTime.utc(2026),
      title: 'Memory',
      media: const [
        EcosystemMediaReference(
          id: 'p1',
          kind: 'photo',
          handoff: EcosystemMediaHandoff(
            kind: EcosystemMediaHandoffKind.cloudObject,
            locator: 'file:///private/photo.jpg',
          ),
        ),
      ],
    );
    expect(
      EcosystemContractValidator.validate(invalidMedia).reason,
      'private_media_reference_forbidden',
    );

    final privateEnvelope = EcosystemEnvelope(
      sourceApp: EcosystemAppId.wonderlog,
      sourceEntityType: EcosystemEntityType.memory,
      sourceEntityId: 'm2',
      createdAtUtc: DateTime.utc(2026),
      title: 'Private',
      privacyScope: EcosystemPrivacyScope.private,
    );
    expect(
      EcosystemContractValidator.validate(privateEnvelope).reason,
      'explicit_share_required',
    );
  });

  test('Anna -> Wonderlog Golden C package matches shared semantics', () async {
    final store = AgendaStore();
    await store.load();
    final block = DiaryBlock(
      id: 'moment-42',
      type: DiaryBlockType.note,
      createdAt: DateTime.utc(2026, 10, 1, 18),
      text: 'Una sera insieme',
    );

    final package = store.exportEcosystemDiaryBlock(
      block,
      targetApp: EcosystemAppId.wonderlog,
      revision: 7,
      packagedAtUtc: DateTime.utc(2026, 10, 3, 9),
    );

    expect(package.targetApp, EcosystemAppId.wonderlog);
    expect(package.envelope.sourceApp, EcosystemAppId.annasDiary);
    expect(package.envelope.sourceEntityType, EcosystemEntityType.note);
    expect(package.envelope.sourceEntityId, 'moment-42');
    expect(
      package.envelope.bridgeId,
      'ecosystem:v1:annas_diary:note:moment-42',
    );
    expect(
      package.envelope.idempotencyKey,
      'ecosystem:v1:annas_diary:note:moment-42:7:copy',
    );
    expect(
      package.envelope.provenance.canonicalDeepLink,
      'annasdiary://moment/moment-42',
    );
    expect(
      EcosystemLocalTransportCodec.decode(
        EcosystemLocalTransportCodec.encode(package),
      ).envelope.idempotencyKey,
      package.envelope.idempotencyKey,
    );

    final wire = jsonEncode(package.toJson());
    expect(wire, isNot(contains('file://')));
    expect(wire, isNot(contains('content://')));
    expect(wire, isNot(contains('/data/')));
    expect(wire, isNot(contains('/private/')));

    store.dispose();
  });

  test('package targeted to another app is rejected before materialization',
      () async {
    final store = AgendaStore();
    await store.load();
    final source = wonderlogJourney();
    final wrongTarget = EcosystemTransferPackage(
      targetApp: EcosystemAppId.notes,
      createdAtUtc: source.createdAtUtc,
      envelope: source.envelope,
    );

    final inspection = inspectAnnaEcosystemPackage(wrongTarget);
    expect(inspection.status, AnnaEcosystemPackageStatus.wrongTarget);

    final result = await store.importEcosystemTransferPackage(wrongTarget);
    expect(result.outcome, LifeBridgeImportOutcome.unsupported);
    expect((await store.loadLifeBridgeState()).history, isEmpty);

    store.dispose();
  });
}
