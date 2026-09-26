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

  test('legacy diary blocks remain connection-compatible', () {
    final legacy = DiaryBlock.fromJson({
      'id': 'legacy',
      'type': DiaryBlockType.note.name,
      'createdAt': DateTime(2026, 10, 5).toIso8601String(),
      'text': 'Vecchio ricordo',
    });
    expect(legacy.relatedBlockIds, isEmpty);

    final linked = legacy.copyWith(relatedBlockIds: ['other']);
    final restored = DiaryBlock.fromJson(linked.toJson());
    expect(restored.relatedBlockIds, ['other']);
  });

  test('connections validate targets persist and derive backlinks', () async {
    final store = AgendaStore();
    await store.load();
    final firstDay = DateTime(2026, 10, 1);
    final secondDay = DateTime(2026, 10, 2);

    await store.saveJournal(
      firstDay,
      DayJournal(
        blocks: [
          DiaryBlock(
            id: 'a',
            type: DiaryBlockType.note,
            createdAt: DateTime(2026, 10, 1, 9),
            text: 'Primo ricordo',
          ),
        ],
      ),
    );
    await store.saveJournal(
      secondDay,
      DayJournal(
        blocks: [
          DiaryBlock(
            id: 'b',
            type: DiaryBlockType.note,
            createdAt: DateTime(2026, 10, 2, 9),
            text: 'Secondo ricordo',
          ),
        ],
      ),
    );

    await store.setDiaryBlockConnections(
      firstDay,
      'a',
      ['a', 'missing', 'b', 'b'],
    );

    final a = store.diaryBlockReferenceById('a')!.block;
    expect(a.relatedBlockIds, ['b']);
    expect(store.relatedDiaryBlocks(a).single.block.id, 'b');
    expect(store.backlinksForDiaryBlock('b').single.block.id, 'a');
    store.dispose();

    final reloaded = AgendaStore();
    await reloaded.load();
    expect(
      reloaded.diaryBlockReferenceById('a')!.block.relatedBlockIds,
      ['b'],
    );
    expect(reloaded.backlinksForDiaryBlock('b').single.block.id, 'a');
    reloaded.dispose();
  });

  test('permanent purge removes dangling diary backlinks', () async {
    final store = AgendaStore();
    await store.load();
    final day = DateTime(2026, 10, 6);
    await store.saveJournal(
      day,
      DayJournal(
        blocks: [
          DiaryBlock(
            id: 'source',
            type: DiaryBlockType.note,
            createdAt: DateTime(2026, 10, 6, 8),
            text: 'Source',
            relatedBlockIds: const ['target'],
          ),
          DiaryBlock(
            id: 'target',
            type: DiaryBlockType.note,
            createdAt: DateTime(2026, 10, 6, 9),
            text: 'Target',
          ),
        ],
      ),
    );

    expect(await store.moveDiaryBlockToTrash(day, 'target'), isTrue);
    expect(
      store.diaryBlockReferenceById('source')!.block.relatedBlockIds,
      ['target'],
    );

    final targetTrash = store.trash
        .firstWhere((entry) => entry.entityId == 'target');
    expect(
      await store.purgeTrashEntry(
        targetTrash.id,
        createSafetySnapshot: false,
      ),
      isTrue,
    );

    expect(
      store.diaryBlockReferenceById('source')!.block.relatedBlockIds,
      isEmpty,
    );
    store.dispose();
  });

  test('global search narrows all tokens across personal domains', () async {
    final store = AgendaStore();
    await store.load();

    await store.savePerson(
      const PersonEntry(
        id: 'anna',
        name: 'Anna',
        relationship: 'Compagna',
        note: 'Montagna insieme',
      ),
    );
    await store.saveJournal(
      DateTime(2026, 10, 7),
      DayJournal(
        blocks: [
          DiaryBlock(
            id: 'memory',
            type: DiaryBlockType.note,
            createdAt: DateTime(2026, 10, 7, 12),
            text: 'Passeggiata al rifugio',
            tags: const ['montagna'],
            personIds: const ['anna'],
          ),
          DiaryBlock(
            id: 'archived',
            type: DiaryBlockType.note,
            createdAt: DateTime(2026, 10, 7, 13),
            text: 'Segreto archiviato',
            archived: true,
          ),
        ],
      ),
    );
    await store.upsert(
      AgendaItem(
        id: 'event',
        title: 'Dentista',
        note: 'Controllo annuale',
        date: DateTime(2026, 10, 8),
        type: ItemType.appointment,
      ),
    );
    await store.addInboxEntry('Comprare il regalo montagna');

    final diary = store.personalSearch(
      'anna montagna',
      kinds: {PersonalSearchKind.diary},
    );
    expect(diary.map((hit) => hit.diaryBlockId), contains('memory'));

    final person = store.personalSearch(
      'anna compagna',
      kinds: {PersonalSearchKind.person},
    );
    expect(person.single.personId, 'anna');

    final agenda = store.personalSearch(
      'dentista annuale',
      kinds: {PersonalSearchKind.agenda},
    );
    expect(agenda.single.agendaItem!.id, 'event');

    final inbox = store.personalSearch(
      'regalo montagna',
      kinds: {PersonalSearchKind.inbox},
    );
    expect(inbox.single.inboxId, isNotNull);

    expect(store.personalSearch('segreto archiviato'), isEmpty);
    expect(
      store.personalSearch(
        'segreto archiviato',
        includeArchived: true,
      ).map((hit) => hit.diaryBlockId),
      contains('archived'),
    );
    store.dispose();
  });
}
