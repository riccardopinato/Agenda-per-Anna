import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// On-device photo text recognition.
///
/// Android uses Google ML Kit's bundled Latin text recognizer. The original
/// image remains the source of truth; this service returns derived text only.
class PhotoOcrService {
  PhotoOcrService._();

  static final PhotoOcrService instance = PhotoOcrService._();

  static const MethodChannel _channel =
      MethodChannel('annas_diary/photo_ocr');

  Future<String?> recognize(Uint8List bytes) async {
    if (kIsWeb || bytes.isEmpty) return null;
    try {
      final value = await _channel.invokeMethod<String>(
        'recognizeImage',
        bytes,
      );
      if (value == null) return null;
      return _normalize(value);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  String _normalize(String raw) => raw
      .replaceAll('\r\n', '\n')
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}
