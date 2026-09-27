import 'dart:io';

import 'package:agenda_per_anna/app_version.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('v0.64 Android share target reuses existing capture paths', () {
    final service = File('lib/share_capture_service.dart').readAsStringSync();
    final home =
        File('lib/src/screens/home_inbox_search.dart').readAsStringSync();
    final android =
        File('tool/prepare_android_platform.py').readAsStringSync();
    final main = File('lib/main.dart').readAsStringSync();

    expect(service, contains("MethodChannel('annas_diary/share_capture')"));
    expect(service, contains("'takeInitialShare'"));
    expect(service, contains("'consumeSharedImage'"));
    expect(home, contains('_handleIncomingShareCapture'));
    expect(home, contains("store.addInboxEntry(preview)"));
    expect(home, contains('DiaryBlockType.photo'));
    expect(home, contains('_compressDiaryImageBytes(rawBytes)'));
    expect(main, contains('ShareCaptureService.instance.initialize()'));
    expect(android, contains('android.intent.action.SEND'));
    expect(android, contains('android:mimeType="text/plain"'));
    expect(android, contains('android:mimeType="image/*"'));
    expect(android, contains('shared image exceeds 30 MB'));
    expect(android, contains('sharedImageFile(token)?.delete()'));
  });

  test('v0.64 focus writing mode keeps the normal diary note model', () {
    final diary =
        File('lib/src/diary/diary_components.dart').readAsStringSync();

    expect(diary, contains('class FocusWritingScreen'));
    expect(diary, contains('Scrivi a schermo intero'));
    expect(diary, contains('Modalità scrittura'));
    expect(diary, contains('wordCount'));
    expect(diary, contains('DiaryBlockType.note'));
    expect(diary, isNot(contains('focus_note_database')));
  });

  test('v0.64 release metadata is aligned', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(appReleaseVersion, '0.65.0');
    expect(pubspec, contains('version: 0.65.0+75'));
  });
}
