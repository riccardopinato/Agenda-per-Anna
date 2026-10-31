import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('agenda shows real stored shared space names without legacy filters', () {
    final agenda = File('lib/src/unified_agenda.dart')
        .readAsStringSync();

    expect(agenda, contains("entry.space!.name.trim()"));
    expect(agenda, contains("AnnaStrings.of(context).d3('sharedSpace')"));
    expect(agenda, isNot(contains("entry.space!.name != 'Noi ♡'")));
  });
}
