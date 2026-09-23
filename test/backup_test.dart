import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:agenda_per_anna/backup_service.dart';
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

  test('backup document contains and restores core agenda data', () async {
    final source = AgendaStore();
    source.items.add(
      AgendaItem(
        id: 'event-1',
        title: 'Cena',
        note: 'Ricordo',
        date: DateTime(2026, 9, 21),
        type: ItemType.appointment,
        category: AgendaCategory.couple,
        start: const TimeOfDay(hour: 20, minute: 0),
      ),
    );
    source.journals['2026-09-21'] = const DayJournal(
      beautiful: 'Una bella serata',
      mood: DayMood.great,
      gratitude: ['Tempo insieme'],
    );
    source.months['2026-09'] = const MonthlyData(
      intention: 'Stare bene',
      goals: ['Leggere'],
      films: ['Un film'],
    );
    source.habits.add(
      const HabitDefinition(id: 'read', name: 'Leggere'),
    );

    final raw = await source.createBackupJson();
    final summary = source.inspectBackup(raw);

    expect(summary.itemCount, 1);
    expect(summary.journalCount, 1);
    expect(summary.monthCount, 1);
    expect(summary.habitCount, 1);

    final restored = AgendaStore();
    await restored.restoreBackup(raw, merge: false);

    expect(restored.items.single.title, 'Cena');
    expect(restored.journal(DateTime(2026, 9, 21)).mood, DayMood.great);
    expect(restored.month(2026, 9).films, ['Un film']);
    expect(restored.habits.single.name, 'Leggere');
    expect(restored.localSnapshots, hasLength(1));
  });

  test('invalid backup is rejected before restore', () {
    final store = AgendaStore();

    expect(
      () => store.inspectBackup('{"format":"something_else"}'),
      throwsA(isA<FormatException>()),
    );
  });

  test('ZIP backup separates media from JSON and restores it', () async {
    final photoBytes = Uint8List.fromList(
      List<int>.generate(128, (index) => (index * 13) % 251),
    );
    final encoded = base64Encode(photoBytes);
    final assetId = await MediaAssetStore.instance.put(photoBytes);

    final source = AgendaStore();
    source.journals['2026-09-23'] = DayJournal(
      beautiful: 'Backup ZIP',
      blocks: [
        DiaryBlock(
          id: 'photo-zip',
          type: DiaryBlockType.photo,
          createdAt: DateTime(2026, 9, 23, 12),
          text: 'Foto separata',
          mediaAssetId: assetId,
          mediaThumbnailAssetId: assetId,
        ),
      ],
    );

    final zip = await source.createBackupZip();
    final decoded = BackupFileService.instance.decodeZipBackup(zip);
    final summary = source.inspectBackupZip(zip);

    expect(summary.journalCount, 1);
    expect(decoded.media.keys, contains(assetId));
    expect(decoded.dataJson, isNot(contains(encoded)));
    expect(decoded.dataJson, contains(assetId));

    await MediaAssetStore.instance.resetForTesting();
    expect(await MediaAssetStore.instance.read(assetId), isNull);

    final restored = AgendaStore();
    await restored.restoreBackupZip(zip, merge: false);

    final block =
        restored.journal(DateTime(2026, 9, 23)).blocks.single;
    expect(block.mediaAssetId, assetId);
    expect(
      await MediaAssetStore.instance.read(assetId),
      orderedEquals(photoBytes),
    );

    source.dispose();
    restored.dispose();
  });

  test('ZIP backup rejects missing or inconsistent manifest data', () {
    final invalid = BackupFileService.instance.buildZipBackup(
      manifestJson: jsonEncode({
        'format': 'wrong_format',
        'bundleVersion': 1,
        'dataSha256': 'invalid',
        'media': <Object>[],
      }),
      dataJson: jsonEncode({
        'format': 'agenda_per_anna_backup',
        'schemaVersion': 1,
        'appVersion': 'test',
        'exportedAt': DateTime(2026, 9, 23).toIso8601String(),
        'data': <String, Object>{},
      }),
      media: const <String, Uint8List>{},
    );

    final store = AgendaStore();
    expect(
      () => store.inspectBackupZip(invalid),
      throwsA(isA<FormatException>()),
    );
    store.dispose();
  });

}
