import 'dart:convert';
import 'dart:typed_data';

import 'package:sembast/sembast.dart';
import 'package:sembast_web/sembast_web.dart';

final StoreRef<String, String> _assets =
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
  await _assets.record(assetId).put(db, base64Encode(bytes));
}

Future<Uint8List?> readMediaAssetBytes(String assetId) async {
  final db = await _db();
  final raw = await _assets.record(assetId).get(db);
  if (raw == null) return null;
  try {
    return base64Decode(raw);
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

Future<void> clearMediaAssetsForTesting() async {
  final db = await _db();
  await _assets.delete(db);
}
