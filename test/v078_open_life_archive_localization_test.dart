import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
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

  test('language preference is backward compatible and persistent', () {
    final legacy = AgendaPreferences.fromJson(const {});
    expect(legacy.language, AppLanguage.system);

    final english = legacy.copyWith(language: AppLanguage.english);
    final roundTrip = AgendaPreferences.fromJson(english.toJson());
    expect(roundTrip.language, AppLanguage.english);
  });

  test('unsupported system locales fall back to English', () {
    expect(
      AgendaLocalization.resolveLocale(const Locale('ja')).languageCode,
      'en',
    );
    expect(
      AgendaLocalization.resolveLocale(const Locale('fr')).languageCode,
      'fr',
    );
    expect(
      AgendaLocalization.supportedLocales.map((e) => e.languageCode),
      containsAll(['it', 'en', 'es', 'fr', 'de', 'pt']),
    );
  });

  test('Open Life Archive is readable and separate from restore backup',
      () async {
    final store = AgendaStore();
    await store.load();
    final day = DateTime(2025, 9, 29);

    final photoBytes = Uint8List.fromList([
      0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46,
    ]);
    final assetId = await MediaAssetStore.instance.put(photoBytes);

    await store.saveJournal(
      day,
      DayJournal(
        blocks: [
          DiaryBlock(
            id: 'open-life',
            type: DiaryBlockType.photo,
            createdAt: DateTime(2025, 9, 29, 12),
            text: 'Giornata da ricordare',
            mediaAssetId: assetId,
            places: const [DiaryPlaceReference(name: 'Campo Tures')],
          ),
        ],
      ),
    );

    final bytes = await store.createOpenLifeArchive();
    final archive = ZipDecoder().decodeBytes(bytes, verify: true);
    final names = archive.files.where((e) => e.isFile).map((e) => e.name).toSet();

    expect(names, contains('README.txt'));
    expect(names, contains('life.txt'));
    expect(names, contains('life.json'));
    expect(names, contains('years/2025.md'));
    expect(names.any((name) => name == 'media/$assetId.jpg'), isTrue);
    expect(names, isNot(contains('manifest.json')));
    expect(names, isNot(contains('data.json')));

    final lifeJsonEntry =
        archive.files.firstWhere((entry) => entry.name == 'life.json');
    final document = jsonDecode(
      utf8.decode(lifeJsonEntry.readBytes() ?? const <int>[]),
    ) as Map<String, dynamic>;
    expect(document['format'], 'annas_diary_open_life_archive');
    expect(document['restoreBackup'], isFalse);
    final data = Map<String, dynamic>.from(document['data'] as Map);
    expect(data.containsKey('trash'), isFalse);
    expect(data.containsKey('preferences'), isFalse);

    final yearEntry =
        archive.files.firstWhere((entry) => entry.name == 'years/2025.md');
    final yearText = utf8.decode(yearEntry.readBytes() ?? const <int>[]);
    expect(yearText, contains('Giornata da ricordare'));
    expect(yearText, contains('Campo Tures'));
    expect(yearText, contains('../media/$assetId.jpg'));

    store.dispose();
  });

  test('v0.78 does not create a parallel archive persistence store', () {
    final store = File('lib/src/agenda_store.dart').readAsStringSync();
    final backup =
        File('lib/src/store/backup_domain.dart').readAsStringSync();
    final locale =
        File('lib/src/app_localization.dart').readAsStringSync();

    expect(backup, contains('createOpenLifeArchive'));
    expect(backup, contains("'restoreBackup': false"));
    expect(locale, contains('AppLanguage.system'));
    expect(store.toLowerCase(), isNot(contains('open_life_archive_v1')));
    expect(store.toLowerCase(), isNot(contains('_openlifearchivekey')));
  });
}
