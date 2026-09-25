import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pull requests avoid the duplicate Development Android build', () {
    final workflow =
        File('.github/workflows/dev-checks.yml').readAsStringSync();

    expect(
      workflow,
      contains("if: github.event_name != 'pull_request'"),
    );
    expect(workflow, contains('Build Android ARM64 release gate'));
    expect(workflow, contains('flutter build apk'));
  });

  test('PR Android coverage remains split across AppLab and size audit', () {
    final appLab =
        File('.github/workflows/applab.yml').readAsStringSync();
    final sizeAudit =
        File('.github/workflows/android-size-audit.yml').readAsStringSync();

    expect(appLab, contains('pull_request:'));
    expect(appLab, contains('flutter build apk --release --split-per-abi'));
    expect(sizeAudit, contains('pull_request:'));
    expect(sizeAudit, contains('Build production-equivalent ARM64 APK'));
    expect(
      sizeAudit,
      contains('      - ".github/workflows/dev-checks.yml"'),
    );
    expect(
      sizeAudit,
      contains('      - ".github/workflows/applab.yml"'),
    );
  });

  test('main still keeps the Development Android release gate', () {
    final workflow =
        File('.github/workflows/dev-checks.yml').readAsStringSync();

    expect(workflow, contains('push:'));
    expect(workflow, contains('branches: [main]'));
    expect(workflow, isNot(contains("if: github.event_name == 'push'")));
  });
}
