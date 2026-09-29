import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:agenda_per_anna/app_version.dart';

void main() {
  test('v0.81 keeps the install lightweight and ships no bundled local LLM', () {
    final pubspec = File('pubspec.yaml').readAsStringSync().toLowerCase();

    const forbiddenDependencies = <String>[
      'openai',
      'google_generative_ai',
      'firebase_ai',
      'langchain',
      'llama',
      'cactus',
      'onnxruntime',
      'pytorch',
      'executorch',
      'tflite_flutter',
      'tensorflow_lite',
    ];
    for (final dependency in forbiddenDependencies) {
      expect(pubspec, isNot(contains(dependency)));
    }

    const forbiddenModelExtensions = <String>{
      '.gguf',
      '.onnx',
      '.tflite',
      '.safetensors',
      '.pt',
      '.pth',
      '.task',
    };

    final assets = Directory('assets');
    if (assets.existsSync()) {
      for (final entity in assets.listSync(recursive: true)) {
        if (entity is! File) continue;
        final lower = entity.path.toLowerCase();
        expect(
          forbiddenModelExtensions.any(lower.endsWith),
          isFalse,
          reason: 'Bundled model asset found: ${entity.path}',
        );
        expect(
          entity.lengthSync(),
          lessThan(2 * 1024 * 1024),
          reason:
              'Single bundled asset exceeds the 2 MB release-candidate guard: ${entity.path}',
        );
      }
    }
  });

  test('v0.81 release metadata is canonical', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(appReleaseVersion, '0.81.0');
    expect(appReleaseBuildNumber, 91);
    expect(pubspec, contains('version: 0.81.0+91'));
  });

  test('trusted release journey covers the consolidated critical surfaces', () {
    final journey =
        File('.maestro/applab-journey.json').readAsStringSync();
    final settings =
        File('.maestro/journey/settings.yaml').readAsStringSync();

    for (final checkpoint in [
      '"calendar"',
      '"week"',
      '"today"',
      '"memories"',
      '"people"',
      '"home"',
      '"archive"',
      '"shared"',
      '"account"',
      '"trash"',
      '"settings"',
    ]) {
      expect(journey, contains(checkpoint));
    }

    expect(settings, contains('Privacy Center'));
    expect(settings, contains('Cassaforte privata'));
    expect(settings, contains('Backup e sicurezza dati'));
    expect(settings, contains('Account e diritti sui dati'));
  });

  test('current architecture documentation reflects post-v0.80 domains', () {
    final architecture =
        File('docs/ARCHITECTURE.md').readAsStringSync();

    expect(architecture, contains('Current structure — v0.81.0'));
    expect(architecture, contains('src/life_archive_domain.dart'));
    expect(architecture, contains('src/notes_bridge.dart'));
    expect(architecture, contains('src/shopping_domain.dart'));
    expect(architecture, contains('src/workout_domain.dart'));
    expect(architecture, contains('src/screens/private_vault.dart'));
  });

  test('release candidate readiness records the four mandatory gates', () {
    final readiness =
        File('docs/PRODUCTION_READINESS_V081.md').readAsStringSync();

    expect(readiness, contains('Development checks'));
    expect(readiness, contains('Web release'));
    expect(readiness, contains('Android size audit'));
    expect(readiness, contains('AppLab Trusted Verify'));
    expect(readiness, contains('no bundled LLM'));
  });
}
