import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agenda_per_anna/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('local changes are captured in cloud sync queue', () async {
    final store = AgendaStore();
    await store.load();

    final before = store.pendingCloudChanges;

    await store.upsert(
      AgendaItem(
        id: 'cloud-item-1',
        title: 'Appuntamento',
        note: '',
        date: DateTime(2026, 9, 21),
        type: ItemType.appointment,
        start: const TimeOfDay(hour: 18, minute: 30),
      ),
    );

    expect(store.pendingCloudChanges, greaterThan(before));
  });

  test('sync queue survives store reload', () async {
    final first = AgendaStore();
    await first.load();

    await first.addInboxEntry('Idea da sincronizzare');
    final queued = first.pendingCloudChanges;

    final second = AgendaStore();
    await second.load();

    expect(second.pendingCloudChanges, queued);
  });

  test('updating the same entity replaces pending operation', () async {
    final store = AgendaStore();
    await store.load();

    final item = AgendaItem(
      id: 'same-item',
      title: 'Prima versione',
      note: '',
      date: DateTime(2026, 9, 21),
      type: ItemType.task,
    );

    await store.upsert(item);
    final afterFirst = store.pendingCloudChanges;

    await store.upsert(item.copyWith(title: 'Seconda versione'));
    final afterSecond = store.pendingCloudChanges;

    expect(afterSecond, afterFirst);
  });

  test('deleting an entity keeps a tombstone pending for cloud', () async {
    final store = AgendaStore();
    await store.load();

    final item = AgendaItem(
      id: 'delete-item',
      title: 'Da eliminare',
      note: '',
      date: DateTime(2026, 9, 21),
      type: ItemType.task,
    );

    await store.upsert(item);
    final beforeDelete = store.pendingCloudChanges;

    await store.deleteItem(item.id);

    expect(store.pendingCloudChanges, greaterThanOrEqualTo(beforeDelete));
    expect(store.items.where((e) => e.id == item.id), isEmpty);
  });
}
