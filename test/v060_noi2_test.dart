import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:agenda_per_anna/cloud_sync_service.dart';

void main() {
  test('shared member payload remains deterministic and role-aware', () {
    final owner = SharedSpaceMember.fromJson({
      'user_id': 'owner-id',
      'role': 'owner',
      'display_name': 'Anna',
      'avatar_url': 'https://example.invalid/a.png',
    });
    final member = SharedSpaceMember.fromJson({
      'user_id': 'member-id',
      'role': 'member',
      'display_name': '',
    });

    expect(owner.isOwner, isTrue);
    expect(owner.displayName, 'Anna');
    expect(member.isOwner, isFalse);
    expect(member.displayName, 'Persona');
  });

  test('v0.60 member RPCs preserve owner and membership boundaries', () {
    final migration = File(
      'supabase/migrations/024_noi2_member_management_v060.sql',
    ).readAsStringSync();

    expect(migration, contains('space_membership_required'));
    expect(migration, contains('only_owner_can_remove_member'));
    expect(migration, contains('owner_cannot_be_removed'));
    expect(migration, contains('list_shared_space_members'));
    expect(migration, contains('remove_shared_space_member'));
    expect(
      migration,
      contains(
        'revoke all on function public.list_shared_space_members(uuid) from public, anon',
      ),
    );
    expect(
      migration,
      contains(
        'grant execute on function public.remove_shared_space_member(uuid, uuid) to authenticated',
      ),
    );
  });

  test('Noi destructive actions expose explicit per-user/per-space semantics', () {
    final screen =
        File('lib/src/screens/shared_space.dart').readAsStringSync();

    expect(screen, contains('Elimina per tutti'));
    expect(screen, contains('Lascia solo per me'));
    expect(screen, contains('Persone nello spazio'));
    expect(screen, contains('Rimuovi dallo spazio'));
  });
}
