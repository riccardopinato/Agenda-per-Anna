import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('visible localized copy no longer contains old decorative space label', () {
    for (final path in [
      'lib/src/localization.dart',
      'lib/src/localization_v100.dart',
      'lib/src/localization_d3.dart',
    ]) {
      final copy = File(path).readAsStringSync();
      expect(copy, isNot(contains('Noi ♡')), reason: path);
    }
    final shared = File('lib/src/screens/shared_space.dart').readAsStringSync();
    expect(shared, isNot(contains("title: const Text(\n              'Noi ♡'")));
    expect(shared, contains("AnnaStrings.of(context).d3('sharedSpace')"));
    final history = File('lib/src/unified_agenda.dart').readAsStringSync();
    // Historical user-generated space names remain unmodified.
    expect(history, contains("entry.space!.name != 'Noi ♡'"));
  });
}
