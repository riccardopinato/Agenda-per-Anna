import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agenda_per_anna/local_state_store.dart';
import 'package:agenda_per_anna/main.dart';
import 'package:agenda_per_anna/media_asset_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    AgendaStore.restoreFailurePhaseForTesting = null;
    await LocalStateStore.instance.resetForTesting();
    await MediaAssetStore.instance.resetForTesting();
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    AgendaStore.restoreFailurePhaseForTesting = null;
    await LocalStateStore.instance.resetForTesting();
    await MediaAssetStore.instance.resetForTesting();
  });

  Future<
      ({
        Uint8List zip,
        Uint8List bytes,
        String assetId,
        DateTime day,
      })> buildPhotoBackup() async {
    final bytes = Uint8List.fromList(
      <int>[0xff, 0xd8, 0xff, 0xe0, ...List<int>.generate(96, (i) => i % 251)],
    );
    final assetId = await MediaAssetStore.instance.put(bytes);
    final day = DateTime(2026, 10, 7);
    final source = AgendaStore();
    source.journals[AgendaStore.dateKey(day)] = DayJournal(
      beautiful: 'Restore v21',
      blocks: [
        DiaryBlock(
          id: 'restore-photo',
          type: DiaryBlockType.photo,
          createdAt: day.add(const Duration(hours: 12)),
          text: 'Foto da ripristinare',
          mediaAssetId: assetId,
          mediaThumbnailAssetId: assetId,
        ),
      ],
    );
    final zip = await source.createBackupZip();
    source.dispose();
    await MediaAssetStore.instance.delete(assetId);
    return (zip: zip, bytes: bytes, assetId: assetId, day: day);
  }

  Future<LocalStateStore> localState() async =>
      LocalStateStore.instance.open(
        legacyPreferences: await SharedPreferences.getInstance(),
      );

  Future<void> seedBaseline(AgendaStore store) async {
    await store.load();
    await store.saveJournal(
      DateTime(2026, 1, 1),
      const DayJournal(beautiful: 'Baseline locale'),
    );
  }

  Future<Set<String>> stagingIds() async => (await MediaAssetStore.instance
          .listStoredAssetIds())
      .where((id) => id.startsWith(MediaAssetStore.restoreStagingPrefix))
      .toSet();

  test('v1.00-C successful ZIP restore leaves no staging or marker', () async {
    final fixture = await buildPhotoBackup();
    final target = AgendaStore();
    await seedBaseline(target);

    await target.restoreBackupZip(fixture.zip, merge: false);

    final restored = target.journal(fixture.day);
    expect(restored.blocks.single.mediaAssetId, fixture.assetId);
    expect(
      await MediaAssetStore.instance.read(fixture.assetId),
      orderedEquals(fixture.bytes),
    );
    expect(await stagingIds(), isEmpty);
    expect(
      (await localState()).getString('backup_restore_transaction_v1'),
      isNull,
    );

    target.dispose();
  });

  test('v1.00-C failure after canonical promotion rolls back media and state',
      () async {
    final fixture = await buildPhotoBackup();
    final target = AgendaStore();
    await seedBaseline(target);

    AgendaStore.restoreFailurePhaseForTesting = 'after_media_promotion';
    await expectLater(
      target.restoreBackupZip(fixture.zip, merge: false),
      throwsA(isA<StateError>()),
    );
    AgendaStore.restoreFailurePhaseForTesting = null;

    expect(
      target.journal(DateTime(2026, 1, 1)).beautiful,
      'Baseline locale',
    );
    expect(target.journal(fixture.day).blocks, isEmpty);
    expect(await MediaAssetStore.instance.read(fixture.assetId), isNull);
    expect(await stagingIds(), isEmpty);
    expect(
      (await localState()).getString('backup_restore_transaction_v1'),
      isNull,
    );

    target.dispose();
  });

  test('v1.00-C staging survives generic GC but load cleans interrupted stage',
      () async {
    final fixture = await buildPhotoBackup();
    final target = AgendaStore();
    await seedBaseline(target);

    AgendaStore.restoreFailurePhaseForTesting = 'crash_after_staging';
    await expectLater(
      target.restoreBackupZip(fixture.zip, merge: false),
      throwsA(anything),
    );
    AgendaStore.restoreFailurePhaseForTesting = null;

    final stagedBeforeGc = await stagingIds();
    expect(stagedBeforeGc, isNotEmpty);
    expect(
      (await localState()).getString('backup_restore_transaction_v1'),
      isNotNull,
    );

    await MediaAssetStore.instance.prune(<String>{});
    expect(await stagingIds(), stagedBeforeGc);
    expect(await MediaAssetStore.instance.read(fixture.assetId), isNull);

    final restarted = AgendaStore();
    await restarted.load();

    expect(await stagingIds(), isEmpty);
    expect(
      (await localState()).getString('backup_restore_transaction_v1'),
      isNull,
    );
    expect(
      restarted.journal(DateTime(2026, 1, 1)).beautiful,
      'Baseline locale',
    );

    target.dispose();
    restarted.dispose();
  });

  test('v1.00-C pre-commit crash removes promoted canonical media on next load',
      () async {
    final fixture = await buildPhotoBackup();
    final target = AgendaStore();
    await seedBaseline(target);

    AgendaStore.restoreFailurePhaseForTesting =
        'crash_after_media_promotion';
    await expectLater(
      target.restoreBackupZip(fixture.zip, merge: false),
      throwsA(anything),
    );
    AgendaStore.restoreFailurePhaseForTesting = null;

    expect(await MediaAssetStore.instance.read(fixture.assetId), isNotNull);
    expect(
      (await localState()).getString('backup_restore_transaction_v1'),
      isNotNull,
    );

    final restarted = AgendaStore();
    await restarted.load();

    expect(await MediaAssetStore.instance.read(fixture.assetId), isNull);
    expect(await stagingIds(), isEmpty);
    expect(
      (await localState()).getString('backup_restore_transaction_v1'),
      isNull,
    );
    expect(
      restarted.journal(DateTime(2026, 1, 1)).beautiful,
      'Baseline locale',
    );
    expect(restarted.journal(fixture.day).blocks, isEmpty);

    target.dispose();
    restarted.dispose();
  });

  test('v1.00-C committed crash preserves restored state and media', () async {
    final fixture = await buildPhotoBackup();
    final target = AgendaStore();
    await seedBaseline(target);

    AgendaStore.restoreFailurePhaseForTesting =
        'crash_after_structured_commit';
    await expectLater(
      target.restoreBackupZip(fixture.zip, merge: false),
      throwsA(anything),
    );
    AgendaStore.restoreFailurePhaseForTesting = null;

    final restarted = AgendaStore();
    await restarted.load();

    expect(restarted.journal(fixture.day).blocks.single.id, 'restore-photo');
    expect(
      await MediaAssetStore.instance.read(fixture.assetId),
      orderedEquals(fixture.bytes),
    );
    expect(await stagingIds(), isEmpty);
    expect(
      (await localState()).getString('backup_restore_transaction_v1'),
      isNull,
    );

    target.dispose();
    restarted.dispose();
  });

  test('v1.00-C reference without an integral file fails closed', () async {
    final target = AgendaStore();
    await seedBaseline(target);
    final day = DateTime(2026, 10, 8);
    const missingId = 'sha256_missing_reference';

    final raw = jsonEncode({
      'format': 'agenda_per_anna_backup',
      'schemaVersion': 1,
      'appVersion': '1.0-test',
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'data': {
        'journals': {
          AgendaStore.dateKey(day): DayJournal(
            blocks: [
              DiaryBlock(
                id: 'missing-reference',
                type: DiaryBlockType.photo,
                createdAt: day,
                mediaAssetId: missingId,
              ),
            ],
          ).toLocalJson(),
        },
      },
    });

    await expectLater(
      target.restoreBackup(raw, merge: false),
      throwsA(isA<FormatException>()),
    );

    expect(
      target.journal(DateTime(2026, 1, 1)).beautiful,
      'Baseline locale',
    );
    expect(target.journal(day).blocks, isEmpty);
    expect(await stagingIds(), isEmpty);
    expect(
      (await localState()).getString('backup_restore_transaction_v1'),
      isNull,
    );

    target.dispose();
  });

  test('v1.00-C purge keeps media still referenced by another live entity',
      () async {
    final store = AgendaStore();
    await store.load();

    final bytes = Uint8List.fromList(
      <int>[0xff, 0xd8, 0xff, ...List<int>.filled(80, 13)],
    );
    final assetId = await MediaAssetStore.instance.put(bytes);
    final liveDay = DateTime(2026, 10, 9);
    final trashDay = DateTime(2026, 10, 10);

    await store.saveJournal(
      liveDay,
      DayJournal(
        blocks: [
          DiaryBlock(
            id: 'live-shared-media',
            type: DiaryBlockType.photo,
            createdAt: liveDay,
            mediaAssetId: assetId,
          ),
        ],
      ),
    );
    await store.saveJournal(
      trashDay,
      DayJournal(
        blocks: [
          DiaryBlock(
            id: 'trash-shared-media',
            type: DiaryBlockType.photo,
            createdAt: trashDay,
            mediaAssetId: assetId,
          ),
        ],
      ),
    );

    expect(
      await store.moveDiaryBlockToTrash(
        trashDay,
        'trash-shared-media',
      ),
      isTrue,
    );
    final trashId = store.trash.single.id;
    expect(
      await store.purgeTrashEntry(
        trashId,
        createSafetySnapshot: false,
      ),
      isTrue,
    );

    await Future<void>.delayed(const Duration(milliseconds: 700));

    expect(
      store.journal(liveDay).blocks.single.mediaAssetId,
      assetId,
    );
    expect(
      await MediaAssetStore.instance.read(assetId),
      orderedEquals(bytes),
    );

    store.dispose();
  });

  test('v1.00-C ZIP restore generates a thumbnail from staged full media',
      () async {
    final bytes = Uint8List.fromList(
      <int>[0xff, 0xd8, 0xff, 0xe0, ...List<int>.filled(128, 9)],
    );
    final assetId = await MediaAssetStore.instance.put(bytes);
    final day = DateTime(2026, 10, 11);
    final source = AgendaStore();
    source.journals[AgendaStore.dateKey(day)] = DayJournal(
      blocks: [
        DiaryBlock(
          id: 'restore-photo-without-thumbnail',
          type: DiaryBlockType.photo,
          createdAt: day,
          mediaAssetId: assetId,
        ),
      ],
    );
    final zip = await source.createBackupZip();
    source.dispose();
    await MediaAssetStore.instance.delete(assetId);

    final target = AgendaStore();
    await target.load();
    await target.restoreBackupZip(zip, merge: false);

    final restored = target.journal(day).blocks.single;
    expect(restored.mediaAssetId, assetId);
    expect(restored.mediaThumbnailAssetId, isNotEmpty);
    expect(
      await MediaAssetStore.instance.read(restored.mediaThumbnailAssetId),
      isNotNull,
    );
    expect(await stagingIds(), isEmpty);

    target.dispose();
  });

  test('v1.00-C post-commit cleanup fault does not report restore failure',
      () async {
    final fixture = await buildPhotoBackup();
    final target = AgendaStore();
    await seedBaseline(target);

    AgendaStore.restoreFailurePhaseForTesting =
        'cleanup_after_structured_commit';
    await target.restoreBackupZip(fixture.zip, merge: false);
    AgendaStore.restoreFailurePhaseForTesting = null;

    expect(target.journal(fixture.day).blocks.single.id, 'restore-photo');
    expect(
      await MediaAssetStore.instance.read(fixture.assetId),
      orderedEquals(fixture.bytes),
    );
    expect(await stagingIds(), isNotEmpty);
    expect(
      (await localState()).getString('backup_restore_transaction_v1'),
      isNotNull,
    );

    final restarted = AgendaStore();
    await restarted.load();

    expect(restarted.journal(fixture.day).blocks.single.id, 'restore-photo');
    expect(
      await MediaAssetStore.instance.read(fixture.assetId),
      orderedEquals(fixture.bytes),
    );
    expect(await stagingIds(), isEmpty);
    expect(
      (await localState()).getString('backup_restore_transaction_v1'),
      isNull,
    );

    target.dispose();
    restarted.dispose();
  });

  test('v1.00-C recovered stale marker never deletes committed media',
      () async {
    final fixture = await buildPhotoBackup();
    final target = AgendaStore();
    await seedBaseline(target);

    AgendaStore.restoreFailurePhaseForTesting =
        'crash_after_structured_commit';
    await expectLater(
      target.restoreBackupZip(fixture.zip, merge: false),
      throwsA(anything),
    );
    AgendaStore.restoreFailurePhaseForTesting = null;

    final state = await localState();
    expect(
      state.getString('backup_restore_transaction_v1'),
      contains('structured_committed'),
    );
    await state.corruptRecordChecksumForTesting(
      'backup_restore_transaction_v1',
    );
    await state.reloadValidatedRecordsForTesting();
    expect(
      state.recoveredKeys,
      contains('backup_restore_transaction_v1'),
    );
    expect(
      state.getString('backup_restore_transaction_v1'),
      contains('canonical_media_ready'),
    );

    final restarted = AgendaStore();
    await restarted.load();

    expect(restarted.journal(fixture.day).blocks.single.id, 'restore-photo');
    expect(
      await MediaAssetStore.instance.read(fixture.assetId),
      orderedEquals(fixture.bytes),
    );
    expect(await stagingIds(), isEmpty);
    expect(
      state.getString('backup_restore_transaction_v1'),
      isNull,
    );

    target.dispose();
    restarted.dispose();
  });

  test('v1.00-C startup removes orphan staging when marker is missing',
      () async {
    final state = await localState();
    expect(
      state.getString('backup_restore_transaction_v1'),
      isNull,
    );

    final bytes = Uint8List.fromList(
      <int>[0xff, 0xd8, 0xff, ...List<int>.filled(48, 17)],
    );
    final stagingId = MediaAssetStore.instance.restoreStagingAssetId(
      'orphan-transaction',
      'sha256_orphan',
    );
    await MediaAssetStore.instance.putNamed(stagingId, bytes);
    expect(await stagingIds(), contains(stagingId));

    final restarted = AgendaStore();
    await restarted.load();

    expect(await stagingIds(), isEmpty);
    expect(await MediaAssetStore.instance.read(stagingId), isNull);
    restarted.dispose();
  });

  test('v1.00-C corrupted ZIP media fails closed before staging',
      () async {
    final fixture = await buildPhotoBackup();
    final sourceArchive = ZipDecoder().decodeBytes(
      fixture.zip,
      verify: true,
    );
    final tampered = Archive();
    for (final entry in sourceArchive) {
      if (!entry.isFile) continue;
      final original = Uint8List.fromList(entry.readBytes()!);
      final bytes = Uint8List.fromList(original);
      if (entry.name == 'media/${fixture.assetId}.bin' && bytes.isNotEmpty) {
        bytes[0] = bytes[0] ^ 0xff;
      }
      tampered.addFile(ArchiveFile.bytes(entry.name, bytes));
    }
    final corruptedZip = ZipEncoder().encodeBytes(tampered);

    final target = AgendaStore();
    await seedBaseline(target);

    await expectLater(
      target.restoreBackupZip(corruptedZip, merge: false),
      throwsA(isA<FormatException>()),
    );

    expect(
      target.journal(DateTime(2026, 1, 1)).beautiful,
      'Baseline locale',
    );
    expect(target.journal(fixture.day).blocks, isEmpty);
    expect(await stagingIds(), isEmpty);
    expect(
      (await localState()).getString('backup_restore_transaction_v1'),
      isNull,
    );

    target.dispose();
  });

}
