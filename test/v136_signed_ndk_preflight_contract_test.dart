import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('v136 signing pipeline retries truncated NDK before Flutter build', () {
    final source =
        File('.github/workflows/sideload-arm64.yml').readAsStringSync();
    final prepare = source.indexOf('Preinstall pinned Android NDK');
    final build = source.indexOf('Build lightweight ARM64 release APK');
    expect(prepare, greaterThan(0));
    expect(build, greaterThan(prepare));
    expect(source, contains('28.2.13676358'));
    expect(source, contains('for attempt in 1 2 3'));
    expect(source, contains('timeout 900'));
    expect(source, contains('source.properties'));
    expect(source, contains('Pkg\\.Revision'));
    expect(source, contains('Unable to install verified Android NDK'));
    expect(source, contains('Require stable Android signing configuration'));
    expect(source, contains('Prepare physical certification identity'));
    expect(source, contains('Upload lightweight ARM64 APK'));
    expect(source, contains('test "$(git rev-parse HEAD)" = "$BUILD_SOURCE_SHA"'));
    expect(source, contains('ANNA_STORE_RELEASE=false'));
  });
}
