import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
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

  test('corrupt account profile archive blocks account switching without overwrite',
      () async {
    final store = AgendaStore();
    await store.load();
    await store.addInboxEntry('Dato locale');

    final state = await LocalStateStore.instance.open(
      legacyPreferences: await SharedPreferences.getInstance(),
    );
    await state.setString('account_profiles_v1', '{corrupt-profile-json');

    await expectLater(
      store.activateCloudAccount('user-a'),
      throwsA(isA<FormatException>()),
    );

    expect(store.activeAccountId, isNull);
    expect(store.inbox.map((entry) => entry.text), contains('Dato locale'));
    expect(
      state.getString('account_profiles_v1'),
      '{corrupt-profile-json',
    );
    expect(store.hasStorageWarnings, isTrue);

    store.dispose();
  });

  test('failed ZIP restore rolls back media imported only for that restore',
      () async {
    final store = AgendaStore();
    await store.load();

    final mediaBytes = Uint8List.fromList(
      List<int>.generate(128, (index) => (index * 17) % 251),
    );
    final assetId = MediaAssetStore.instance.contentAssetId(mediaBytes);

    final dataJson = jsonEncode({
      'format': 'agenda_per_anna_backup',
      'schemaVersion': 1,
      'appVersion': '0.39.1',
      'exportedAt': DateTime(2026, 9, 24).toIso8601String(),
      'data': {
        'items': ['malformed-item-that-fails-model-decoding'],
        'journals': <String, Object>{},
        'months': <String, Object>{},
        'weeks': <String, Object>{},
        'habits': <Object>[],
        'inbox': <Object>[],
      },
    });

    final manifestJson = jsonEncode({
      'format': 'agenda_per_anna_backup_bundle',
      'bundleVersion': 1,
      'appVersion': '0.39.1',
      'exportedAt': DateTime(2026, 9, 24).toIso8601String(),
      'dataFile': 'data.json',
      'mediaCount': 1,
      'media': [
        {
          'assetId': assetId,
          'path': 'media/$assetId.bin',
          'size': mediaBytes.lengthInBytes,
          'sha256': sha256.convert(mediaBytes).toString(),
        },
      ],
      'dataSha256': sha256.convert(utf8.encode(dataJson)).toString(),
    });

    final zip = BackupFileService.instance.buildZipBackup(
      manifestJson: manifestJson,
      dataJson: dataJson,
      media: {assetId: mediaBytes},
    );

    expect(await MediaAssetStore.instance.read(assetId), isNull);

    await expectLater(
      store.restoreBackupZip(zip, merge: false),
      throwsA(anything),
    );

    expect(await MediaAssetStore.instance.read(assetId), isNull);
    store.dispose();
  });

  test('sync-only pending counter uses granular sync revision', () async {
    final store = AgendaStore();
    await store.load();
    await store.activateCloudAccount('user-a');

    final state = await LocalStateStore.instance.open(
      legacyPreferences: await SharedPreferences.getInstance(),
    );
    await state.setString(
      store.sharedPendingStorageKey('space-1'),
      '[{},{}]',
    );

    var globalNotifications = 0;
    store.addListener(() => globalNotifications++);
    final beforeRevision = store.syncRevision.value;

    await store.refreshPendingSharedCount();

    expect(store.pendingSharedChangeCount, 2);
    expect(store.syncRevision.value, greaterThan(beforeRevision));
    expect(globalNotifications, 0);

    store.dispose();
  });

  test('backup limits are bounded for mobile-safe in-memory processing', () {
    expect(
      BackupFileService.maxBackupMediaBytes,
      lessThanOrEqualTo(96 * 1024 * 1024),
    );
    expect(
      BackupFileService.maxCompressedArchiveBytes,
      lessThanOrEqualTo(128 * 1024 * 1024),
    );
    expect(
      BackupFileService.maxUncompressedArchiveBytes,
      lessThanOrEqualTo(192 * 1024 * 1024),
    );
  });
}
