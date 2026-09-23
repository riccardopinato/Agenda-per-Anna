import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agenda_per_anna/local_state_store.dart';
import 'package:agenda_per_anna/main.dart';
import 'package:agenda_per_anna/media_asset_store.dart';
import 'package:agenda_per_anna/media_asset_backend_io.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await LocalStateStore.instance.resetForTesting();
    await MediaAssetStore.instance.resetForTesting();
    SharedPreferences.setMockInitialValues({});
  });

  test('media store deduplicates content and preserves remote offline cache',
      () async {
    final bytes = Uint8List.fromList([1, 2, 3, 4, 5, 6]);

    final first = await MediaAssetStore.instance.put(bytes);
    final second = await MediaAssetStore.instance.put(bytes);

    expect(first, second);
    expect(await MediaAssetStore.instance.read(first), orderedEquals(bytes));

    final remoteId =
        MediaAssetStore.instance.namedAssetId('remote', 'shared/path.jpg');
    await MediaAssetStore.instance.putNamed(remoteId, bytes);

    await MediaAssetStore.instance.prune({first});

    expect(await MediaAssetStore.instance.read(first), isNotNull);
    expect(await MediaAssetStore.instance.read(remoteId), isNotNull);
  });


  test('native atomic media replacement does not keep stale equal-size bytes',
      () async {
    final directory = await Directory.systemTemp.createTemp(
      'annas_diary_media_test_',
    );
    addTearDown(() => directory.delete(recursive: true));

    final file = File(
      '${directory.path}${Platform.pathSeparator}remote_cache.bin',
    );
    final first = Uint8List.fromList([1, 2, 3, 4]);
    final second = Uint8List.fromList([9, 8, 7, 6]);

    await writeMediaAssetFileAtomically(file, first);
    await writeMediaAssetFileAtomically(file, second);

    expect(await file.readAsBytes(), orderedEquals(second));
  });

  test('legacy private photo and sketch media migrate out of journal JSON',
      () async {
    final sourceBytes = Uint8List.fromList([9, 8, 7, 6, 5, 4, 3, 2, 1]);
    final encoded = base64Encode(sourceBytes);
    final date = DateTime(2026, 9, 23);

    SharedPreferences.setMockInitialValues({
      'journals_v1': jsonEncode({
        '2026-09-23': {
          'beautiful': 'Test media',
          'note': '',
          'mood': null,
          'gratitude': <String>[],
          'completedHabitIds': <String>[],
          'blocks': [
            {
              'id': 'legacy-photo',
              'type': 'photo',
              'createdAt': date.toUtc().toIso8601String(),
              'text': 'Foto',
              'imageBase64': encoded,
              'pages': <Object?>[],
            },
            {
              'id': 'legacy-sketch',
              'type': 'sketch',
              'createdAt': date.toUtc().toIso8601String(),
              'text': '',
              'imageBase64': '',
              'pages': [
                {
                  'id': 'page-1',
                  'paper': 'plain',
                  'strokes': <Object?>[],
                  'textElements': <Object?>[],
                  'imageElements': [
                    {
                      'id': 'sketch-image',
                      'imageBase64': encoded,
                      'x': 0.1,
                      'y': 0.2,
                      'width': 0.5,
                      'height': 0.3,
                    },
                  ],
                },
              ],
            },
          ],
        },
      }),
    });

    final store = AgendaStore();
    await store.load();

    final journal = store.journal(date);
    final photo = journal.blocks.firstWhere((block) => block.id == 'legacy-photo');
    final sketch =
        journal.blocks.firstWhere((block) => block.id == 'legacy-sketch');
    final sketchImage = sketch.pages.single.imageElements.single;

    expect(photo.imageBase64, isEmpty);
    expect(photo.mediaAssetId, isNotEmpty);
    expect(photo.mediaThumbnailAssetId, isNotEmpty);
    expect(sketchImage.imageBase64, isEmpty);
    expect(sketchImage.mediaAssetId, isNotEmpty);

    final state = await LocalStateStore.instance.open(
      legacyPreferences: await SharedPreferences.getInstance(),
    );
    final localJournalJson = state.getString('journals_v1')!;
    expect(localJournalJson, isNot(contains(encoded)));
    expect(localJournalJson, contains(photo.mediaAssetId));
    expect(localJournalJson, contains(sketchImage.mediaAssetId));

    final backup = jsonDecode(await store.createBackupJson())
        as Map<String, dynamic>;
    final data = Map<String, dynamic>.from(backup['data'] as Map);
    final journals = Map<String, dynamic>.from(data['journals'] as Map);
    final portableJournal =
        Map<String, dynamic>.from(journals['2026-09-23'] as Map);
    final blocks = (portableJournal['blocks'] as List)
        .map((value) => Map<String, dynamic>.from(value as Map))
        .toList();

    final portablePhoto =
        blocks.firstWhere((block) => block['id'] == 'legacy-photo');
    expect(portablePhoto['imageBase64'], encoded);
    expect(portablePhoto.containsKey('mediaAssetId'), isFalse);
    expect(portablePhoto.containsKey('mediaThumbnailAssetId'), isFalse);

    final portableSketch =
        blocks.firstWhere((block) => block['id'] == 'legacy-sketch');
    final portablePages = portableSketch['pages'] as List;
    final portablePage =
        Map<String, dynamic>.from(portablePages.single as Map);
    final portableImages = portablePage['imageElements'] as List;
    final portableImage =
        Map<String, dynamic>.from(portableImages.single as Map);
    expect(portableImage['imageBase64'], encoded);
    expect(portableImage.containsKey('mediaAssetId'), isFalse);

    store.dispose();
  });

  test('private and shared offline queues persist media references, not bytes',
      () async {
    final bytes = Uint8List.fromList([11, 22, 33, 44, 55]);
    final encoded = base64Encode(bytes);
    final assetId = await MediaAssetStore.instance.put(bytes);

    final store = AgendaStore();
    await store.load();

    final date = DateTime(2026, 9, 23);
    await store.saveJournal(
      date,
      DayJournal(
        blocks: [
          DiaryBlock(
            id: 'photo',
            type: DiaryBlockType.photo,
            createdAt: date,
            mediaAssetId: assetId,
            mediaThumbnailAssetId: assetId,
          ),
          DiaryBlock(
            id: 'sketch',
            type: DiaryBlockType.sketch,
            createdAt: date,
            pages: [
              DiarySketchPage(
                id: 'page',
                imageElements: [
                  DiarySketchImageElement(
                    id: 'image',
                    mediaAssetId: assetId,
                    x: 0.1,
                    y: 0.1,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    final state = await LocalStateStore.instance.open(
      legacyPreferences: await SharedPreferences.getInstance(),
    );
    final privateQueue = state.getString('cloud_sync_queue_v1')!;
    expect(privateQueue, isNot(contains(encoded)));
    expect(privateQueue, contains(assetId));

    await store.enqueueSharedMediaUpload(
      SharedMediaPendingUpload(
        id: 'upload-1',
        spaceId: 'space-1',
        entryId: 'entry-1',
        title: 'Foto',
        note: '',
        date: date,
        mediaAssetId: assetId,
        thumbnailAssetId: assetId,
        oldMediaPath: '',
        createdAt: date,
      ),
    );

    final mediaQueue =
        state.getString(store.sharedMediaPendingStorageKey('space-1'))!;
    expect(mediaQueue, isNot(contains(encoded)));
    expect(mediaQueue, contains(assetId));

    await store.enqueueSharedUpsert(
      spaceId: 'space-1',
      entry: SharedEntry(
        id: 'entry-2',
        type: SharedEntryType.photo,
        title: 'Foto',
        note: '',
        date: date,
        mediaThumbnailAssetId: assetId,
      ),
    );

    final sharedQueue =
        state.getString(store.sharedPendingStorageKey('space-1'))!;
    expect(sharedQueue, isNot(contains(encoded)));
    expect(sharedQueue, contains('_mediaThumbnailAssetId'));
    expect(sharedQueue, contains(assetId));

    store.dispose();
  });
}
