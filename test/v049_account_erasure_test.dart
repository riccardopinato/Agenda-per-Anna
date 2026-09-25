import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agenda_per_anna/local_state_store.dart';
import 'package:agenda_per_anna/main.dart';
import 'package:agenda_per_anna/media_asset_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await LocalStateStore.instance.resetForTesting();
    await MediaAssetStore.instance.resetForTesting();
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    await LocalStateStore.instance.resetForTesting();
    await MediaAssetStore.instance.resetForTesting();
  });

  test('account erasure removes only the erased cloud profile locally',
      () async {
    final store = AgendaStore();
    await store.load();

    await store.activateCloudAccount('user-a');
    await store.upsert(
      AgendaItem(
        id: 'private-a',
        title: 'Solo account A',
        note: '',
        date: DateTime(2026, 9, 25),
        type: ItemType.task,
      ),
    );
    await store.addInboxEntry('Inbox account A');

    await store.activateCloudAccount(null);
    await store.addInboxEntry('Inbox guest');

    await store.activateCloudAccount('user-a');
    expect(store.items.map((item) => item.id), contains('private-a'));
    expect(store.inbox.map((entry) => entry.text), contains('Inbox account A'));

    final state = await LocalStateStore.instance.open(
      legacyPreferences: await SharedPreferences.getInstance(),
    );
    await state.setString('shared_cache_user-a_space-1', '[]');
    await state.setString('shared_pending_user-a_space-1', '[]');
    await state.setString('shared_unread_user-a', '{}');
    await state.setString('cloud_first_sync_snapshot_user-a', '{}');

    await store.eraseLocalCloudAccount('user-a');

    expect(store.activeAccountId, isNull);
    expect(store.items.map((item) => item.id), isNot(contains('private-a')));
    expect(store.inbox.map((entry) => entry.text), contains('Inbox guest'));
    expect(
      store.inbox.map((entry) => entry.text),
      isNot(contains('Inbox account A')),
    );

    final profilesRaw = state.getString('account_profiles_v1');
    final profiles = profilesRaw == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(profilesRaw) as Map);
    expect(profiles.containsKey('user:user-a'), isFalse);
    expect(
      state.getKeys().where((key) => key.contains('user-a')),
      isEmpty,
    );

    store.dispose();
  });

  test('account deletion backend requires authenticated explicit erasure',
      () {
    final function =
        File('supabase/functions/delete-account/index.ts').readAsStringSync();
    final cloud = File('lib/cloud_sync_service.dart').readAsStringSync();
    final screen =
        File('lib/src/screens/cloud_account.dart').readAsStringSync();

    expect(function, contains('explicit_confirmation_required'));
    expect(function, contains('DELETE_MY_ACCOUNT'));
    expect(function, contains('auth.getUser'));
    expect(function, contains('admin.auth.admin.deleteUser(user.id)'));
    expect(function, contains('.from("shared_spaces")'));
    expect(function, contains('.from("agenda_records")'));
    expect(function, contains('storage.remove(chunk)'));

    expect(cloud, contains("functions.invoke("));
    expect(cloud, contains("'delete-account'"));
    expect(cloud, contains('SignOutScope.local'));

    expect(screen, contains('Scrivi ELIMINA per confermare.'));
    expect(screen, contains('Elimina account e dati'));
    expect(
      screen,
      contains('quello spazio viene eliminato anche per gli altri membri'),
    );
  });
}
