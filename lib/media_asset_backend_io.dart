import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

final Map<String, Uint8List> _testAssets = <String, Uint8List>{};
final Map<String, int> _testAccessedAt = <String, int>{};

bool get _isTest => Platform.environment['FLUTTER_TEST'] == 'true';

Future<Directory> _mediaDirectory() async {
  final root = await getApplicationSupportDirectory();

  final directory = Directory(
    '${root.path}${Platform.pathSeparator}media_v2',
  );
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }
  return directory;
}

String _safeAssetId(String assetId) =>
    assetId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');

Future<File> _assetFile(String assetId) async {
  final directory = await _mediaDirectory();
  return File(
    '${directory.path}${Platform.pathSeparator}${_safeAssetId(assetId)}.bin',
  );
}

Future<void> writeMediaAssetFileAtomically(
  File file,
  Uint8List bytes,
) async {
  final temp = File('${file.path}.tmp');
  if (await temp.exists()) {
    await temp.delete();
  }

  await temp.writeAsBytes(bytes, flush: true);
  if (await file.exists()) {
    await file.delete();
  }
  await temp.rename(file.path);
}

Future<void> writeMediaAssetBytes(
  String assetId,
  Uint8List bytes,
) async {
  if (_isTest) {
    _testAssets[assetId] = Uint8List.fromList(bytes);
    _testAccessedAt[assetId] = DateTime.now().millisecondsSinceEpoch;
    return;
  }

  final file = await _assetFile(assetId);
  await writeMediaAssetFileAtomically(file, bytes);
}

Future<Uint8List?> readMediaAssetBytes(String assetId) async {
  if (_isTest) {
    final value = _testAssets[assetId];
    if (value == null) return null;
    _testAccessedAt[assetId] = DateTime.now().millisecondsSinceEpoch;
    return Uint8List.fromList(value);
  }

  final file = await _assetFile(assetId);
  if (!await file.exists()) return null;
  final bytes = Uint8List.fromList(await file.readAsBytes());
  try {
    await file.setLastModified(DateTime.now());
  } catch (_) {
    // Cache recency is best-effort; reading the asset must still succeed.
  }
  return bytes;
}

Future<bool> deleteMediaAssetBytes(String assetId) async {
  if (_isTest) {
    _testAccessedAt.remove(assetId);
    return _testAssets.remove(assetId) != null;
  }

  final file = await _assetFile(assetId);
  if (!await file.exists()) return false;
  await file.delete();
  return true;
}

Future<Set<String>> listMediaAssetIds() async {
  if (_isTest) return _testAssets.keys.toSet();

  final directory = await _mediaDirectory();
  final result = <String>{};
  await for (final entity in directory.list(followLinks: false)) {
    if (entity is! File || !entity.path.endsWith('.bin')) continue;
    final name = entity.uri.pathSegments.last;
    result.add(name.substring(0, name.length - 4));
  }
  return result;
}

Future<Map<String, List<int>>> listMediaAssetStats() async {
  if (_isTest) {
    return {
      for (final entry in _testAssets.entries)
        entry.key: [
          _testAccessedAt[entry.key] ?? 0,
          entry.value.lengthInBytes,
        ],
    };
  }

  final directory = await _mediaDirectory();
  final result = <String, List<int>>{};
  await for (final entity in directory.list(followLinks: false)) {
    if (entity is! File || !entity.path.endsWith('.bin')) continue;
    final name = entity.uri.pathSegments.last;
    final assetId = name.substring(0, name.length - 4);
    try {
      final stat = await entity.stat();
      result[assetId] = [
        stat.modified.millisecondsSinceEpoch,
        stat.size,
      ];
    } catch (_) {
      // Ignore files that disappear while the cache is being inspected.
    }
  }
  return result;
}

Future<void> clearMediaAssetsForTesting() async {
  _testAssets.clear();
  _testAccessedAt.clear();
}
