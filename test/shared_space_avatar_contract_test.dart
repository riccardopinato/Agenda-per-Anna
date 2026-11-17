import 'dart:io';

import 'package:agenda_per_anna/cloud_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const shared = <String, dynamic>{
    'id': '11111111-1111-1111-1111-111111111111',
    'owner_id': '22222222-2222-2222-2222-222222222222',
    'name': 'Il nostro diario',
    'created_at': '2026-11-17T15:12:00Z',
  };

  test('older shared-space caches remain compatible without avatar_path', () {
    final space = SharedSpace.fromJson(shared, role: 'member');
    expect(space.avatarPath, isEmpty);
    expect(space.name, 'Il nostro diario');
    expect(space.id, shared['id']);
  });

  test('current space profile image is account/space scoped', () {
    const avatarPath =
        '11111111-1111-1111-1111-111111111111/__space_avatar/'
        '33333333-3333-4333-8333-333333333333.jpg';
    final space = SharedSpace.fromJson({
      ...shared,
      'avatar_path': avatarPath,
    }, role: 'owner');
    expect(space.avatarPath, avatarPath);
    expect(space.isOwner, isTrue);
  });

  test('storage owner policy and canonical RPC are enforced by migration', () {
    final sql = File('supabase/migrations/100_shared_space_avatar_v139.sql')
        .readAsStringSync();
    expect(sql, contains("add column if not exists avatar_path"));
    expect(sql, contains("v_entry_id = '__space_avatar'"));
    expect(sql, contains('owner_id = v_user'));
    expect(sql, contains('v_owner is distinct from v_user'));
    expect(sql, contains('private.set_shared_space_avatar_impl'));
    expect(sql, contains("set avatar_path = v_path"));
    expect(sql, contains('to authenticated'));
    expect(sql, isNot(contains('grant update on table public.shared_spaces')));
    expect(sql, isNot(contains('grant execute on function public.set_shared_space_avatar(uuid, text)\n  to anon')));
  });

  test('avatar is not a diary media orphan and remains private', () {
    final service = File('lib/cloud_sync_service.dart').readAsStringSync();
    final sharedUi = File('lib/src/screens/shared_space.dart').readAsStringSync();
    final store = File('lib/src/agenda_store.dart').readAsStringSync();
    final organic = File('lib/src/organic_pastel_design.dart').readAsStringSync();

    expect(service, contains(".select('id,owner_id,name,created_at,avatar_path')"));
    expect(service, contains("client.rpc('set_shared_space_avatar'"));
    expect(service, contains("storage.from('shared-media').uploadBinary"));
    expect(service, contains("!path.contains('/__space_avatar/')"));
    expect(store, contains("'avatar_path': space.avatarPath"));
    expect(sharedUi, contains('chooseAndSaveSharedSpaceAvatar('));
    expect(sharedUi, contains('sharedSpaceCanRename(space,'));
    expect(sharedUi, contains('bytes[0] != 0xFF'));
    expect(sharedUi, contains('SharedSpaceAvatar('));
    expect(sharedUi, contains("'avatar_path': space.avatarPath"));
    expect(organic, contains('final Widget? avatar;'));
    expect(organic, contains('onChangePhoto'));
    expect(sharedUi, contains('if (value == \'avatar\')'));
  });
}
