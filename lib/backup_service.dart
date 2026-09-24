import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';

class PickedBackupFile {
  final String name;
  final Uint8List bytes;

  const PickedBackupFile({
    required this.name,
    required this.bytes,
  });

  bool get isZip => name.toLowerCase().endsWith('.zip');
  bool get isJson => name.toLowerCase().endsWith('.json');
}

class DecodedZipBackup {
  final String manifestJson;
  final String dataJson;
  final Map<String, Uint8List> media;

  const DecodedZipBackup({
    required this.manifestJson,
    required this.dataJson,
    required this.media,
  });
}

class BackupFileService {
  BackupFileService._();

  static final BackupFileService instance = BackupFileService._();

  static const int maxBackupMediaBytes = 96 * 1024 * 1024;
  static const int maxCompressedArchiveBytes = 128 * 1024 * 1024;
  static const int maxUncompressedArchiveBytes = 192 * 1024 * 1024;
  static const int maxSingleEntryBytes = 16 * 1024 * 1024;
  static const int _maxArchiveEntries = 5000;

  Future<bool> saveJsonBackup({
    required String json,
    required String fileName,
  }) async {
    try {
      final uri = await FilePicker.saveFile(
        fileName: fileName,
        bytes: Uint8List.fromList(utf8.encode(json)),
        mimeType: 'application/json',
        type: FileType.custom,
        allowedExtensions: const ['json'],
        dialogTitle: 'Salva backup Anna\'s Diary',
      );
      return uri != null;
    } catch (_) {
      return false;
    }
  }

  Future<bool> saveZipBackup({
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      final uri = await FilePicker.saveFile(
        fileName: fileName,
        bytes: bytes,
        mimeType: 'application/zip',
        type: FileType.custom,
        allowedExtensions: const ['zip'],
        dialogTitle: 'Salva backup Anna\'s Diary',
      );
      return uri != null;
    } catch (_) {
      return false;
    }
  }

  Future<PickedBackupFile?> pickBackup() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['zip', 'json'],
        dialogTitle: 'Scegli un backup Anna\'s Diary',
      );
      if (file == null) return null;
      return PickedBackupFile(
        name: file.name,
        bytes: await file.readAsBytes(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<String?> pickJsonBackup() async {
    final picked = await pickBackup();
    if (picked == null || !picked.isJson) return null;
    try {
      return utf8.decode(picked.bytes);
    } catch (_) {
      return null;
    }
  }

  Uint8List buildZipBackup({
    required String manifestJson,
    required String dataJson,
    required Map<String, Uint8List> media,
  }) {
    final totalMediaBytes = media.values.fold<int>(
      0,
      (sum, value) => sum + value.lengthInBytes,
    );
    final estimatedUncompressed =
        totalMediaBytes + utf8.encode(manifestJson).length + utf8.encode(dataJson).length;
    if (totalMediaBytes > maxBackupMediaBytes ||
        estimatedUncompressed > maxUncompressedArchiveBytes) {
      throw const FormatException(
        'Il backup è troppo grande per essere creato in sicurezza su questo dispositivo.',
      );
    }
    if (media.values.any((value) => value.lengthInBytes > maxSingleEntryBytes)) {
      throw const FormatException(
        'Un contenuto multimediale del backup è troppo grande.',
      );
    }

    final archive = Archive()
      ..addFile(ArchiveFile.string('manifest.json', manifestJson))
      ..addFile(ArchiveFile.string('data.json', dataJson));

    final ids = media.keys.toList()..sort();
    for (final assetId in ids) {
      if (!_validAssetId(assetId)) {
        throw const FormatException('Identificatore media non valido.');
      }
      final bytes = media[assetId]!;
      archive.addFile(
        ArchiveFile.bytes('media/$assetId.bin', bytes),
      );
    }

    return ZipEncoder().encodeBytes(
      archive,
      level: DeflateLevel.bestSpeed,
    );
  }

  DecodedZipBackup decodeZipBackup(Uint8List bytes) {
    if (bytes.lengthInBytes > maxCompressedArchiveBytes) {
      throw const FormatException(
        'Il file ZIP è troppo grande per essere aperto in sicurezza.',
      );
    }

    final archive = ZipDecoder().decodeBytes(bytes, verify: true);
    if (archive.length > _maxArchiveEntries) {
      throw const FormatException('Il backup contiene troppi file.');
    }

    String? manifestJson;
    String? dataJson;
    final media = <String, Uint8List>{};
    var totalBytes = 0;

    for (final entry in archive) {
      if (!entry.isFile) continue;
      if (entry.size > maxSingleEntryBytes) {
        throw const FormatException(
          'Il backup contiene un file singolo troppo grande.',
        );
      }
      totalBytes += entry.size;
      if (totalBytes > maxUncompressedArchiveBytes) {
        throw const FormatException('Il backup è troppo grande.');
      }

      final name = entry.name.replaceAll('\\', '/');
      if (name == 'manifest.json') {
        manifestJson = utf8.decode(entry.readBytes() ?? const <int>[]);
        continue;
      }
      if (name == 'data.json') {
        dataJson = utf8.decode(entry.readBytes() ?? const <int>[]);
        continue;
      }
      if (!name.startsWith('media/') || !name.endsWith('.bin')) {
        continue;
      }

      final assetId =
          name.substring('media/'.length, name.length - '.bin'.length);
      if (!_validAssetId(assetId) || media.containsKey(assetId)) {
        throw const FormatException('Contenuto media del backup non valido.');
      }
      final content = entry.readBytes();
      if (content == null || content.isEmpty) continue;
      media[assetId] = Uint8List.fromList(content);
    }

    if (manifestJson == null || dataJson == null) {
      throw const FormatException(
        'Il file ZIP non contiene un backup Anna\'s Diary completo.',
      );
    }

    return DecodedZipBackup(
      manifestJson: manifestJson,
      dataJson: dataJson,
      media: media,
    );
  }

  bool _validAssetId(String value) =>
      value.isNotEmpty &&
      value.length <= 160 &&
      RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(value);

  Future<bool> saveTextExport({
    required String text,
    required String fileName,
  }) async {
    try {
      final uri = await FilePicker.saveFile(
        fileName: fileName,
        bytes: Uint8List.fromList(utf8.encode(text)),
        mimeType: 'text/plain',
        type: FileType.custom,
        allowedExtensions: const ['txt'],
        dialogTitle: 'Esporta Anna\'s Diary',
      );
      return uri != null;
    } catch (_) {
      return false;
    }
  }
}
