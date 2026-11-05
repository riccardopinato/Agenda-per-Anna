import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agenda_per_anna/main.dart';
import 'package:agenda_per_anna/local_state_store.dart';
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

  test('places group all private memories, including singletons and no GPS',
      () async {
    final store = AgendaStore();
    await store.load();
    Future<void> save(String id, DateTime day, String name,
        {bool archived = false}) async {
      await store.saveJournal(day, DayJournal(blocks: [
        DiaryBlock(
          id: id,
          type: DiaryBlockType.note,
          createdAt: day,
          archived: archived,
          text: 'Ricordo $id',
          places: [DiaryPlaceReference(name: name)],
        ),
      ]));
    }

    await save('first', DateTime(2026, 1, 2), 'Monselice');
    await save('second', DateTime(2026, 2, 2), 'MONSELICE');
    await save('single', DateTime(2026, 3, 2), 'Padova');
    await save('archived', DateTime(2026, 4, 2), 'Privato',
        archived: true);
    final groups = store.memoryMapSnapshot().places;
    expect(groups.map((p) => p.key), ['monselice', 'padova']);
    expect(groups.first.count, 2);
    expect(groups.last.count, 1);
    expect(store.memoryLifeThreadReferences('place:padova'), hasLength(1));
    expect(store.memoryLifeThreadReferences('place:privato'), isEmpty);
    store.dispose();
  });

  test('places UI reuses existing MemoryMap and renders full list lazily', () {
    final source = File('lib/src/screens/memory_collections_screen.dart')
        .readAsStringSync();
    expect(source, contains('memoryMapSnapshot().places'));
    expect(source, contains("key: const ValueKey('memories-by-place-heading')"));
    expect(source, contains('placeGroups.take(6)'));
    expect(source, contains('ListView.builder('));
    expect(source, contains('memoryLifeThreadReferences('));
    expect(source, isNot(contains('MemoryPlacesDatabase')));
  });

  test('places UI has five locales and a clear empty state', () {
    for (final code in ['it', 'en', 'es', 'fr', 'pt']) {
      for (final key in ['title', 'intro', 'empty', 'all']) {
        expect(memoryPlacesCopy(code, key), isNotEmpty);
      }
    }
  });
}
