import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agenda_per_anna/app_version.dart';
import 'package:agenda_per_anna/main.dart';

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

  testWidgets('v0.62 shell keeps accessible Material interaction defaults',
      (tester) async {
    final store = AgendaStore();
    await store.load();
    await store.savePreferences(
      store.preferences.copyWith(onboardingDone: true),
    );

    await tester.pumpWidget(
      AgendaApp(store: store, bypassIdentityForTesting: true),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(MaterialApp));
    final theme = Theme.of(context);
    expect(theme.materialTapTargetSize, MaterialTapTargetSize.padded);
    expect(theme.visualDensity, VisualDensity.standard);
    expect(find.byType(FocusTraversalGroup), findsWidgets);

    store.dispose();
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
    expect(appLab, contains('Trusted verify'));
    expect(appLab, contains('app-arm64-v8a-release.apk'));
  });
}
