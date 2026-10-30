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

  test('final release workflows keep every required production gate', () {
    final development =
        File('.github/workflows/dev-checks.yml').readAsStringSync();
    final web = File('.github/workflows/deploy-pages.yml').readAsStringSync();
    final size =
        File('.github/workflows/android-size-audit.yml').readAsStringSync();
    final appLab = File('.github/workflows/applab.yml').readAsStringSync();
    final appLabProject = File('applab.project.json').readAsStringSync();

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
      contains('@c276f03d5935a2cbd9e089175fd311466cf491ef'),
    );
    expect(appLab, contains('analysis_mode: fast'));
    expect(
      appLab,
      contains(r"baseline_sha: ${{ github.event.pull_request.base.sha || '' }}"),
    );
    expect(appLab, contains('cache_verification: true'));
    expect(appLabProject, contains('"physical_validation"'));
    expect(appLabProject, contains('"required": true'));
    expect(appLabProject, contains('"biometrics"'));
    expect(appLabProject, contains('"keystore"'));
    expect(appLabProject, contains('"notifications"'));
    expect(appLabProject, contains('"file_picker"'));
    expect(appLabProject, contains('"billing"'));
    expect(appLabProject, contains('"play_delivery"'));
    expect(appLabProject, contains('"cross_app"'));
    expect(appLab, contains('actions: read'));
    expect(appLab, contains('run_maestro: true'));
    expect(appLab, contains('build/app/outputs/flutter-apk/app-release.apk'));
    expect(appLab, contains('--target-platform android-x64'));
    expect(appLab, isNot(contains('--split-per-abi')));
  });
}
