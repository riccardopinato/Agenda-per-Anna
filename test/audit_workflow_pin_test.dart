import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('critical Actions are pinned to immutable and verified SHAs', () {
    for (final path in [
      '.github/workflows/dev-checks.yml',
      '.github/workflows/deploy-pages.yml',
      '.github/workflows/applab.yml',
      '.github/workflows/sideload-arm64.yml',
    ]) {
      final workflow = File(path).readAsStringSync();
      final uses = RegExp(r'(?m)^\s*-\s*uses:\s*([^\s#]+)')
          .allMatches(workflow)
          .map((match) => match.group(1)!)
          .toList();
      expect(uses, isNotEmpty, reason: path);
      for (final ref in uses) {
        expect(RegExp(r'@[0-9a-f]{40}$').hasMatch(ref), isTrue,
            reason: '$path: $ref must use a full action SHA');
      }
    }
  });
}
