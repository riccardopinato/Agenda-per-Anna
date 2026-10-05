import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:agenda_per_anna/main.dart';

void main() {
  test('v0.98 routes every primary day surface through Unified Capture', () {
    final home =
        File('lib/src/screens/home_inbox_search.dart').readAsStringSync();
    final planner = File('lib/src/planner_views.dart').readAsStringSync();

    expect(home, contains('_showQuickCapture(context, store)'));
    expect(
      planner,
      contains('entryPoint: UnifiedCaptureEntryPoint.month'),
    );
    expect(
      planner,
      contains('entryPoint: UnifiedCaptureEntryPoint.week'),
    );
    expect(
      planner,
      contains('entryPoint: UnifiedCaptureEntryPoint.day'),
    );
    expect(
      home,
      contains('entryPoint: UnifiedCaptureEntryPoint.inbox'),
    );
  });

  test('external launch routes reuse Unified Capture instead of a new store', () {
    final main = File('lib/main.dart').readAsStringSync();
    final home =
        File('lib/src/screens/home_inbox_search.dart').readAsStringSync();
    final capture = File('lib/src/unified_capture.dart').readAsStringSync();

    expect(
      UnifiedCaptureEntryPoint.values,
      [
        UnifiedCaptureEntryPoint.home,
        UnifiedCaptureEntryPoint.month,
        UnifiedCaptureEntryPoint.week,
        UnifiedCaptureEntryPoint.day,
        UnifiedCaptureEntryPoint.inbox,
        UnifiedCaptureEntryPoint.external,
      ],
    );
    expect(
      main,
      contains('entryPoint: UnifiedCaptureEntryPoint.external'),
    );
    expect(home, contains("query['capture'] == '1'"));
    expect(home, contains("query['today'] == '1'"));
    expect(
      home,
      contains('entryPoint: UnifiedCaptureEntryPoint.external'),
    );

    expect(capture, contains('store.saveJournal('));
    expect(capture, contains('store.addInboxEntry(value)'));
    expect(capture, isNot(contains('SharedPreferences.getInstance')));
    expect(capture, isNot(contains('LocalStateStore')));
  });

  test('Android launcher shortcuts feed the existing home widget action bridge',
      () {
    final source =
        File('tool/prepare_android_platform.py').readAsStringSync();

    expect(source, contains('android.app.shortcuts'));
    expect(source, contains('annas_diary_shortcuts.xml'));
    expect(source, contains('annasdiary://capture'));
    expect(source, contains('annasdiary://today'));
    expect(source, contains('decodeLaunchAction'));
    expect(source, contains('"capture" -> "quick_capture"'));
    expect(source, contains('"today" -> "today"'));
    expect(source, contains('HOME_WIDGET_CHANNEL'));
  });

  test('PWA manifest exposes Capture and Today shortcuts', () {
    final manifest = jsonDecode(
      File('web_manifest.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final shortcuts = (manifest['shortcuts'] as List<dynamic>)
        .cast<Map<String, dynamic>>();

    expect(shortcuts.map((entry) => entry['url']), contains('./?capture=1'));
    expect(shortcuts.map((entry) => entry['url']), contains('./?today=1'));

    final preparer =
        File('tool/prepare_web_platform.py').readAsStringSync();
    expect(preparer, contains('"url": "./?capture=1"'));
    expect(preparer, contains('"url": "./?today=1"'));
  });

  test('v0.98 keeps share target on canonical Unified Capture persistence', () {
    final main = File('lib/main.dart').readAsStringSync();
    final home =
        File('lib/src/screens/home_inbox_search.dart').readAsStringSync();

    expect(main, contains('ShareCaptureService.instance.initialize()'));
    expect(home, contains('_handleIncomingShareCapture'));
    expect(home, contains('_saveUnifiedCaptureText('));
    expect(home, contains('_saveUnifiedCapturePhoto('));
  });
}
