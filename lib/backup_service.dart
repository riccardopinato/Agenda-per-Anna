import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

class BackupFileService {
  BackupFileService._();

  static final BackupFileService instance = BackupFileService._();

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
        dialogTitle: 'Salva backup Agenda per Anna',
      );
      return uri != null;
    } catch (_) {
      return false;
    }
  }

  Future<String?> pickJsonBackup() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['json'],
        dialogTitle: 'Scegli un backup Agenda per Anna',
      );
      if (file == null) return null;

      final bytes = await file.readAsBytes();
      return utf8.decode(bytes);
    } catch (_) {
      return null;
    }
  }

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
        dialogTitle: 'Esporta Agenda per Anna',
      );
      return uri != null;
    } catch (_) {
      return false;
    }
  }
}
