import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agenda_per_anna/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('shared entry round-trip preserves calendar data', () {
    final original = SharedEntry(
      id: 'shared-1',
      type: SharedEntryType.appointment,
      title: 'Cena insieme',
      note: 'Prenotazione alle 20',
      date: DateTime(2026, 9, 21),
      start: const TimeOfDay(hour: 20, minute: 0),
      end: const TimeOfDay(hour: 22, minute: 0),
      editorName: 'Anna',
    );

    final restored = SharedEntry.fromJson(
      original.toJson(),
      updatedBy: 'user-2',
      updatedAt: DateTime.utc(2026, 9, 21, 18),
    );

    expect(restored.id, original.id);
    expect(restored.type, SharedEntryType.appointment);
    expect(restored.title, 'Cena insieme');
    expect(restored.start?.hour, 20);
    expect(restored.end?.hour, 22);
    expect(restored.updatedBy, 'user-2');
    expect(restored.editorName, 'Anna');
    expect(restored.updatedAt, DateTime.utc(2026, 9, 21, 18));
  });

  test('shared cache keeps server revision metadata', () {
    final original = SharedEntry(
      id: 'cache-1',
      type: SharedEntryType.note,
      title: 'Idea',
      note: 'Weekend',
      date: DateTime(2026, 9, 23),
      updatedBy: 'user-a',
      updatedAt: DateTime.utc(2026, 9, 23, 10, 15),
      editorName: 'Riccardo',
    );

    final restored = SharedEntry.fromCacheJson(original.toCacheJson());

    expect(restored.updatedBy, 'user-a');
    expect(restored.updatedAt, DateTime.utc(2026, 9, 23, 10, 15));
    expect(restored.editorName, 'Riccardo');
  });

  test('shared task preserves completion state', () {
    final task = SharedEntry(
      id: 'task-1',
      type: SharedEntryType.task,
      title: 'Comprare i biglietti',
      note: '',
      date: DateTime(2026, 9, 22),
      done: true,
    );

    final restored = SharedEntry.fromJson(task.toJson());

    expect(restored.type, SharedEntryType.task);
    expect(restored.done, isTrue);
  });

  test('pending shared operation round-trip is deterministic', () {
    final revision = DateTime.utc(2026, 9, 21, 18, 30);
    final operation = SharedPendingOperation(
      action: SharedPendingAction.upsert,
      entityId: 'shared-1',
      payload: {'id': 'shared-1', 'title': 'Cena'},
      updatedAt: revision,
    );

    final restored = SharedPendingOperation.fromJson(operation.toJson());

    expect(restored.action, SharedPendingAction.upsert);
    expect(restored.entityId, 'shared-1');
    expect(restored.payload?['title'], 'Cena');
    expect(restored.updatedAt, revision);
  });

  test('shared queue coalesces repeated edits and delete wins', () async {
    final store = AgendaStore();
    await store.load();
    await store.activateCloudAccount('user-a');

    final first = SharedEntry(
      id: 'entry-1',
      type: SharedEntryType.note,
      title: 'Prima',
      note: '',
      date: DateTime(2026, 9, 21),
    );
    final second = first.copyWith(title: 'Seconda');

    await store.enqueueSharedUpsert(
      spaceId: 'space-1',
      entry: first,
      updatedAt: DateTime.utc(2026, 9, 21, 10),
    );
    await store.enqueueSharedUpsert(
      spaceId: 'space-1',
      entry: second,
      updatedAt: DateTime.utc(2026, 9, 21, 11),
    );

    var queue = await store.loadSharedPendingOperations('space-1');
    expect(queue, hasLength(1));
    expect(queue.single.action, SharedPendingAction.upsert);
    expect(queue.single.payload?['title'], 'Seconda');

    await store.enqueueSharedDelete(
      spaceId: 'space-1',
      entityId: 'entry-1',
      updatedAt: DateTime.utc(2026, 9, 21, 12),
    );

    queue = await store.loadSharedPendingOperations('space-1');
    expect(queue, hasLength(1));
    expect(queue.single.action, SharedPendingAction.delete);
    expect(queue.single.updatedAt, DateTime.utc(2026, 9, 21, 12));
  });

  test('shared queue remains account scoped', () async {
    final store = AgendaStore();
    await store.load();
    await store.activateCloudAccount('user-a');
    await store.enqueueSharedDelete(
      spaceId: 'space-1',
      entityId: 'a-only',
    );

    await store.activateCloudAccount('user-b');
    expect(await store.pendingSharedChanges('space-1'), 0);

    await store.enqueueSharedDelete(
      spaceId: 'space-1',
      entityId: 'b-only',
    );
    expect(await store.pendingSharedChanges('space-1'), 1);

    await store.activateCloudAccount('user-a');
    final queue = await store.loadSharedPendingOperations('space-1');
    expect(queue.map((operation) => operation.entityId), contains('a-only'));
    expect(
      queue.map((operation) => operation.entityId),
      isNot(contains('b-only')),
    );
  });
}
