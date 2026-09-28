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

  test('memory projections share the canonical diary reference primitive',
      () async {
    final store = AgendaStore();
    await store.load();
    await store.savePerson(
      const PersonEntry(id: 'anna', name: 'Anna'),
    );

    await store.saveJournal(
      DateTime(2025, 9, 28),
      DayJournal(
        blocks: [
          DiaryBlock(
            id: 'old-memory',
            type: DiaryBlockType.note,
            createdAt: DateTime(2025, 9, 28, 12),
            text: 'Ricordo insieme',
            personIds: const ['anna'],
          ),
        ],
      ),
    );
    await store.saveJournal(
      DateTime(2026, 9, 27),
      DayJournal(
        blocks: [
          DiaryBlock(
            id: 'recent-memory',
            type: DiaryBlockType.note,
            createdAt: DateTime(2026, 9, 27, 12),
            text: 'Ricordo recente',
            personIds: const ['anna'],
          ),
        ],
      ),
    );

    final all = store.memoryReferences(
      includeArchived: true,
      personId: 'anna',
    );
    final people = store.memoriesForPerson('anna');
    final onThisDay = store.onThisDayMemories(
      DateTime(2026, 9, 28),
      personId: 'anna',
    );

    expect(all.map((entry) => entry.block.id),
        ['recent-memory', 'old-memory']);
    expect(people.map((entry) => entry.block.id),
        ['recent-memory', 'old-memory']);
    expect(onThisDay.map((entry) => entry.block.id), ['old-memory']);
    store.dispose();
  });

  test('memory review introduces no parallel persistent engine', () {
    final search =
        File('lib/src/search_connections_domain.dart').readAsStringSync();
    final people = File('lib/src/people_domain.dart').readAsStringSync();
    final memories =
        File('lib/src/diary/diary_memories.dart').readAsStringSync();
    final store = File('lib/src/agenda_store.dart').readAsStringSync();

    expect(search, contains('List<DiaryBlockReference> memoryReferences('));
    expect(people, contains('typedef PersonMemoryReference = DiaryBlockReference;'));
    expect(memories, contains('widget.store.memoryReferences('));
    expect(memories, isNot(contains('class _DiaryMemoryRecord')));
    expect(store, isNot(contains('memory_engine')));
    expect(store, isNot(contains('memories_v1')));
  });
}
