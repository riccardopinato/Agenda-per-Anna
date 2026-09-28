import 'dart:io';

import 'package:agenda_per_anna/app_version.dart';
import 'package:agenda_per_anna/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  test('v0.66 OCR metadata is backward compatible and portable', () {
    final legacy = DiaryBlock.fromJson({
      'id': 'legacy-photo',
      'type': 'photo',
      'createdAt': '2026-09-27T08:00:00.000Z',
      'text': 'Foto',
      'mediaAssetId': 'sha256_fake',
    });

    expect(legacy.ocrText, isEmpty);
    expect(legacy.ocrScanned, isFalse);

    final indexed = legacy.copyWith(
      ocrText: 'Via Roma 24 Padova',
      ocrScanned: true,
    );
    final restored = DiaryBlock.fromJson(indexed.toJson());

    expect(restored.ocrText, 'Via Roma 24 Padova');
    expect(restored.ocrScanned, isTrue);
  });

  test('v0.66 deterministic search includes recognized photo text', () async {
    await initializeDateFormatting('it_IT', null);
    final store = AgendaStore();
    store.journals['2026-09-27'] = DayJournal(
      blocks: [
        DiaryBlock(
          id: 'photo-1',
          type: DiaryBlockType.photo,
          createdAt: DateTime(2026, 9, 27, 10),
          text: 'Passeggiata',
          ocrText: 'Rifugio Lago di Neves',
          ocrScanned: true,
        ),
      ],
    );

    final hits = store.personalSearch('lago neves');
    expect(hits, hasLength(1));
    expect(hits.single.diaryBlockId, 'photo-1');
  });

  test('v0.66 uses bundled on-device Android OCR', () {
    final service = File('lib/photo_ocr_service.dart').readAsStringSync();
    final android =
        File('tool/prepare_android_platform.py').readAsStringSync();
    final search =
        File('lib/src/search_connections_domain.dart').readAsStringSync();
    final diary =
        File('lib/src/diary/diary_components.dart').readAsStringSync();

    expect(service, contains("MethodChannel('annas_diary/photo_ocr')"));
    expect(service, contains("'recognizeImage'"));
    expect(android, contains('com.google.mlkit:text-recognition:16.0.1'));
    expect(android, contains('TextRecognition.getClient'));
    expect(android, contains('InputImage.fromBitmap'));
    expect(search, contains('block.ocrText'));
    expect(search, contains('ensurePhotoOcrIndexed'));
    expect(diary, contains('ocrScanned: false'));
  });

  test('v0.66 release metadata is aligned', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(appReleaseVersion, '0.70.0');
    expect(pubspec, contains('version: 0.70.0+80'));
  });
}
