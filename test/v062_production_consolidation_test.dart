import 'dart:io';

import 'package:flutter_test/flutter_test.dart';


void main() {
  test('v0.62 stays non-AI and reuses the production architecture', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final roadmap = File('docs/ROADMAP.md').readAsStringSync();

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
    final finalize = File('tool/finalize_web_build.py').readAsStringSync();
    final push = File('web_push/annas-diary-push.js').readAsStringSync();
    final pushWorker =
        File('web_push/annas-diary-push-sw.js').readAsStringSync();
    final recovery =
        File('web_push/update-recovery.html').readAsStringSync();

    expect(platform, contains('no-cache, no-store, must-revalidate'));
    expect(push, contains('annas-diary-push-sw.js'));
    expect(push, contains('updateViaCache: "none"'));
    expect(push, contains('await result.update()'));
    expect(push, contains('controllerchange'));
    expect(pushWorker, contains('self.skipWaiting()'));
    expect(pushWorker, contains('self.clients.claim()'));
    expect(finalize, contains('PUSH_WORKER_TARGET'));
    expect(finalize, isNot(contains('generated +')));
    expect(recovery, contains('flutter-app-cache'));
    expect(recovery, contains('caches.delete'));
    expect(recovery, isNot(contains('indexedDB.deleteDatabase')));
    expect(recovery, isNot(contains('localStorage.clear')));
  });

  test('code gates are automatic and APK generation is explicitly manual', () {
    final development =
        File('.github/workflows/dev-checks.yml').readAsStringSync();
    final web = File('.github/workflows/deploy-pages.yml').readAsStringSync();
    final size =
        File('.github/workflows/android-size-audit.yml').readAsStringSync();
    final appLab = File('.github/workflows/applab.yml').readAsStringSync();
    final androidIntegration =
        File('.github/workflows/android-integration.yml').readAsStringSync();
    final sideload =
        File('.github/workflows/sideload-arm64.yml').readAsStringSync();
    final appLabProject = File('applab.project.json').readAsStringSync();

    expect(development, contains('flutter analyze'));
    expect(development, contains('flutter test'));
    expect(development, contains('flutter build web'));
    expect(development, isNot(contains('flutter build apk')));
    expect(web, contains('flutter build web'));

    for (final manual in [size, sideload, androidIntegration]) {
      expect(manual, contains('workflow_dispatch:'));
      expect(manual, isNot(contains('pull_request:')));
      expect(manual, isNot(contains('push:')));
    }
    expect(size, contains('--split-per-abi'));
    expect(size, contains('app-arm64-v8a-release.apk'));
    expect(appLab, contains('AppLab Source Gate'));
    expect(appLab, contains('tool/check_ui5_visual_flows.py'));
    expect(appLab, isNot(contains('external-project-runner.yml')));
    expect(appLab, isNot(contains('flutter build apk')));
    expect(appLab, isNot(contains('run_maestro: true')));
    expect(appLabProject, contains('"physical_validation"'));
    expect(appLabProject, contains('"required": true'));
    for (final capability in [
      '"biometrics"', '"keystore"', '"notifications"', '"file_picker"',
      '"billing"', '"play_delivery"', '"cross_app"',
    ]) {
      expect(appLabProject, contains(capability));
    }
  });
}
