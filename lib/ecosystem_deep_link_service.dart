import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class EcosystemDeepLinkService {
  EcosystemDeepLinkService._();

  static final instance = EcosystemDeepLinkService._();

  static const _channel = MethodChannel('annas_diary/ecosystem_deep_link');
  final _controller = StreamController<Uri>.broadcast();

  Stream<Uri> get stream => _controller.stream;

  Future<Uri?> initialize() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }

    _channel.setMethodCallHandler((call) async {
      if (call.method != 'ecosystemDeepLink') return;
      final raw = call.arguments?.toString().trim() ?? '';
      final uri = Uri.tryParse(raw);
      if (uri != null) _controller.add(uri);
    });

    final raw = await _channel.invokeMethod<String>('takeInitialDeepLink');
    final normalized = raw?.trim() ?? '';
    return normalized.isEmpty ? null : Uri.tryParse(normalized);
  }
}
