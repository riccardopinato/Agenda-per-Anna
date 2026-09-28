import 'dart:io';

import 'package:agenda_per_anna/app_version.dart';
import 'package:agenda_per_anna/local_state_store.dart';
import 'package:agenda_per_anna/main.dart';
import 'package:agenda_per_anna/media_asset_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  test('shared delete removes queued child interactions before reconnect',
      () async {
    final store = AgendaStore();
    await store.load();

    const spaceId = 'space-v067';
    const entryId = 'entry-v067';

    await store.enqueueSharedHeart(
      spaceId: spaceId,
      entryId: entryId,
      active: true,
    );
    await store.enqueueSharedComment(
      spaceId: spaceId,
      entryId: entryId,
      authorName: 'Test',
      body: 'Commento offline',
    );

    expect(
      await store.loadSharedInteractionPendingOperations(spaceId),
      hasLength(2),
    );

    await store.enqueueSharedDelete(
      spaceId: spaceId,
      entityId: entryId,
      updatedAt: DateTime.utc(2026, 9, 28, 9),
    );

    expect(
      await store.loadSharedInteractionPendingOperations(spaceId),
      isEmpty,
    );

    final parentOps = await store.loadSharedPendingOperations(spaceId);
    expect(parentOps, hasLength(1));
    expect(parentOps.single.entityId, entryId);
    expect(parentOps.single.action, SharedPendingAction.delete);

    store.dispose();
  });

  test('shared media cleanup queue is scoped and deduplicated', () async {
    final store = AgendaStore();
    await store.load();

    const spaceId = 'space-cleanup';
    const validPath = 'space-cleanup/entry-1/media.jpg';

    await store.enqueueSharedMediaCleanup(
      spaceId: spaceId,
      mediaPath: validPath,
    );
    await store.enqueueSharedMediaCleanup(
      spaceId: spaceId,
      mediaPath: validPath,
    );
    await store.enqueueSharedMediaCleanup(
      spaceId: spaceId,
      mediaPath: 'other-space/entry-1/media.jpg',
    );

    expect(
      await store.loadSharedMediaCleanupPaths(spaceId),
      [validPath],
    );

    store.dispose();
  });

  // Parent-before-child ordering is a lifecycle invariant: the shared entry
  // tombstone must win before any queued interaction can be retried.
  test('v0.67 shared sync keeps parent mutations before child interactions',
      () {
    final source = File('lib/src/agenda_store.dart').readAsStringSync();
    final syncStart = source.indexOf('Future<void> _syncSharedCloudWork()');
    final syncEnd = source.indexOf('Future<void> syncAllCloud', syncStart);
    expect(syncStart, greaterThanOrEqualTo(0));
    expect(syncEnd, greaterThan(syncStart));

    final block = source.substring(syncStart, syncEnd);
    final parent = block.indexOf('await flushSharedPendingOperations();');
    final children =
        block.indexOf('await flushSharedInteractionOperations();');
    final cleanup = block.indexOf('await flushSharedMediaCleanup();');

    expect(parent, greaterThanOrEqualTo(0));
    expect(children, greaterThan(parent));
    expect(cleanup, greaterThan(children));
  });

  test('v0.67 preserves deterministic private delete-edit reconciliation', () {
    final store = File('lib/src/agenda_store.dart').readAsStringSync();
    final merge = File(
      'supabase/migrations/'
      '20260921155617_deterministic_record_merge_v0161.sql',
    ).readAsStringSync();

    expect(
      store,
      contains(
        '!localOp.updatedAt.isAfter(record.clientUpdatedAt)',
      ),
    );
    expect(
      merge,
      contains(
        'excluded.client_updated_at > agenda_records.client_updated_at',
      ),
    );
  });

  test('v0.67 shared delete persists child cache removal', () {
    final screen =
        File('lib/src/screens/shared_space.dart').readAsStringSync();
    final deleteStart =
        screen.indexOf('Future<void> _delete(SharedEntry entry)');
    final deleteEnd = screen.indexOf('Future<void> _invite()', deleteStart);
    expect(deleteStart, greaterThanOrEqualTo(0));
    expect(deleteEnd, greaterThan(deleteStart));

    final block = screen.substring(deleteStart, deleteEnd);
    expect(block, contains('commentsByEntry.remove(entry.id)'));
    expect(block, contains('heartsByEntry.remove(entry.id)'));
    expect(block, contains('await _saveInteractionCache('));
  });

  test('v0.67 migration owns cross-user child cascade securely', () {
    final migration = File(
      'supabase/migrations/'
      '20260928092607_shared_entry_lifecycle_integrity_v067.sql',
    ).readAsStringSync();

    expect(
      migration,
      contains('cleanup_shared_entry_interactions_on_tombstone'),
    );
    expect(migration, contains('security definer'));
    expect(migration, contains("set search_path = ''"));
    expect(
      migration,
      contains(
        'revoke all on function '
        'private.cleanup_shared_entry_interactions_on_tombstone()',
      ),
    );
    expect(migration, contains('delete from public.shared_entry_comments'));
    expect(migration, contains('delete from public.shared_entry_reactions'));
  });

  test('v0.67 release metadata is aligned', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(appReleaseVersion, '0.67.0');
    expect(pubspec, contains('version: 0.67.0+77'));
  });
}
