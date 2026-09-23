import 'dart:convert';
import 'dart:typed_data';

import 'package:sembast_web/sembast_web.dart';

final StoreRef<String, Map<String, Object?>> _assets =
    stringMapStoreFactory.store('media_assets_v2');
Database? _database;

Future<Database> _db() async =>
    _database ??= await databaseFactoryWeb.openDatabase(
      'annas_diary_media_v2',
      version: 1,
    );

Future<void> writeMediaAssetBytes(
  String assetId,
  Uint8List bytes,
) async {
  final db = await _db();
  await _assets.record(assetId).put(
    db,
    <String, Object?>{
      'data': base64Encode(bytes),
      'lastAccessedMs': DateTime.now().millisecondsSinceEpoch,
      'sizeBytes': bytes.lengthInBytes,
    },
  );
}

Future<Uint8List?> readMediaAssetBytes(String assetId) async {
  final db = await _db();
  final record = await _assets.record(assetId).get(db);
  final raw = record?['data'];
  if (raw is! String) return null;
  try {
    final bytes = base64Decode(raw);
    await _assets.record(assetId).update(
      db,
      <String, Object?>{
        'lastAccessedMs': DateTime.now().millisecondsSinceEpoch,
        'sizeBytes': bytes.lengthInBytes,
      },
    );
    return bytes;
  } catch (_) {
    return null;
  }
}

Future<bool> deleteMediaAssetBytes(String assetId) async {
  final db = await _db();
  return await _assets.record(assetId).delete(db) != null;
}

Future<Set<String>> listMediaAssetIds() async {
  final db = await _db();
  final records = await _assets.find(db);
  return records.map((record) => record.key).toSet();
}

Future<Map<String, List<int>>> listMediaAssetStats() async {
  final db = await _db();
  final records = await _assets.find(db);
  return {
    for (final record in records)
      record.key: [
        record.value['lastAccessedMs'] as int? ?? 0,
        record.value['sizeBytes'] as int? ??
            (((record.value['data'] as String?)?.length ?? 0) * 3 ~/ 4),
      ],
  };
}

Future<void> clearMediaAssetsForTesting() async {
  final db = await _db();
  await _assets.delete(db);
}
