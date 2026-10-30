import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('automatic Development checks never build an APK', () {
    final workflow =
        File('.github/workflows/dev-checks.yml').readAsStringSync();
    expect(workflow, contains('pull_request:'));
    expect(workflow, contains('push:'));
    expect(workflow, contains('flutter analyze'));
    expect(workflow, contains('flutter test'));
    expect(workflow, isNot(contains('flutter build apk')));
    expect(workflow, isNot(contains('Build Android ARM64 release gate')));
  });

  test('AppLab Source Gate validates only visual source contracts', () {
    final source =
        File('.github/workflows/applab.yml').readAsStringSync();
    final contract =
        File('tool/check_ui5_visual_flows.py').readAsStringSync();
    expect(source, contains('AppLab Source Gate'));
    expect(source, contains('pull_request:'));
    expect(source, contains('python3 tool/check_ui5_visual_flows.py'));
    expect(source, isNot(contains('external-project-runner.yml')));
    expect(source, isNot(contains('flutter build apk')));
    expect(source, isNot(contains('run_maestro: true')));
    expect(contract, contains('ui5-today-date-strip'));
  });

  test('Android size, integration and signed sideload are manual-only', () {
    final size =
        File('.github/workflows/android-size-audit.yml').readAsStringSync();
    final integration =
        File('.github/workflows/android-integration.yml').readAsStringSync();
    final sideload =
        File('.github/workflows/sideload-arm64.yml').readAsStringSync();
    for (final workflow in [size, integration, sideload]) {
      expect(workflow, contains('workflow_dispatch:'));
      expect(workflow, isNot(contains('  push:')));
      expect(workflow, isNot(contains('  pull_request:')));
    }
    expect(size, contains('--split-per-abi'));
    expect(size, contains('Build production-equivalent ARM64 APK'));
    expect(integration, contains('ANNAS_DIARY_INTEGRATION_TEST=true'));
    expect(sideload, contains('--release-signing'));
  });

  test('main branch still validates source but does not package Android', () {
    final workflow =
        File('.github/workflows/dev-checks.yml').readAsStringSync();
    expect(workflow, contains('push:'));
    expect(workflow, contains('branches: [main]'));
    expect(workflow, isNot(contains('flutter build apk')));
  });
}
