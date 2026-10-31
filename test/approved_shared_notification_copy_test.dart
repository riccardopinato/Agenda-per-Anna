import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shared activity notifications use approved neutral labels', () {
    final notification = File('lib/notification_service.dart')
        .readAsStringSync();
    final push = File('supabase/functions/send-shared-push/index.ts')
        .readAsStringSync();
    final agenda = File('lib/src/unified_agenda.dart')
        .readAsStringSync();

    for (final actual in [notification, push, agenda]) {
      expect(actual, isNot(contains('Noi ♡')));
    }
    expect(notification, contains("'Spazio condiviso'"));
    expect(push, contains("Anna's Diary · Spazio condiviso"));
    expect(agenda, contains("AnnaStrings.of(context).d3('sharedSpace')"));
    // Historical user-defined group names stay stored and visible.
    expect(agenda, contains("entry.space!.name.trim()"));
  });
}
