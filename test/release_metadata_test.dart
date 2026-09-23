import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:agenda_per_anna/app_version.dart';

void main() {
  test('runtime release version matches pubspec semantic version', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match = RegExp(r'^version:\s*([^\s]+)', multiLine: true)
        .firstMatch(pubspec);

    expect(match, isNotNull);
    final packageVersion = match!.group(1)!;
    expect(packageVersion, startsWith('$appReleaseVersion+'));
  });
}
