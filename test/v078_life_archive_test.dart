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

  test('life archive derives history from canonical domains', () async {
    final store = AgendaStore();
    await store.load();

    await store.upsert(
      AgendaItem(
        id: 'agenda-past',
        title: 'Dentista',
        note: 'Controllo annuale',
        date: DateTime(2026, 8, 12),
        type: ItemType.appointment,
      ),
    );
    await store.upsert(
      AgendaItem(
        id: 'agenda-future',
        title: 'Futuro',
        note: '',
        date: DateTime(2200, 1, 1),
        type: ItemType.appointment,
      ),
    );

    await store.saveJournal(
      DateTime(2026, 7, 10),
      DayJournal(
        blocks: [
          DiaryBlock(
            id: 'diary',
            type: DiaryBlockType.note,
            createdAt: DateTime(2026, 7, 10, 18),
            text: 'Passeggiata al lago',
            places: const [DiaryPlaceReference(name: 'Lago di Braies')],
          ),
        ],
      ),
    );

    await store.addWorkoutSession(
      sport: WorkoutSport.running,
      date: DateTime(2026, 6, 3),
      title: 'Lungo',
      durationSeconds: 3600,
      distanceKm: 15,
      note: 'Argine',
    );

    await store.addInboxEntry('Idea viaggio Dolomiti');
    final inboxId = store.inbox.single.id;
    await store.setInboxTags(inboxId, ['viaggio']);
    await store.toggleInboxArchived(inboxId);

    final entries = store.lifeArchiveEntries(
      through: DateTime(2100, 1, 1),
    );

    expect(entries.map((entry) => entry.id), contains('agenda:agenda-past'));
    expect(entries.map((entry) => entry.id), isNot(contains('agenda:agenda-future')));
    expect(entries.map((entry) => entry.id), contains('diary:diary'));
    expect(
      entries.where((entry) => entry.kind == LifeArchiveKind.workout),
      hasLength(1),
    );
    expect(
      entries.where((entry) => entry.kind == LifeArchiveKind.inbox),
      hasLength(1),
    );

    store.dispose();
  });

  test('archive search is multi-word and kind-aware', () async {
    final store = AgendaStore();
    await store.load();

    await store.saveJournal(
      DateTime(2026, 8, 14),
      DayJournal(
        blocks: [
          DiaryBlock(
            id: 'memory',
            type: DiaryBlockType.note,
            createdAt: DateTime(2026, 8, 14, 12),
            text: 'Vacanza insieme',
            places: const [DiaryPlaceReference(name: 'Campo Tures')],
          ),
        ],
      ),
    );
    await store.addWorkoutSession(
      sport: WorkoutSport.hiking,
      date: DateTime(2026, 8, 13),
      title: 'Escursione',
      note: 'Valle Aurina',
    );

    final diary = store.lifeArchiveEntries(
      through: DateTime(2026, 9, 29),
      query: 'vacanza campo',
      kind: LifeArchiveKind.diary,
    );
    expect(diary.map((entry) => entry.id), ['diary:memory']);

    final wrongKind = store.lifeArchiveEntries(
      through: DateTime(2026, 9, 29),
      query: 'vacanza campo',
      kind: LifeArchiveKind.workout,
    );
    expect(wrongKind, isEmpty);

    store.dispose();
  });

  test('manually archived content stays recoverable in the open archive',
      () async {
    final store = AgendaStore();
    await store.load();
    final day = DateTime(2026, 5, 4);

    await store.saveJournal(
      day,
      DayJournal(
        blocks: [
          DiaryBlock(
            id: 'archived-memory',
            type: DiaryBlockType.note,
            createdAt: day,
            text: 'Da conservare',
            archived: true,
          ),
        ],
      ),
    );
    await store.addInboxEntry('Inbox conservata');
    await store.toggleInboxArchived(store.inbox.single.id);

    final entries = store.lifeArchiveEntries(
      through: DateTime(2100, 1, 1),
    );
    expect(
      entries.firstWhere((entry) => entry.id == 'diary:archived-memory').archived,
      isTrue,
    );
    expect(
      entries.firstWhere((entry) => entry.kind == LifeArchiveKind.inbox).archived,
      isTrue,
    );

    store.dispose();
  });

  test('v0.78 archive is derived and introduces no parallel persistence', () {
    final main = File('lib/main.dart').readAsStringSync();
    final domain = File('lib/src/life_archive_domain.dart').readAsStringSync();
    final screen =
        File('lib/src/screens/home_inbox_search.dart').readAsStringSync();

    expect(main, contains("part 'src/life_archive_domain.dart';"));
    expect(domain, contains('List<LifeArchiveEntry> lifeArchiveEntries('));
    expect(screen, contains('strings.lifeArchive'));
    expect(screen, contains('lifeArchiveEntries('));

    for (final forbidden in [
      'life_archive_v1',
      '_lifeArchiveKey',
      'setString(',
      'writeBatch(',
      'supabase',
    ]) {
      expect(domain.toLowerCase(), isNot(contains(forbidden.toLowerCase())));
    }
  });
}
