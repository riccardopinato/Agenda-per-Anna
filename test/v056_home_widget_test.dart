import 'dart:io';

import 'package:agenda_per_anna/main.dart';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('launcher details use the privacy-safe projection', () {
    expect(HomeWidgetBridge.visibleDetail(
      hidden: true, sensitive: false, fallback: 'Protected', detail: 'Secret event',
    ), 'Protected');
    expect(HomeWidgetBridge.visibleDetail(
      hidden: false, sensitive: true, fallback: 'Protected', detail: 'Shared secret',
    ), 'Protected');
    expect(HomeWidgetBridge.visibleDetail(
      hidden: false, sensitive: false, fallback: 'Protected', detail: 'Ordinary event',
    ), 'Ordinary event');
  });

  test('account switches clear stale launcher previews before republishing', () {
    final store = File('lib/src/agenda_store.dart').readAsStringSync();
    final bridge = File('lib/src/home_widget_bridge.dart').readAsStringSync();
    expect(RegExp(r'HomeWidgetBridge\.instance\.clear\(\)').allMatches(store).length,
        greaterThanOrEqualTo(2));
    expect(bridge, contains('!store.entryScopeReady'));
    expect(bridge, contains('store.activeAccountId != accountAtStart'));
    expect(bridge, contains('quickWinEntrySensitive(next)'));
    expect(bridge, contains('store.preferences.hideHomeDetails'));
  });

  test('Android platform generator contains Anna Diary home widget contract', () {
    final source =
        File('tool/prepare_android_platform.py').readAsStringSync();

    expect(source, contains('annas_diary/home_widget'));
    expect(source, contains('HomeWidgetProvider'));
    expect(source, contains('annas_diary_home_widget.xml'));
    expect(source, contains('annas_diary_home_widget_info.xml'));
    expect(source, contains('quick_capture'));
    expect(source, contains('takeLaunchAction'));
    expect(source, contains('updateWidget'));
    expect(source, contains('"clearWidget" -> {'));
    expect(source, contains('prefs.edit().clear().commit()'));
  });
}
