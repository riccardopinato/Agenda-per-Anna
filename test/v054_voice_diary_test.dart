import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agenda_per_anna/local_state_store.dart';
import 'package:agenda_per_anna/main.dart';
import 'package:agenda_per_anna/media_asset_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await LocalStateStore.instance.resetForTesting();
    await MediaAssetStore.instance.resetForTesting();
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    await LocalStateStore.instance.resetForTesting();
    await MediaAssetStore.instance.resetForTesting();
  });

  test('voice block metadata round-trips without inline local audio', () async {
    final bytes = Uint8List.fromList(List<int>.generate(512, (i) => i % 251));
    final assetId = await MediaAssetStore.instance.put(bytes);
    final block = DiaryBlock(
      id: 'voice-1',
      type: DiaryBlockType.voice,
      createdAt: DateTime(2026, 9, 26, 9, 30),
      text: 'Pensiero del mattino',
      mediaAssetId: assetId,
      audioDurationMs: 32100,
      audioMimeType: 'audio/mp4',
    );

    final local = block.toLocalJson();
    expect(local['audioBase64'], isEmpty);
    expect(local['mediaAssetId'], assetId);

    final restored = DiaryBlock.fromJson(local);
    expect(restored.type, DiaryBlockType.voice);
    expect(restored.hasVoiceMedia, isTrue);
    expect(restored.audioDurationMs, 32100);
    expect(restored.audioMimeType, 'audio/mp4');
  });

  test('voice media survives journal restart and ZIP backup restore', () async {
    final bytes = Uint8List.fromList(List<int>.generate(2048, (i) => i % 199));
    final assetId = await MediaAssetStore.instance.put(bytes);
    final day = DateTime(2026, 9, 26);

    final first = AgendaStore();
    await first.load();
    await first.saveJournal(
      day,
      DayJournal(
        blocks: [
          DiaryBlock(
            id: 'voice-backup',
            type: DiaryBlockType.voice,
            createdAt: DateTime(2026, 9, 26, 10),
            mediaAssetId: assetId,
            audioDurationMs: 12000,
          ),
        ],
      ),
    );

    final zip = await first.createBackupZip();
    expect(zip, isNotEmpty);
    first.dispose();

    await LocalStateStore.instance.resetForTesting();
    await MediaAssetStore.instance.resetForTesting();
    SharedPreferences.setMockInitialValues({});

    final second = AgendaStore();
    await second.load();
    await second.restoreBackupZip(zip, merge: false);

    final block = second.journal(day).blocks.single;
    expect(block.type, DiaryBlockType.voice);
    expect(block.audioDurationMs, 12000);
    final restoredBytes =
        await MediaAssetStore.instance.read(block.mediaAssetId);
    expect(restoredBytes, bytes);
    second.dispose();
  });

  test('voice deletion reuses diary Trash lifecycle', () async {
    final bytes = Uint8List.fromList(List<int>.filled(128, 7));
    final assetId = await MediaAssetStore.instance.put(bytes);
    final store = AgendaStore();
    await store.load();
    final day = DateTime(2026, 9, 26);

    await store.saveJournal(
      day,
      DayJournal(
        blocks: [
          DiaryBlock(
            id: 'voice-trash',
            type: DiaryBlockType.voice,
            createdAt: DateTime(2026, 9, 26, 11),
            mediaAssetId: assetId,
            audioDurationMs: 8000,
          ),
        ],
      ),
    );

    expect(await store.moveDiaryBlockToTrash(day, 'voice-trash'), isTrue);
    expect(store.journal(day).blocks, isEmpty);
    expect(store.trash.single.kind, TrashEntityKind.diaryBlock);

    expect(await store.restoreTrashEntry(store.trash.single.id), isTrue);
    final restored = store.journal(day).blocks.single;
    expect(restored.type, DiaryBlockType.voice);
    expect(await MediaAssetStore.instance.read(restored.mediaAssetId), bytes);
    store.dispose();
  });

  test('Android platform generator carries microphone and voice channel', () {
    final script =
        File('tool/prepare_android_platform.py').readAsStringSync();
    expect(script, contains('android.permission.RECORD_AUDIO'));
    expect(script, contains('annas_diary/voice_diary'));
    expect(script, contains('MediaRecorder'));
    expect(script, contains('MediaPlayer'));
  });
}
