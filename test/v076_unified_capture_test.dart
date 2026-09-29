import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:agenda_per_anna/main.dart';

void main() {
  test('v0.76 registers one reusable Unified Capture surface', () {
    final main = File('lib/main.dart').readAsStringSync();
    final capture = File('lib/src/unified_capture.dart').readAsStringSync();
    final home =
        File('lib/src/screens/home_inbox_search.dart').readAsStringSync();
    final planner = File('lib/src/planner_views.dart').readAsStringSync();

    expect(main, contains("part 'src/unified_capture.dart';"));
    expect(capture, contains('Future<void> showUnifiedCapture('));
    expect(home, contains('return showUnifiedCapture('));
    expect(planner, contains('captureDate: day'));
    expect(planner, contains('UnifiedCaptureEntryPoint.day'));
  });

  test('text voice and photo reuse existing canonical models', () {
    final capture = File('lib/src/unified_capture.dart').readAsStringSync();

    expect(capture, contains('store.addInboxEntry(value)'));
    expect(capture, contains('store.saveJournal('));
    expect(capture, contains('DiaryBlockType.note'));
    expect(capture, contains('DiaryBlockType.voice'));
    expect(capture, contains('DiaryBlockType.photo'));
    expect(capture, contains('MediaAssetStore.instance.put'));
    expect(capture, contains('_diaryThumbnailBytes(imageBytes)'));
    expect(capture, isNot(contains('SharedPreferences.getInstance')));
    expect(capture, isNot(contains('LocalStateStore')));
  });

  test('share target reuses Unified Capture persistence helpers', () {
    final home =
        File('lib/src/screens/home_inbox_search.dart').readAsStringSync();

    expect(home, contains('_saveUnifiedCaptureText('));
    expect(home, contains('_saveUnifiedCapturePhoto('));
    expect(home, contains('consumeImageBytes('));
  });

  test('Unified Capture keeps non-day actions on existing flows', () {
    final capture = File('lib/src/unified_capture.dart').readAsStringSync();

    expect(capture, contains('openUnifiedItemComposer('));
    expect(capture, contains('BirthdaysScreen(store: store)'));
    expect(capture, contains('PeopleScreen('));
    expect(capture, contains('_captureVoiceClip(context)'));
    expect(capture, contains('_pickCompressedDiaryImageBytes(source)'));
  });

  test('entry points remain a projection choice, not a persistence model', () {
    expect(
      UnifiedCaptureEntryPoint.values,
      [
        UnifiedCaptureEntryPoint.home,
        UnifiedCaptureEntryPoint.day,
        UnifiedCaptureEntryPoint.inbox,
      ],
    );
  });
}
