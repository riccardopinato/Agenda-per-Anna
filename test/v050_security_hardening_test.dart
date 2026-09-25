import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('privileged account media cleanup is scoped to the owning space', () {
    final source =
        File('supabase/functions/delete-account/index.ts').readAsStringSync();

    expect(source, contains('.select("space_id,payload")'));
    expect(source, contains('const spaceId = String(row.space_id ?? "").trim();'));
    expect(source, contains('path.startsWith(requiredPrefix)'));
    expect(
      source,
      contains('collectMediaPaths(row.payload, mediaPaths, `${spaceId}/`)'),
    );
    expect(
      source,
      isNot(contains('collectMediaPaths(row.payload, mediaPaths);')),
    );
  });

  test('web push tables expose no anonymous client grants', () {
    final migration = File(
      'supabase/migrations/023_web_push_anon_privilege_hardening_v050.sql',
    ).readAsStringSync();

    expect(
      migration,
      contains(
        'revoke all privileges on table public.web_push_reminders from anon;',
      ),
    );
    expect(
      migration,
      contains(
        'revoke all privileges on table public.web_push_subscriptions from anon;',
      ),
    );
  });

  test('delete-account remains JWT protected by repository contract', () {
    final source =
        File('supabase/functions/delete-account/index.ts').readAsStringSync();

    expect(source, contains('missing_authorization'));
    expect(source, contains('auth.getUser(accessToken)'));
    expect(source, contains('DELETE_MY_ACCOUNT'));
    expect(source, contains('admin.auth.admin.deleteUser(user.id)'));
  });
}
