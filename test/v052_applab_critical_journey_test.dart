import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AppLab critical journey covers core operational surfaces', () {
    final raw = File('.maestro/applab-journey.json').readAsStringSync();
    final journey = jsonDecode(raw) as Map<String, dynamic>;
    final checkpoints = (journey['checkpoints'] as List)
        .map((entry) => Map<String, dynamic>.from(entry as Map))
        .toList();
    final names = checkpoints.map((entry) => entry['name']).toList();

    expect(
      names,
      containsAllInOrder([
        'calendar',
        'week',
        'today',
        'memories',
        'people',
        'home',
        'shared',
        'account',
        'trash',
      ]),
    );
  });

  test('critical AppLab flows assert stable user-visible destinations', () {
    final home = File('.maestro/journey/home.yaml').readAsStringSync();
    final shared = File('.maestro/journey/shared.yaml').readAsStringSync();
    final account = File('.maestro/journey/account.yaml').readAsStringSync();
    final trash = File('.maestro/journey/trash.yaml').readAsStringSync();

    expect(home, contains('La mia agenda'));
    expect(shared, contains('Noi ♡'));
    expect(account, contains('Account e sincronizzazione'));
    expect(trash, contains('Archivio'));
    expect(trash, contains('Cestino'));
  });
}
