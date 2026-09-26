import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:agenda_per_anna/app_version.dart';

void main() {
  test('v0.62 stays non-AI and reuses the production architecture', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final roadmap = File('docs/ROADMAP.md').readAsStringSync();

    expect(appReleaseVersion, '0.62.0');
    expect(pubspec, contains('version: 0.62.0+71'));

    const forbiddenDependencies = <String>[
      'openai',
      'google_generative_ai',
      'firebase_ai',
      'langchain',
    ];
    for (final dependency in forbiddenDependencies) {
      expect(pubspec.toLowerCase(), isNot(contains(dependency)));
    }

    expect(roadmap, contains('v0.62'));
    expect(roadmap, contains('Non-AI Production Consolidation'));
  });

  test('v0.62 shell declares accessible Material interaction defaults', () {
    final shell = File('lib/src/app_shell.dart').readAsStringSync();

    expect(
      shell,
      contains('materialTapTargetSize: MaterialTapTargetSize.padded'),
    );
    expect(shell, contains('visualDensity: VisualDensity.standard'));
    expect(shell, contains('FocusTraversalGroup('));
    expect(shell, contains('ReadingOrderTraversalPolicy()'));
  });

  test('web PWA actively refreshes stale installed builds', () {
    final platform = File('tool/prepare_web_platform.py').readAsStringSync();
    final push = File('web_push/annas-diary-push.js').readAsStringSync();

    expect(platform, contains('no-cache, no-store, must-revalidate'));
    expect(push, contains('await result.update()'));
    expect(push, contains('controllerchange'));
    expect(push, contains('window.location.reload()'));
  });

  test('final release workflows keep every required production gate', () {
    final development =
        File('.github/workflows/dev-checks.yml').readAsStringSync();
    final web = File('.github/workflows/deploy-pages.yml').readAsStringSync();
    final size =
        File('.github/workflows/android-size-audit.yml').readAsStringSync();
    final appLab = File('.github/workflows/applab.yml').readAsStringSync();

    expect(development, contains('flutter analyze'));
    expect(development, contains('flutter test'));
    expect(development, contains('flutter build web'));
    expect(web, contains('flutter build web'));
    expect(size, contains('--split-per-abi'));
    expect(size, contains('app-arm64-v8a-release.apk'));
    expect(appLab, contains('AppLab Production Gate'));
    // Trusted Verify is owned by the pinned reusable AppLab runner; this
    // repository must keep invoking that trusted runner at an immutable SHA.
    expect(appLab, contains('uses: riccardopinato/AppLab/.github/workflows/'));
    expect(
      appLab,
      contains('@a871a1c1e0ab8339c48bc8ee53ee4cc34d634d34'),
    );
    expect(appLab, contains('run_flutter_tests: true'));
    expect(appLab, contains('run_maestro: true'));
    expect(appLab, contains('app-arm64-v8a-release.apk'));
  });
}
