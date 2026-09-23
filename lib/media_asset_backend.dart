import 'dart:typed_data';

import 'media_asset_backend_io.dart'
    if (dart.library.html) 'media_asset_backend_web.dart' as implementation;

Future<void> writeMediaAssetBytes(String assetId, Uint8List bytes) =>
    implementation.writeMediaAssetBytes(assetId, bytes);

Future<Uint8List?> readMediaAssetBytes(String assetId) =>
    implementation.readMediaAssetBytes(assetId);

Future<bool> deleteMediaAssetBytes(String assetId) =>
    implementation.deleteMediaAssetBytes(assetId);

Future<Set<String>> listMediaAssetIds() =>
    implementation.listMediaAssetIds();

Future<void> clearMediaAssetsForTesting() =>
    implementation.clearMediaAssetsForTesting();
