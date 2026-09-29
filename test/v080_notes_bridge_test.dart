import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agenda_per_anna/local_state_store.dart';
import 'package:agenda_per_anna/main.dart';
import 'package:agenda_per_anna/media_asset_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('it_IT');
  });

  setUp(() async {
    await LocalStateStore.instance.resetForTesting();
    await MediaAssetStore.instance.resetForTesting();
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    await LocalStateStore.instance.resetForTesting();
    await MediaAssetStore.instance.resetForTesting();
  });

  test('Inbox bridge exports portable text without changing storage', () async {
    final store = AgendaStore();
    await store.load();

    final entry = InboxEntry(
      id: 'inbox-1',
      text: 'Idea per il progetto personale',
      createdAt: DateTime(2026, 9, 29, 14, 30),
      tags: const ['idea', 'personale'],
    );

    final text = store.notesBridgeTextForInbox(entry);

    expect(text, contains('Idea per il progetto personale'));
    expect(text, contains("Fonte: Anna's Diary · Inbox"));
    expect(text, contains('#idea #personale'));
    expect(text, contains('Notes Bridge Lite'));

    store.dispose();
  });

  test('Diary bridge exports text, tags and places but no media payload', () async {
    final store = AgendaStore();
    await store.load();

    final block = DiaryBlock(
      id: 'diary-1',
      type: DiaryBlockType.photo,
      createdAt: DateTime(2026, 8, 14, 18, 45),
      text: 'Tramonto in montagna',
      mediaAssetId: 'asset-secret-id',
      imageBase64: 'base64-secret-payload',
      tags: const ['viaggio'],
      places: const [DiaryPlaceReference(name: 'Valle Aurina')],
    );

    final text = store.notesBridgeTextForDiary(
      DateTime(2026, 8, 14),
      block,
    );

    expect(text, contains('Tramonto in montagna'));
    expect(text, contains('#viaggio'));
    expect(text, contains('Luoghi: Valle Aurina'));
    expect(text, contains('la foto originale resta'));
    expect(text, isNot(contains('asset-secret-id')));
    expect(text, isNot(contains('base64-secret-payload')));

    store.dispose();
  });

  test('Sketch bridge copies only textual sketch content', () async {
    final store = AgendaStore();
    await store.load();

    final block = DiaryBlock(
      id: 'sketch-1',
      type: DiaryBlockType.sketch,
      createdAt: DateTime(2026, 9, 1, 9),
      pages: const [
        DiarySketchPage(
          id: 'page-1',
          textElements: [
            DiarySketchTextElement(
              id: 'text-1',
              text: 'Idea centrale',
              x: 20,
              y: 30,
            ),
          ],
          strokes: [
            DiarySketchStroke(
              tool: DiarySketchTool.pen,
              colorValue: 0xFF222222,
              width: 3,
              points: [
                DiarySketchPoint(1, 1),
                DiarySketchPoint(2, 2),
              ],
            ),
          ],
        ),
      ],
    );

    final text = store.notesBridgeTextForDiary(
      DateTime(2026, 9, 1),
      block,
    );

    expect(text, contains('Idea centrale'));
    expect(text, contains('vengono copiati solo i testi dello sketch'));
    expect(text, isNot(contains('DiarySketchPoint')));

    store.dispose();
  });

  test('v0.80 bridge introduces no sync or persistence subsystem', () {
    final domain = File('lib/src/notes_bridge.dart').readAsStringSync();
    final inbox =
        File('lib/src/screens/home_inbox_search.dart').readAsStringSync();
    final diary =
        File('lib/src/diary/diary_components.dart').readAsStringSync();

    expect(domain, contains('class NotesBridgePayload'));
    expect(domain, contains('notesBridgeTextForInbox'));
    expect(domain, contains('notesBridgeTextForDiary'));
    expect(inbox, contains('strings.copyForNotes'));
    expect(diary, contains("'Copia per Notes'"));

    for (final forbidden in [
      'notes_bridge_v1',
      '_notesBridgeKey',
      'supabase',
      'writeBatch(',
      'setString(',
      'syncQueue',
      'http',
    ]) {
      expect(
        domain.toLowerCase(),
        isNot(contains(forbidden.toLowerCase())),
      );
    }
  });
}
