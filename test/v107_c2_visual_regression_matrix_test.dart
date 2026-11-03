import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('C2 visual matrix covers real AppLab checkpoints', () {
    final matrix = jsonDecode(File('.maestro/applab-visual-matrix.json')
      .readAsStringSync()) as Map<String, dynamic>;
    final journey = jsonDecode(File('.maestro/applab-journey.json')
      .readAsStringSync()) as Map<String, dynamic>;
    final existing = (journey['checkpoints'] as List)
      .map((element) => (element as Map)['name'] as String).toSet();
    final checks = (matrix['checkpoints'] as List).cast<String>();
    expect(matrix['schema_version'], 1);
    expect(checks.length, 10);
    expect(checks.toSet().length, 10);
    for (final item in checks) {
      expect(existing, contains(item));
      expect(File('.maestro/journey/$item.yaml').existsSync(), isTrue);
    }
    for (final sensitive in ['vault', 'shared', 'account']) {
      expect(checks, isNot(contains(sensitive)));
      expect(matrix['excluded'], contains(sensitive));
    }
  });

  test('C2 variants cover five locales, themes, palette/HSV and accessibility', () {
    final matrix = jsonDecode(File('.maestro/applab-visual-matrix.json')
      .readAsStringSync()) as Map<String, dynamic>;
    final variants = (matrix['variants'] as List)
      .cast<Map<String, dynamic>>();
    expect(variants.map((v) => v['locale']).toSet(),
      containsAll(['en', 'it', 'es', 'fr', 'pt']));
    expect(variants.map((v) => v['theme']).toSet(),
      containsAll(['dark', 'light']));
    expect(variants.map((v) => v['palette']).toSet(),
      containsAll(['rose', 'lilac', 'sage', 'peach', 'sky', 'custom-hsv']));
    expect(variants.any((v) => (v['text_scale'] as num) >= 1.5), isTrue);
    expect(variants.any((v) => (v['width'] as num) <= 360), isTrue);
    expect(variants.any((v) => (v['width'] as num) >= 800), isTrue);
    expect(variants.any((v) => v['reduced_motion'] == true), isTrue);
    expect(variants.any((v) => v['seed_argb'] != null), isTrue);
    expect(matrix['capture_policy'], contains('synthetic-data-only'));
    expect(matrix['evidence_status'], contains('NOT_VERIFIED'));
  });
}
