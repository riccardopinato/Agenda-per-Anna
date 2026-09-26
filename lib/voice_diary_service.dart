import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class VoiceDiaryService {
  VoiceDiaryService._();

  static final VoiceDiaryService instance = VoiceDiaryService._();
  static const MethodChannel _channel =
      MethodChannel('annas_diary/voice_diary');

  bool get canRecord => !kIsWeb;
  bool get canPlayNative => !kIsWeb;

  Future<void> startRecording() async {
    if (kIsWeb) {
      throw PlatformException(
        code: 'voice_recording_unsupported',
        message: 'La registrazione diretta non è disponibile sul web.',
      );
    }
    await _channel.invokeMethod<void>('startRecording');
  }

  Future<Uint8List> stopRecording() async {
    if (kIsWeb) {
      throw PlatformException(
        code: 'voice_recording_unsupported',
        message: 'La registrazione diretta non è disponibile sul web.',
      );
    }
    final bytes = await _channel.invokeMethod<Uint8List>('stopRecording');
    if (bytes == null || bytes.isEmpty) {
      throw PlatformException(
        code: 'empty_voice_recording',
        message: 'La registrazione è vuota.',
      );
    }
    return bytes;
  }

  Future<void> cancelRecording() async {
    if (kIsWeb) return;
    await _channel.invokeMethod<void>('cancelRecording');
  }

  Future<void> play(Uint8List bytes) async {
    if (bytes.isEmpty) return;
    if (kIsWeb) {
      throw PlatformException(
        code: 'voice_playback_unsupported',
        message: 'La riproduzione diretta non è disponibile sul web.',
      );
    }
    await _channel.invokeMethod<void>('playRecording', bytes);
  }

  Future<void> stopPlayback() async {
    if (kIsWeb) return;
    await _channel.invokeMethod<void>('stopPlayback');
  }
}
