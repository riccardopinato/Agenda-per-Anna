import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agenda_per_anna/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<AgendaStore> seededStore() async {
    final prefs = await SharedPreferences.getInstance();
    final privateItem = AgendaItem(
      id: 'private-1',
      title: 'Studio',
      note: '',
      date: DateTime(2026, 9, 22),
      type: ItemType.task,
      category: AgendaCategory.study,
    );
    final sharedAppointment = SharedEntry(
      id: 'shared-1',
      type: SharedEntryType.appointment,
      title: 'Cena insieme',
      note: '',
      date: DateTime(2026, 9, 22),
      start: const TimeOfDay(hour: 20, minute: 0),
      end: const TimeOfDay(hour: 22, minute: 0),
      editorName: 'Anna',
    );
    final sharedNote = SharedEntry(
      id: 'shared-note',
      type: SharedEntryType.note,
      title: 'Idea weekend',
      note: '',
      date: DateTime(2026, 9, 22),
    );

    await prefs.setString('active_account_v1', 'user-a');
    await prefs.setString('items_v1', jsonEncode([privateItem.toJson()]));
    await prefs.setString(
      'shared_spaces_user-a',
      jsonEncode([
        {
          'id': 'space-a',
          'owner_id': 'user-a',
          'name': 'Noi ♡',
          'role': 'owner',
          'created_at': DateTime.utc(2026, 9, 1).toIso8601String(),
        }
      ]),
    );
    await prefs.setString(
      'shared_cache_user-a_space-a',
      jsonEncode([
        sharedAppointment.toCacheJson(),
        sharedNote.toCacheJson(),
      ]),
    );

    final store = AgendaStore();
    await store.load();
    return store;
  }

  test('unified agenda combines private and shared calendar entries', () async {
    final store = await seededStore();

    final all = store.unifiedForDay(DateTime(2026, 9, 22));
    expect(all, hasLength(2));
    expect(all.where((entry) => entry.isPrivate), hasLength(1));
    expect(all.where((entry) => entry.isShared), hasLength(1));
    expect(
      all.any((entry) => entry.title == 'Idea weekend'),
      isFalse,
      reason: 'Shared notes do not belong in calendar views.',
    );

    store.dispose();
  });

  test('unified filter never leaks the opposite visibility', () async {
    final store = await seededStore();

    store.setAgendaContentFilter(AgendaContentFilter.privateOnly);
    expect(store.unifiedAgendaItems, hasLength(1));
    expect(store.unifiedAgendaItems.single.isPrivate, isTrue);

    store.setAgendaContentFilter(AgendaContentFilter.sharedOnly);
    expect(store.unifiedAgendaItems, hasLength(1));
    expect(store.unifiedAgendaItems.single.isShared, isTrue);
    expect(store.unifiedAgendaItems.single.visibilityLabel, 'Noi ♡');

    store.dispose();
  });

  test('offline shared edit immediately updates unified cache', () async {
    final store = await seededStore();

    await store.enqueueSharedUpsert(
      spaceId: 'space-a',
      entry: SharedEntry(
        id: 'shared-1',
        type: SharedEntryType.appointment,
        title: 'Cena spostata',
        note: '',
        date: DateTime(2026, 9, 22),
        start: const TimeOfDay(hour: 21, minute: 0),
      ),
      updatedAt: DateTime.utc(2026, 9, 22, 18),
    );

    store.setAgendaContentFilter(AgendaContentFilter.sharedOnly);
    final shared = store.unifiedForDay(DateTime(2026, 9, 22));
    expect(shared, hasLength(1));
    expect(shared.single.title, 'Cena spostata');
    expect(shared.single.start, const TimeOfDay(hour: 21, minute: 0));
    expect(await store.pendingSharedChanges('space-a'), 1);

    store.dispose();
  });

  test('offline shared delete disappears from unified agenda immediately',
      () async {
    final store = await seededStore();

    await store.enqueueSharedDelete(
      spaceId: 'space-a',
      entityId: 'shared-1',
      updatedAt: DateTime.utc(2026, 9, 22, 19),
    );

    store.setAgendaContentFilter(AgendaContentFilter.sharedOnly);
    expect(store.unifiedForDay(DateTime(2026, 9, 22)), isEmpty);
    expect(await store.pendingSharedChanges('space-a'), 1);

    store.dispose();
  });
}
