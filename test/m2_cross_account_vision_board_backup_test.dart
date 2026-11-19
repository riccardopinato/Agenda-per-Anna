import 'dart:typed_data';

import 'package:agenda_per_anna/backup_service.dart';
import 'package:agenda_per_anna/local_state_store.dart';
import 'package:agenda_per_anna/main.dart';
import 'package:agenda_per_anna/media_asset_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// M2 source regression: private Vision Board + backup scope A→B→A.
/// Uses synthetic bytes only. It does NOT certify real PWA installations,
/// live Supabase ACLs, actual Android file pickers or physical device recovery.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await LocalStateStore.instance.resetForTesting();
    await MediaAssetStore.instance.resetForTesting();
  });
  tearDown(() async {
    await LocalStateStore.instance.resetForTesting();
    await MediaAssetStore.instance.resetForTesting();
  });

  test('A-B-A Vision Board and ZIP exports never carry the other account data',
      () async {
    final store = AgendaStore();
    await store.load();
    await store.activateCloudAccount('m2-synthetic-a');
    final date = DateTime(2026, 11, 19);
    final bytes = Uint8List.fromList(<int>[11, 72, 19, 86, 2, 73, 9, 41]);
    final assetId = await MediaAssetStore.instance.put(bytes);

    final presetA = visionBoardPresetsFor(const AnnaStrings('it'))[1];
    final original = VisionBoardFoundation.draft(presetA, createdAt: date);
    final page = original.pages.single.copyWith(imageElements: [
      DiarySketchImageElement(
        id: 'm2-synthetic-image-a', mediaAssetId: assetId,
        x: 0.1, y: 0.2,
      ),
    ]);
    final boardA = original.copyWith(
      text: 'm2_private_marker_account_a',
      pages: [page],
    );
    final guardA = Cap0160TagEditGuard(store);
    expect(await VisionBoardFoundation.saveDraft(
      store, date, boardA, scopeGuard: guardA,
    ), isTrue);
    expect(VisionBoardFoundation.personalBoards(store).single.block.id,
        boardA.id);

    final backupA = BackupFileService.instance
        .decodeZipBackup(await store.createBackupZip());
    expect(backupA.dataJson, contains('m2_private_marker_account_a'));
    expect(backupA.media.keys, contains(assetId));
    expect(backupA.media[assetId], orderedEquals(bytes));

    await store.activateCloudAccount('m2-synthetic-b');
    expect(VisionBoardFoundation.personalBoards(store), isEmpty);
    expect(store.journal(date).blocks, isEmpty);
    final backupB = BackupFileService.instance
        .decodeZipBackup(await store.createBackupZip());
    expect(backupB.dataJson, isNot(contains('m2_private_marker_account_a')));
    expect(backupB.media.keys, isNot(contains(assetId)),
        reason: 'An unreferenced A image must never be copied into B backup');

    final boardB = VisionBoardFoundation.draft(
      visionBoardPresetsFor(const AnnaStrings('en'))[2],
      createdAt: date,
    ).copyWith(text: 'm2_private_marker_account_b');
    expect(await VisionBoardFoundation.saveDraft(
      store, date, boardB, scopeGuard: Cap0160TagEditGuard(store),
    ), isTrue);

    await store.activateCloudAccount('m2-synthetic-a');
    expect(VisionBoardFoundation.personalBoards(store).single.block.id,
        boardA.id);
    expect(store.journal(date).blocks.single.text,
        'm2_private_marker_account_a');
    expect(store.journal(date).blocks.map((e) => e.text),
        isNot(contains('m2_private_marker_account_b')));
    expect(await VisionBoardFoundation.saveDraft(
      store,
      date,
      VisionBoardFoundation.draft(presetA, createdAt: date),
      scopeGuard: guardA,
    ), isFalse, reason: 'Epoch guard captured before A→B→A must stay stale');

    final afterReturn = BackupFileService.instance
        .decodeZipBackup(await store.createBackupZip());
    expect(afterReturn.media.keys, contains(assetId));
    expect(afterReturn.dataJson, isNot(contains('m2_private_marker_account_b')));
    store.dispose();
  });
}
