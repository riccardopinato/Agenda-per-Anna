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

  test('shared delete discards pending child interactions for the same entry',
      () async {
    final store = AgendaStore();
    await store.load();
    await store.activateCloudAccount('user-lifecycle');

    await store.enqueueSharedComment(
      spaceId: 'space-a',
      entryId: 'entry-delete',
      authorName: 'Riccardo',
      body: 'Commento offline',
    );
    await store.enqueueSharedHeart(
      spaceId: 'space-a',
      entryId: 'entry-delete',
      active: true,
    );
    await store.enqueueSharedComment(
      spaceId: 'space-a',
      entryId: 'entry-keep',
      authorName: 'Riccardo',
      body: 'Da conservare',
    );

    final before =
        await store.loadSharedInteractionPendingOperations('space-a');
    expect(before.where((op) => op.entryId == 'entry-delete'), hasLength(2));
    expect(before.where((op) => op.entryId == 'entry-keep'), hasLength(1));

    await store.enqueueSharedDelete(
      spaceId: 'space-a',
      entityId: 'entry-delete',
      mediaPath: 'space-a/entry-delete/media.jpg',
    );

    final after =
        await store.loadSharedInteractionPendingOperations('space-a');
    expect(after.where((op) => op.entryId == 'entry-delete'), isEmpty);
    expect(after.where((op) => op.entryId == 'entry-keep'), hasLength(1));

    final entityOps = await store.loadSharedPendingOperations('space-a');
    expect(entityOps, hasLength(1));
    expect(entityOps.single.entityId, 'entry-delete');
    expect(entityOps.single.action, SharedPendingAction.delete);
    expect(
      entityOps.single.payload?['mediaPath'],
      'space-a/entry-delete/media.jpg',
    );

    store.dispose();
  });

  test('lifecycle hardening keeps deletion authoritative across sync paths', () {
    final agendaSource = File('lib/src/agenda_store.dart').readAsStringSync();
    final lifecycleSource =
        File('lib/src/lifecycle_domain.dart').readAsStringSync();

    expect(
      agendaSource,
      contains('remoteDeleted && !localDeleted'),
      reason: 'Private sync must explicitly distinguish tombstones from edits.',
    );
    expect(
      agendaSource,
      contains('_explicitRestoreKeys.contains(record.localKey)'),
      reason:
          'An intentional Trash restore must be distinguishable from a stale offline edit.',
    );
    expect(
      lifecycleSource,
      contains('await _markExplicitRestoreIntent(restoreTarget.$1, restoreTarget.$2);'),
      reason:
          'Restoring from Trash must persist explicit restore intent before cloud reconciliation.',
    );
    expect(
      agendaSource,
      contains('await _cancelWebPushRemindersForItem(record.entityId);'),
      reason:
          'A remote agenda tombstone must also cancel the account PWA reminder.',
    );
    expect(
      lifecycleSource,
      contains('await _cancelWebPushRemindersForItem(id);'),
      reason:
          'Moving an agenda item to Trash must clean remote PWA reminders from every platform.',
    );
    expect(
      agendaSource,
      contains('web_reminder_delete_retry_v1_'),
      reason:
          'Failed remote reminder deletions must survive offline reconnects.',
    );
    expect(
      agendaSource,
      contains('await _flushWebReminderDeleteRetries();'),
      reason:
          'Connectivity recovery must retry durable PWA reminder cleanup.',
    );
    expect(
      agendaSource,
      contains('await _discardSharedChildOperationsForEntry('),
      reason:
          'Deleting a Noi entry must not leave queued comments or reactions behind.',
    );
    expect(
      agendaSource,
      contains('await _queueSharedMediaDeleteRetry('),
      reason:
          'A failed shared-media deletion must remain recoverable for retry.',
    );

    final sharedSyncStart =
        agendaSource.indexOf('Future<void> _syncSharedCloudWork() async');
    final prePull = agendaSource.indexOf(
      'await refreshSharedAgendaCache(',
      sharedSyncStart,
    );
    final flush = agendaSource.indexOf(
      'await flushSharedPendingOperations();',
      sharedSyncStart,
    );
    expect(sharedSyncStart, greaterThanOrEqualTo(0));
    expect(prePull, greaterThan(sharedSyncStart));
    expect(flush, greaterThan(prePull),
        reason:
            'Shared sync must pull tombstones before flushing offline entity edits.');
  });
}
