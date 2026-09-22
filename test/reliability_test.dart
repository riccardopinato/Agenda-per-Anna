import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agenda_per_anna/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('sync health counts private and shared pending work', () async {
    final sharedOperation = SharedPendingOperation(
      action: SharedPendingAction.upsert,
      entityId: 'shared-1',
      payload: SharedEntry(
        id: 'shared-1',
        type: SharedEntryType.task,
        title: 'Noi',
        note: '',
        date: DateTime(2026, 9, 22),
      ).toJson(),
      updatedAt: DateTime.utc(2026, 9, 22, 11),
    );

    SharedPreferences.setMockInitialValues({
      'active_account_v1': 'user-a',
      'cloud_sync_queue_v1': jsonEncode({
        'item:private-1': {
          'entityType': 'item',
          'entityId': 'private-1',
          'payload': AgendaItem(
            id: 'private-1',
            title: 'Privato',
            note: '',
            date: DateTime(2026, 9, 22),
            type: ItemType.task,
          ).toJson(),
          'updatedAt': DateTime.utc(2026, 9, 22, 10).toIso8601String(),
          'deleted': false,
          'ownerId': 'user-a',
        },
      }),
      'shared_pending_user-a_space-a': jsonEncode([
        sharedOperation.toJson(),
      ]),
    });

    final store = AgendaStore();
    await store.load();

    expect(store.pendingCloudChanges, 1);
    expect(store.pendingSharedChangeCount, 1);
    expect(store.totalPendingCloudChanges, 2);

    store.dispose();
  });

  test('shared pending badge follows the active account scope', () async {
    final operation = SharedPendingOperation(
      action: SharedPendingAction.delete,
      entityId: 'shared-1',
      updatedAt: DateTime.utc(2026, 9, 22, 12),
    );

    SharedPreferences.setMockInitialValues({
      'active_account_v1': 'user-a',
      'shared_pending_user-a_space-a': jsonEncode([
        operation.toJson(),
      ]),
    });

    final store = AgendaStore();
    await store.load();
    expect(store.pendingSharedChangeCount, 1);

    await store.activateCloudAccount('user-b');
    expect(store.pendingSharedChangeCount, 0);

    await store.activateCloudAccount('user-a');
    expect(store.pendingSharedChangeCount, 1);

    store.dispose();
  });

  test('shared unread badge persists and clears per space', () async {
    SharedPreferences.setMockInitialValues({
      'active_account_v1': 'user-a',
      'shared_spaces_user-a': jsonEncode([
        {
          'id': 'space-a',
          'owner_id': 'user-a',
          'name': 'Noi ♡',
          'role': 'owner',
          'created_at': DateTime.utc(2026, 9, 1).toIso8601String(),
        }
      ]),
      'shared_unread_user-a': jsonEncode({'space-a': 2}),
    });

    final store = AgendaStore();
    await store.load();

    expect(store.sharedUnreadCount('space-a'), 2);
    expect(store.totalSharedUnreadCount, 2);

    await store.markSharedSpaceUnread('space-a');
    expect(store.sharedUnreadCount('space-a'), 3);

    final prefs = await SharedPreferences.getInstance();
    expect(
      Map<String, dynamic>.from(
        jsonDecode(prefs.getString('shared_unread_user-a')!) as Map,
      )['space-a'],
      3,
    );

    await store.markSharedSpaceRead('space-a');
    expect(store.sharedUnreadCount('space-a'), 0);
    expect(store.totalSharedUnreadCount, 0);

    store.dispose();
  });

  test('shared unread badge follows account scope', () async {
    SharedPreferences.setMockInitialValues({
      'active_account_v1': 'user-a',
      'shared_spaces_user-a': jsonEncode([
        {
          'id': 'space-a',
          'owner_id': 'user-a',
          'name': 'Noi ♡',
          'role': 'owner',
          'created_at': DateTime.utc(2026, 9, 1).toIso8601String(),
        }
      ]),
      'shared_spaces_user-b': jsonEncode([
        {
          'id': 'space-b',
          'owner_id': 'user-b',
          'name': 'Noi ♡',
          'role': 'owner',
          'created_at': DateTime.utc(2026, 9, 2).toIso8601String(),
        }
      ]),
      'shared_unread_user-a': jsonEncode({'space-a': 4}),
      'shared_unread_user-b': jsonEncode({'space-b': 1}),
    });

    final store = AgendaStore();
    await store.load();

    expect(store.totalSharedUnreadCount, 4);
    expect(store.sharedUnreadCount('space-a'), 4);

    await store.activateCloudAccount('user-b');
    expect(store.totalSharedUnreadCount, 1);
    expect(store.sharedUnreadCount('space-b'), 1);
    expect(store.sharedUnreadCount('space-a'), 0);

    await store.activateCloudAccount('user-a');
    expect(store.totalSharedUnreadCount, 4);
    expect(store.sharedUnreadCount('space-a'), 4);

    store.dispose();
  });

  test('backup metadata reports the current release line', () async {
    final store = AgendaStore();
    await store.load();

    final backup =
        Map<String, dynamic>.from(jsonDecode(store.createBackupJson()) as Map);

    expect(backup['appVersion'], '0.20.1');

    store.dispose();
  });
}
