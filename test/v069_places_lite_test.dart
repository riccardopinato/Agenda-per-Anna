import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agenda_per_anna/local_state_store.dart';
import 'package:agenda_per_anna/main.dart';
import 'package:agenda_per_anna/media_asset_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('it_IT', null);
  });

  setUp(() async {
    await LocalStateStore.instance.resetForTesting();
    await MediaAssetStore.instance.resetForTesting();
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    await LocalStateStore.instance.resetForTesting();
    await MediaAssetStore.instance.resetForTesting();
  });

  test('legacy diary blocks remain Places Lite compatible', () {
    final legacy = DiaryBlock.fromJson({
      'id': 'legacy',
      'type': DiaryBlockType.note.name,
      'createdAt': DateTime(2026, 9, 28).toIso8601String(),
      'text': 'Ricordo senza luogo',
    });
    expect(legacy.places, isEmpty);
  });

  test('inline places round-trip and persist through the journal path',
      () async {
    final store = AgendaStore();
    await store.load();
    final day = DateTime(2026, 9, 28);

    await store.saveJournal(
      day,
      DayJournal(
        blocks: [
          DiaryBlock(
            id: 'memory',
            type: DiaryBlockType.note,
            createdAt: day,
            text: 'Passeggiata',
          ),
        ],
      ),
    );
    await store.setDiaryBlockPlaces(
      day,
      'memory',
      const [
        DiaryPlaceReference(
          name: 'Lago di Braies',
          latitude: 46.6947,
          longitude: 12.0859,
        ),
        DiaryPlaceReference(name: '  Lago di Braies  '),
      ],
    );

    expect(store.journal(day).blocks.single.places, hasLength(1));
    expect(store.journal(day).blocks.single.places.single.name, 'Lago di Braies');
    expect(store.diaryPlaceNames, ['Lago di Braies']);
    store.dispose();

    final reloaded = AgendaStore();
    await reloaded.load();
    final place = reloaded.journal(day).blocks.single.places.single;
    expect(place.name, 'Lago di Braies');
    expect(place.latitude, closeTo(46.6947, 0.00001));
    expect(place.longitude, closeTo(12.0859, 0.00001));
    reloaded.dispose();
  });

  test('global search and memory search source include place references',
      () async {
    final store = AgendaStore();
    await store.load();
    final day = DateTime(2026, 9, 28);
    await store.saveJournal(
      day,
      DayJournal(
        blocks: [
          DiaryBlock(
            id: 'dolomiti',
            type: DiaryBlockType.photo,
            createdAt: day,
            text: 'Giornata insieme',
            places: const [DiaryPlaceReference(name: 'Tre Cime')],
          ),
        ],
      ),
    );

    final diary = store.personalSearch(
      'Tre Cime',
      kinds: {PersonalSearchKind.diary},
    );
    expect(diary.map((hit) => hit.diaryBlockId), contains('dolomiti'));

    final places = store.personalSearch(
      'Tre Cime',
      kinds: {PersonalSearchKind.place},
    );
    expect(places, hasLength(1));
    expect(places.single.placeName, 'Tre Cime');
    expect(store.memoriesForPlace('tre cime').single.block.id, 'dolomiti');
    store.dispose();

    final memoriesSource =
        File('lib/src/diary/diary_memories.dart').readAsStringSync();
    expect(
      memoriesSource,
      contains('...block.places.map((place) => place.name)'),
    );
  });

  test('Places Lite does not introduce a parallel persistent store', () {
    final storeSource = File('lib/src/agenda_store.dart').readAsStringSync();
    final modelSource = File('lib/src/domain_models.dart').readAsStringSync();
    expect(modelSource, contains('class DiaryPlaceReference'));
    expect(storeSource, isNot(contains('places_v1')));
    expect(storeSource, isNot(contains('_placesKey')));
  });
}
