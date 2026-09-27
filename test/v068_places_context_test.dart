import 'dart:io';

import 'package:agenda_per_anna/app_version.dart';
import 'package:agenda_per_anna/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('v0.68 PlaceEntry is lightweight and portable', () {
    const place = PlaceEntry(
      id: 'p1',
      name: 'Lago di Neves',
      category: 'Montagna',
      address: 'Valle Aurina',
      note: 'Posto speciale',
      favorite: true,
    );

    final restored = PlaceEntry.fromJson(place.toJson());
    expect(restored.name, 'Lago di Neves');
    expect(restored.category, 'Montagna');
    expect(restored.address, 'Valle Aurina');
    expect(restored.favorite, isTrue);
  });

  test('v0.68 diary blocks link places without duplicating memories', () {
    final block = DiaryBlock(
      id: 'm1',
      type: DiaryBlockType.photo,
      createdAt: DateTime(2026, 9, 28),
      placeIds: const ['p1', 'p2'],
    );
    final restored = DiaryBlock.fromJson(block.toJson());

    expect(restored.placeIds, ['p1', 'p2']);
    expect(restored.toJson()['placeIds'], ['p1', 'p2']);
  });

  test('v0.68 place memories reuse Memory Engine records', () {
    final store = AgendaStore();
    store.places.add(
      const PlaceEntry(
        id: 'p1',
        name: 'Casa',
      ),
    );
    store.journals['2026-09-28'] = DayJournal(
      blocks: [
        DiaryBlock(
          id: 'm1',
          type: DiaryBlockType.note,
          createdAt: DateTime(2026, 9, 28, 10),
          text: 'Mattina',
          placeIds: const ['p1'],
        ),
      ],
    );

    expect(store.memoriesForPlace('p1').single.block.id, 'm1');
    expect(store.placeMemoryCount('p1'), 1);
    expect(store.lastMemoryDateForPlace('p1'), DateTime(2026, 9, 28));
  });

  test('v0.68 storage and search reuse existing private infrastructure', () {
    final store =
        File('lib/src/agenda_store.dart').readAsStringSync();
    final places =
        File('lib/src/places_domain.dart').readAsStringSync();
    final search =
        File('lib/src/search_connections_domain.dart').readAsStringSync();
    final backup =
        File('lib/src/store/backup_domain.dart').readAsStringSync();
    final lifecycle =
        File('lib/src/lifecycle_domain.dart').readAsStringSync();

    expect(store, contains("static const _placesKey = 'places_v1'"));
    expect(store, contains("add('place', place.id, place.toJson())"));
    expect(store, contains("'place' => _placesKey"));
    expect(places, contains("type: 'place'"));
    expect(places, contains('tagDiaryBlockPlaces'));
    expect(search, contains('PersonalSearchKind.place'));
    expect(search, contains('linkedPlaces'));
    expect(backup, contains("'places': store.places"));
    expect(lifecycle, contains('TrashEntityKind.place'));
  });

  test('v0.68 does not introduce tracking or map dependencies', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final places =
        File('lib/src/places_domain.dart').readAsStringSync();

    expect(pubspec, isNot(contains('geolocator')));
    expect(pubspec, isNot(contains('google_maps_flutter')));
    expect(pubspec, isNot(contains('mapbox')));
    expect(places, isNot(contains('latitude')));
    expect(places, isNot(contains('longitude')));
  });

  test('v0.68 release metadata is aligned', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(appReleaseVersion, '0.68.0');
    expect(pubspec, contains('version: 0.68.0+78'));
  });
}
