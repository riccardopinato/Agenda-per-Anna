import 'dart:convert';

import 'package:agenda_per_anna/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> wonderlogJourneyPayload({
    String transferMode = 'copy',
  }) =>
      <String, dynamic>{
        'protocolVersion': '1.0',
        'bridgeId':
            'life-bridge:v1:wonderlog:journey:journey-42:1790939400000',
        'source': <String, dynamic>{
          'appId': 'wonderlog',
          'objectId': 'journey-42',
          'deepLink': 'wonderlog://journey/journey-42',
          'revision': '1790939400000',
        },
        'objectType': 'journey',
        'transferMode': transferMode,
        'title': 'Valle Aurina',
        'text': 'Diario del viaggio.',
        'occurredAt': '2026-08-10T00:00:00.000Z',
        'location': <String, dynamic>{
          'name': 'Campo Tures',
          'latitude': 46.919,
          'longitude': 11.955,
        },
        'media': <Map<String, dynamic>>[],
        'people': <String>[],
        'tags': <String>[
          'travel',
          'journey',
          'country:italia',
        ],
        'extensions': <String, dynamic>{
          'wonderlog': <String, dynamic>{
            'sourceEnvelopeId': 'wonderlog:journey:journey-42',
            'privacyScope': 'explicitShare',
            'mediaTransfer': 'none',
            'endAt': '2026-08-14T00:00:00.000Z',
            'country': 'Italia',
          },
        },
        'exportedAt': '2026-10-02T09:00:00.000Z',
      };

  test('Anna accepts the exact Wonderlog Journey COPY wire contract', () {
    final payload = LifeBridgePayload.decode(
      jsonEncode(wonderlogJourneyPayload()),
    );

    expect(payload.protocolVersion, lifeBridgeProtocolVersion);
    expect(payload.protocolMajor, 1);
    expect(payload.supportedByAnna, isTrue);
    expect(payload.source.appId, 'wonderlog');
    expect(payload.source.objectId, 'journey-42');
    expect(payload.source.deepLink, 'wonderlog://journey/journey-42');
    expect(payload.source.revision, '1790939400000');
    expect(payload.objectType, 'journey');
    expect(payload.transferMode, LifeBridgeTransferMode.copy);
    expect(payload.title, 'Valle Aurina');
    expect(payload.text, 'Diario del viaggio.');
    expect(payload.location?.name, 'Campo Tures');
    expect(payload.location?.latitude, 46.919);
    expect(payload.location?.longitude, 11.955);
    expect(payload.tags, containsAll(<String>['travel', 'journey']));
    expect(payload.extensions['wonderlog'], isA<Map>());
  });

  test('Anna accepts Wonderlog LINK without changing the source identity', () {
    final json = wonderlogJourneyPayload(transferMode: 'link');
    final payload = LifeBridgePayload.decode(jsonEncode(json));

    expect(payload.supportedByAnna, isTrue);
    expect(payload.transferMode, LifeBridgeTransferMode.link);
    expect(
      payload.bridgeId,
      'life-bridge:v1:wonderlog:journey:journey-42:1790939400000',
    );
    expect(payload.source.appId, 'wonderlog');
    expect(payload.source.objectId, 'journey-42');
  });

  test('Wonderlog bridge metadata does not become Anna canonical content', () {
    final payload = LifeBridgePayload.decode(
      jsonEncode(wonderlogJourneyPayload()),
    );

    final wonderlog =
        Map<String, dynamic>.from(payload.extensions['wonderlog'] as Map);

    expect(wonderlog['privacyScope'], 'explicitShare');
    expect(wonderlog['mediaTransfer'], 'none');
    expect(wonderlog['endAt'], '2026-08-14T00:00:00.000Z');
    expect(payload.media, isEmpty);
  });
}
