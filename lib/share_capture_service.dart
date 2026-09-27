import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class IncomingShareCapture {
  final String text;
  final String mimeType;
  final String imageToken;

  const IncomingShareCapture({
    this.text = '',
    this.mimeType = '',
    this.imageToken = '',
  });

  bool get hasImage => imageToken.trim().isNotEmpty;
  bool get hasText => text.trim().isNotEmpty;

  static IncomingShareCapture? fromMap(dynamic raw) {
    if (raw is! Map) return null;
    final value = IncomingShareCapture(
      text: raw['text']?.toString() ?? '',
      mimeType: raw['mimeType']?.toString() ?? '',
      imageToken: raw['imageToken']?.toString() ?? '',
    );
    return value.hasImage || value.hasText ? value : null;
  }
}

class ShareCaptureService {
  ShareCaptureService._();

  static final ShareCaptureService instance = ShareCaptureService._();

  static const MethodChannel _channel =
      MethodChannel('annas_diary/share_capture');

  final StreamController<IncomingShareCapture> _controller =
      StreamController<IncomingShareCapture>.broadcast();

  bool _initialized = false;

  Stream<IncomingShareCapture> get stream => _controller.stream;

  Future<IncomingShareCapture?> initialize() async {
    if (kIsWeb) return null;
    if (!_initialized) {
      _channel.setMethodCallHandler((call) async {
        if (call.method != 'sharedContent') return;
        final capture = IncomingShareCapture.fromMap(call.arguments);
        if (capture != null) _controller.add(capture);
      });
      _initialized = true;
    }

    try {
      final raw = await _channel.invokeMethod<dynamic>('takeInitialShare');
      return IncomingShareCapture.fromMap(raw);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  Future<Uint8List?> consumeImageBytes(String imageToken) async {
    if (kIsWeb || imageToken.trim().isEmpty) return null;
    try {
      final bytes = await _channel.invokeMethod<Uint8List>(
        'consumeSharedImage',
        imageToken,
      );
      if (bytes == null || bytes.isEmpty) return null;
      return bytes;
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}
