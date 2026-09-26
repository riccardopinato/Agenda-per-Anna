import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
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
  });
}
