import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:agenda_per_anna/local_state_store.dart';
import 'package:agenda_per_anna/main.dart';
import 'package:agenda_per_anna/media_asset_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await initializeDateFormatting('it_IT');
    await LocalStateStore.instance.resetForTesting();
    await MediaAssetStore.instance.resetForTesting();
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    await LocalStateStore.instance.resetForTesting();
    await MediaAssetStore.instance.resetForTesting();
  });

  test('open export keeps readable diary, structured data and separate media',
      () async {
    final photoBytes = Uint8List.fromList(
      <int>[0xff, 0xd8, 0xff, 0xe0, ...List<int>.filled(64, 7)],
    );
    final photoId = await MediaAssetStore.instance.put(photoBytes);

    final store = AgendaStore();
    store.items.add(
      AgendaItem(
        id: 'event-open-export',
        title: 'Cena a Torino',
        note: 'Prenotazione confermata',
        date: DateTime(2026, 10, 17),
        type: ItemType.appointment,
        category: AgendaCategory.couple,
        start: const TimeOfDay(hour: 20, minute: 30),
      ),
    );
    store.journals['2026-10-17'] = DayJournal(
      beautiful: 'Passeggiata serale',
      note: 'Una giornata da ricordare.',
      mood: DayMood.great,
      gratitude: const ['Tempo insieme'],
      blocks: [
        DiaryBlock(
          id: 'note-open-export',
          type: DiaryBlockType.note,
          createdAt: DateTime(2026, 10, 17, 18, 10),
          text: 'Arrivati in centro.',
          tags: const ['torino'],
          places: const [DiaryPlaceReference(name: 'Torino')],
        ),
        DiaryBlock(
          id: 'photo-open-export',
          type: DiaryBlockType.photo,
          createdAt: DateTime(2026, 10, 17, 18, 30),
          text: 'Piazza al tramonto',
          mediaAssetId: photoId,
          mediaThumbnailAssetId: photoId,
        ),
        DiaryBlock(
          id: 'sketch-open-export',
          type: DiaryBlockType.sketch,
          createdAt: DateTime(2026, 10, 17, 19),
          pages: const [
            DiarySketchPage(
              id: 'page-1',
              textElements: [
                DiarySketchTextElement(
                  id: 'text-1',
                  text: 'Ricordare questo posto',
                  x: 0.2,
                  y: 0.3,
                ),
              ],
            ),
          ],
        ),
      ],
    );

    final bytes = await store.createOpenExportZip();
    final archive = ZipDecoder().decodeBytes(bytes, verify: true);
    final byName = {
      for (final entry in archive.where((entry) => entry.isFile))
        entry.name: entry,
    };

    expect(byName.keys, containsAll(<String>[
      'manifest.json',
      'README.md',
      'data.json',
      'media/$photoId.jpg',
      'sketches/sketch-open-export.json',
    ]));

    final readme = utf8.decode(byName['README.md']!.readBytes()!);
    expect(readme, contains('# Anna\'s Diary — Open Export'));
    expect(readme, contains('Una giornata da ricordare.'));
    expect(readme, contains('Arrivati in centro.'));
    expect(readme, contains('![Piazza al tramonto](media/$photoId.jpg)'));
    expect(
      readme,
      contains(
        '[Dati vettoriali del disegno](sketches/sketch-open-export.json)',
      ),
    );
    expect(readme, contains('Ricordare questo posto'));
    expect(readme, contains('Cena a Torino'));

    final data = jsonDecode(
      utf8.decode(byName['data.json']!.readBytes()!),
    ) as Map<String, dynamic>;
    final payload = data['data'] as Map<String, dynamic>;
    expect(data['format'], 'annas_diary_open_export');
    expect(payload.containsKey('trash'), isFalse);
    expect(payload.containsKey('preferences'), isFalse);
    expect(payload['journals'].toString(), contains(photoId));

    final manifest = jsonDecode(
      utf8.decode(byName['manifest.json']!.readBytes()!),
    ) as Map<String, dynamic>;
    expect(manifest['format'], 'annas_diary_open_export_bundle');
    expect(
      (manifest['excludedScopes'] as List).cast<String>(),
      containsAll(<String>[
        'trash',
        'private_vault',
        'cycle_tracker',
        'shared_passwords',
      ]),
    );

    final exportedPhoto =
        Uint8List.fromList(byName['media/$photoId.jpg']!.readBytes()!);
    expect(exportedPhoto, orderedEquals(photoBytes));

    store.dispose();
  });

  test('open export fails closed when referenced local media is missing',
      () async {
    final store = AgendaStore();
    store.journals['2026-10-18'] = DayJournal(
      blocks: [
        DiaryBlock(
          id: 'missing-photo',
          type: DiaryBlockType.photo,
          createdAt: DateTime(2026, 10, 18, 12),
          mediaAssetId: 'sha256_missing_media',
        ),
      ],
    );

    await expectLater(
      store.createOpenExportZip(),
      throwsA(isA<FormatException>()),
    );

    store.dispose();
  });
}
