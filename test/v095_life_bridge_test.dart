import 'dart:io';

import 'package:agenda_per_anna/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Life Bridge v1 codec round-trips COPY payloads', () {
    final payload = LifeBridgePayload(
      bridgeId: 'bridge-1',
      source: const LifeBridgeSource(
        appId: 'wonderlog',
        objectId: 'trip-memory-1',
        deepLink: 'wonderlog://memory/trip-memory-1',
        revision: '7',
      ),
      objectType: 'travel_memory',
      transferMode: LifeBridgeTransferMode.copy,
      title: 'Lago di Braies',
      text: 'Una mattina sul lago.',
      occurredAt: DateTime(2026, 8, 12, 9, 30),
      location: const LifeBridgeLocation(
        name: 'Lago di Braies',
        latitude: 46.6947,
        longitude: 12.0854,
      ),
      people: const ['Anna'],
      tags: const ['viaggio', 'dolomiti'],
      exportedAt: DateTime.utc(2026, 10, 2, 0, 0),
    );

    final decoded = LifeBridgePayload.decode(payload.encode());

    expect(decoded.protocolVersion, lifeBridgeProtocolVersion);
    expect(decoded.protocolMajor, 1);
    expect(decoded.supportedByAnna, isTrue);
    expect(decoded.source.appId, 'wonderlog');
    expect(decoded.objectType, 'travel_memory');
    expect(decoded.transferMode, LifeBridgeTransferMode.copy);
    expect(decoded.location?.name, 'Lago di Braies');
    expect(decoded.people, ['Anna']);
    expect(decoded.tags, contains('dolomiti'));
  });

  test('Life Bridge rejects unknown protocol major safely', () {
    expect(
      () => LifeBridgePayload.fromJson({
        'protocolVersion': '2.0',
        'bridgeId': 'future',
        'source': {
          'appId': 'future_app',
          'objectId': '1',
        },
        'objectType': 'moment',
        'transferMode': 'copy',
        'title': 'Future',
        'text': '',
        'occurredAt': DateTime(2026, 10, 2).toIso8601String(),
        'exportedAt': DateTime.utc(2026, 10, 2).toIso8601String(),
      }),
      throwsFormatException,
    );
  });

  test('unsupported object types decode but are not materialized by Anna', () {
    final payload = LifeBridgePayload(
      bridgeId: 'unknown-type',
      source: const LifeBridgeSource(
        appId: 'future_app',
        objectId: 'x',
      ),
      objectType: 'future_app.custom_object',
      transferMode: LifeBridgeTransferMode.link,
      title: 'Custom',
      text: '',
      occurredAt: DateTime(2026, 10, 2),
      exportedAt: DateTime.utc(2026, 10, 2),
    );

    expect(payload.supportedByAnna, isFalse);
  });

  test('Anna event export uses the canonical AgendaItem model', () {
    final store = AgendaStore();
    final item = AgendaItem(
      id: 'agenda-1',
      title: 'Castello di Tures',
      note: 'Visita',
      date: DateTime(2026, 8, 11),
      start: const TimeOfDay(hour: 10, minute: 15),
      type: ItemType.appointment,
      category: AgendaCategory.leisure,
    );

    final payload = store.exportLifeBridgeAgendaItem(
      item,
      transferMode: LifeBridgeTransferMode.link,
    );

    expect(payload.objectType, 'event');
    expect(payload.source.appId, 'annas_diary');
    expect(payload.source.objectId, item.id);
    expect(payload.transferMode, LifeBridgeTransferMode.link);
    expect(payload.title, item.title);
    expect(payload.tags, contains('leisure'));
  });

  test('v0.95 bridge reuses canonical diary and agenda write paths', () {
    final bridge = File('lib/src/life_bridge.dart').readAsStringSync();
    final explore =
        File('lib/src/screens/explore_screen.dart').readAsStringSync();
    final mainSource = File('lib/main.dart').readAsStringSync();

    expect(bridge, contains('await saveJournal('));
    expect(bridge, contains('await upsert(item);'));
    expect(bridge, contains('DiaryBlock('));
    expect(bridge, contains('DiaryPlaceReference('));
    expect(bridge, contains('LifeBridgeImportOutcome.duplicate'));
    expect(bridge, contains('life_bridge_links_v1:'));
    expect(bridge, isNot(contains('Supabase')));
    expect(bridge, isNot(contains('CloudSyncService')));
    final diary =
        File('lib/src/diary/diary_components.dart').readAsStringSync();
    final editors = File('lib/src/widgets_editors.dart').readAsStringSync();

    expect(explore, contains('LifeEcosystemScreen(store: store)'));
    expect(diary, contains('onCopyToLifeBridge'));
    expect(diary, contains('exportLifeBridgeDiaryBlock'));
    expect(editors, contains('exportLifeBridgeAgendaItem'));
    expect(mainSource, contains("part 'src/life_bridge.dart';"));
  });


}
