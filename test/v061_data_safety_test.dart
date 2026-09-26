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

  test('data safety audit detects missing and orphan local media', () async {
    final store = AgendaStore();
    await store.load();

    final orphanBytes = Uint8List.fromList(List<int>.filled(64, 11));
    final orphanId = await MediaAssetStore.instance.put(orphanBytes);

    await store.saveJournal(
      DateTime(2026, 10, 10),
      DayJournal(
        blocks: [
          DiaryBlock(
            id: 'missing-photo',
            type: DiaryBlockType.photo,
            createdAt: DateTime(2026, 10, 10, 10),
            mediaAssetId: 'sha256_missing_media',
          ),
        ],
      ),
    );

    final report = await store.auditDataSafety();
    expect(report.integrityHealthy, isFalse);
    expect(report.missingMediaIds, contains('sha256_missing_media'));
    expect(report.orphanMediaIds, contains(orphanId));
    store.dispose();
  });

  test('data safety audit detects corrupt referenced content-addressed media',
      () async {
    final store = AgendaStore();
    await store.load();

    const corruptId = 'sha256_deadbeef';
    await MediaAssetStore.instance.putNamed(
      corruptId,
      Uint8List.fromList(List<int>.generate(96, (i) => i)),
    );
    await store.saveJournal(
      DateTime(2026, 10, 11),
      DayJournal(
        blocks: [
          DiaryBlock(
            id: 'corrupt-photo',
            type: DiaryBlockType.photo,
            createdAt: DateTime(2026, 10, 11, 10),
            mediaAssetId: corruptId,
          ),
        ],
      ),
    );

    final report = await store.auditDataSafety();
    expect(report.corruptMediaIds, contains(corruptId));
    expect(report.missingMediaIds, isNot(contains(corruptId)));
    expect(report.integrityHealthy, isFalse);
    store.dispose();
  });

  test('new ZIP backup self-verifies before distribution', () async {
    final store = AgendaStore();
    await store.load();

    await store.upsert(
      AgendaItem(
        id: 'safe-item',
        title: 'Dato protetto',
        note: '',
        date: DateTime(2026, 10, 12),
        type: ItemType.task,
      ),
    );

    final bytes = await store.createBackupZip();
    final summary = store.verifyBackupZip(bytes);
    expect(summary.itemCount, 1);
    expect(summary.journalCount, 0);
    store.dispose();
  });
}
