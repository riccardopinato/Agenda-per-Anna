import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final sql = File(
    'supabase/migrations/099_owner_shared_space_rename_v109.sql',
  ).readAsStringSync();
  final cloud = File('lib/cloud_sync_service.dart').readAsStringSync();
  final screen = File('lib/src/screens/shared_space.dart').readAsStringSync();

  test('owner-only rename updates name without changing stable IDs', () {
    expect(sql, contains('v_owner is distinct from v_user'));
    expect(sql, contains('only_owner_can_rename_space'));
    expect(sql, contains('if v_user is null'));
    expect(sql, contains('if char_length(v_name) < 1'));
    expect(sql, contains('char_length(v_name) > 60'));
    expect(sql, contains('for update;'));
    expect(sql, contains('set name = v_name'));
    expect(sql, isNot(contains('set id =')));
    expect(sql, isNot(contains('delete from public.shared_spaces')));
    expect(sql, isNot(contains('update public.space_members')));
    expect(sql, isNot(contains('update public.space_invites')));
    expect(sql, contains('security definer'));
    expect(sql, contains("set search_path = ''"));
    expect(sql, contains('grant execute on function public.rename_shared_space'));
    expect(sql, contains('to authenticated'));
  });

  test('client calls audited server RPC instead of changing shared table', () {
    expect(cloud, contains('Future<String> renameSharedSpace('));
    expect(cloud, contains("_requireSignedInClient()"));
    expect(cloud, contains("'rename_shared_space'"));
    expect(cloud, contains("'p_space_id': spaceId"));
    expect(cloud, contains("'p_name': trimmed"));
    expect(cloud, isNot(contains(".from('shared_spaces').update(")));
  });

  test('only owner sees rename and all five languages have labels', () {
    expect(screen, contains('if (space.isOwner)'));
    expect(screen, contains('shared-rename-'));
    expect(screen, contains('_renameSpace(space)'));
    expect(screen, contains('!space.isOwner || loading'));
    expect(screen, contains('await _reload()'));
    expect(screen, contains("key: const ValueKey<String>('shared-rename-name')"));
    for (final label in ['Rename group', 'Rinomina gruppo',
      'Renombrar grupo', 'Renommer le groupe', 'Renomear grupo']) {
      expect(screen, contains(label));
    }
    expect(screen, contains('widget.store.markSharedSpaceRead('));
    expect(screen, contains('SharedSpaceScreen('));
    expect(screen, contains('current.expiresAt.difference('));
    expect(screen, contains('SharedInviteQrArtCard('));
  });
}
