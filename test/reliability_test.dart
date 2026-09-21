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

  test('backup metadata reports the current release line', () async {
    final store = AgendaStore();
    await store.load();

    final backup =
        Map<String, dynamic>.from(jsonDecode(store.createBackupJson()) as Map);

    expect(backup['appVersion'], '0.20.0');

    store.dispose();
  });
}
