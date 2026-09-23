import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

final Map<String, Uint8List> _testAssets = <String, Uint8List>{};

bool get _isTest => Platform.environment['FLUTTER_TEST'] == 'true';

Future<Directory> _mediaDirectory() async {
  Directory root;
  try {
    root = await getApplicationSupportDirectory();
  } catch (_) {
    root = Directory(
      '${Directory.systemTemp.path}${Platform.pathSeparator}annas_diary',
    );
  }

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

Future<void> writeMediaAssetBytes(
  String assetId,
  Uint8List bytes,
) async {
  if (_isTest) {
    _testAssets[assetId] = Uint8List.fromList(bytes);
    return;
  }

  final file = await _assetFile(assetId);
  if (await file.exists()) {
    final existing = await file.length();
    if (existing == bytes.length) return;
  }

  final temp = File('${file.path}.tmp');
  await temp.writeAsBytes(bytes, flush: true);
  if (await file.exists()) {
    await file.delete();
  }
  await temp.rename(file.path);
}

Future<Uint8List?> readMediaAssetBytes(String assetId) async {
  if (_isTest) {
    final value = _testAssets[assetId];
    return value == null ? null : Uint8List.fromList(value);
  }

  final file = await _assetFile(assetId);
  if (!await file.exists()) return null;
  return Uint8List.fromList(await file.readAsBytes());
}

Future<bool> deleteMediaAssetBytes(String assetId) async {
  if (_isTest) {
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

Future<void> clearMediaAssetsForTesting() async {
  _testAssets.clear();
}
