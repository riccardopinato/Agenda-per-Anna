import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'media_asset_backend.dart';

class MediaAssetStore {
  MediaAssetStore._();

  static final MediaAssetStore instance = MediaAssetStore._();

  static const int schemaVersion = 2;
  static const int _maxCacheEntries = 24;
  static const int _maxCacheBytes = 8 * 1024 * 1024;

  final Map<String, Uint8List> _cache = <String, Uint8List>{};
  final Set<String> _corruptAssetIds = <String>{};
  int _cacheBytes = 0;

  Set<String> get corruptAssetIds =>
      Set<String>.unmodifiable(_corruptAssetIds);

  String contentAssetId(Uint8List bytes) =>
      'sha256_${sha256.convert(bytes)}';

  String namedAssetId(String namespace, String key) {
    final digest = sha256.convert(utf8.encode(key));
    return '${namespace}_$digest';
  }

  Future<String> put(Uint8List bytes) async {
    final assetId = contentAssetId(bytes);
    await putNamed(assetId, bytes);
    return assetId;
  }

  Future<void> putNamed(String assetId, Uint8List bytes) async {
    if (assetId.trim().isEmpty || bytes.isEmpty) {
      throw ArgumentError('Media asset non valido.');
    }
    await writeMediaAssetBytes(assetId, bytes);
    _corruptAssetIds.remove(assetId);
    _remember(assetId, bytes);
  }

  Future<String?> importBase64(String raw) async {
    if (raw.trim().isEmpty) return null;
    try {
      return await put(base64Decode(raw));
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List?> read(String assetId) async {
    if (assetId.trim().isEmpty) return null;

    final cached = _cache.remove(assetId);
    if (cached != null) {
      _cache[assetId] = cached;
      return Uint8List.fromList(cached);
    }

    final bytes = await readMediaAssetBytes(assetId);
    if (bytes == null || bytes.isEmpty) return null;

    if (assetId.startsWith('sha256_') && contentAssetId(bytes) != assetId) {
      _corruptAssetIds.add(assetId);
      return null;
    }

    _corruptAssetIds.remove(assetId);
    _remember(assetId, bytes);
    return Uint8List.fromList(bytes);
  }

  Future<bool> delete(String assetId) async {
    final cached = _cache.remove(assetId);
    if (cached != null) _cacheBytes -= cached.lengthInBytes;
    _corruptAssetIds.remove(assetId);
    return deleteMediaAssetBytes(assetId);
  }

  Future<int> prune(Set<String> referencedAssetIds) async {
    final existing = await listMediaAssetIds();
    var removed = 0;
    for (final assetId in existing) {
      if (referencedAssetIds.contains(assetId)) continue;
      if (await delete(assetId)) removed++;
    }
    return removed;
  }

  void _remember(String assetId, Uint8List bytes) {
    final previous = _cache.remove(assetId);
    if (previous != null) _cacheBytes -= previous.lengthInBytes;

    final copy = Uint8List.fromList(bytes);
    _cache[assetId] = copy;
    _cacheBytes += copy.lengthInBytes;

    while (_cache.length > _maxCacheEntries ||
        _cacheBytes > _maxCacheBytes) {
      final oldestKey = _cache.keys.first;
      final oldest = _cache.remove(oldestKey);
      if (oldest != null) _cacheBytes -= oldest.lengthInBytes;
    }
  }

  Future<void> resetForTesting() async {
    _cache.clear();
    _cacheBytes = 0;
    _corruptAssetIds.clear();
    await clearMediaAssetsForTesting();
  }
}
