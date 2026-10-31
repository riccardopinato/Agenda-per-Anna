import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shared push uses neutral copy while retaining token and member guards', () {
    final source =
        File('supabase/functions/send-shared-push/index.ts').readAsStringSync();
    expect(source, contains('Spazio condiviso'));
    expect(source, isNot(contains('Noi ♡')));
    expect(source, contains('invalid_cron_authorization'));
    expect(source, contains('missing_authorization'));
    expect(source, contains('auth.getUser(accessJwt)'));
    expect(source, contains('not_a_space_member'));
    expect(source, contains('push_dedupe_failed'));
    expect(source, contains('sendFirebaseMessages'));
    expect(source, contains('sendWebPushMessages'));
  });
}
