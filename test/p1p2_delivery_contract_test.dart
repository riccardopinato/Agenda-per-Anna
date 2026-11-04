import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Pages deployment uses the artifact produced by build-web', () {
    final source = File('.github/workflows/deploy-pages.yml').readAsStringSync();
    expect(source, contains(r'pages_artifact_name: ${{ steps.pages_artifact.outputs.name }}'));
    expect(source, contains(r'name: ${{ steps.pages_artifact.outputs.name }}'));
    expect(source, contains(r'artifact_name: ${{ needs.build-web.outputs.pages_artifact_name }}'));
    expect(source, isNot(contains(r'artifact_name: github-pages-${{ github.run_id }}-${{ github.run_attempt }}')));
  });

  test('AppLab catalog references real files, source roots and flows', () {
    final config = jsonDecode(File('applab.project.json').readAsStringSync())
        as Map<String, dynamic>;
    final journeys = config['journeys'] as Map<String, dynamic>;
    final catalog = journeys['catalog'] as Map<String, dynamic>;
    for (final entry in catalog.entries) {
      final journey = entry.value as Map<String, dynamic>;
      final flow = journey['flow'] as String;
      expect(File(flow).existsSync(), isTrue, reason: entry.key);
      for (final rawPath in (journey['paths'] as List).cast<String>()) {
        if (rawPath.endsWith('/**')) {
          final directory = rawPath.substring(0, rawPath.length - 3);
          expect(Directory(directory).existsSync(), isTrue,
              reason: '${entry.key}: ${rawPath}');
        } else {
          expect(File(rawPath).existsSync(), isTrue,
              reason: '${entry.key}: ${rawPath}');
        }
      }
    }
  });

  test('native smoke uses current four-tab UI5 navigation', () {
    final smoke = File('integration_test/app_smoke_test.dart').readAsStringSync();
    for (final id in <String>[
      'main-nav-today',
      'main-nav-messages',
      'main-nav-memories',
      'main-nav-more',
      'main-nav-create',
    ]) {
      expect(smoke, contains(id));
    }
    expect(smoke, isNot(contains("find.text('Mese')")));
    expect(smoke, isNot(contains("find.text('Settimana')")));
  });
}
