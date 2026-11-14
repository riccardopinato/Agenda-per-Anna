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

  test('empty Inbox category persists across restart and keeps account prefs', () async {
    final first = AgendaStore();
    await first.load();
    expect(first.inbox, isEmpty);
    await first.createInboxCategory(' Viaggi   futuri ');
    await first.createInboxCategory('viaggi futuri');
    expect(first.inboxCategoryTags, ['Viaggi futuri']);
    expect(first.inbox, isEmpty);
    first.dispose();

    final second = AgendaStore();
    await second.load();
    expect(second.inboxCategoryTags, ['Viaggi futuri']);
    expect(second.preferences.toJson()['inboxCategoryCatalog'], ['Viaggi futuri']);
    expect(await second.renameInboxTag('Viaggi futuri', 'Weekend'), 0);
    expect(second.inboxCategoryTags, ['Weekend']);
    second.dispose();

    final third = AgendaStore();
    await third.load();
    expect(third.inboxCategoryTags, ['Weekend']);
    await third.removeUnusedInboxCategory('Weekend');
    expect(third.inboxCategoryTags, isEmpty);
    third.dispose();
  });

  test('empty category cannot be removed while referenced by a note', () async {
    final store = AgendaStore();
    await store.load();
    await store.createInboxCategory('Viaggi');
    await store.addInboxEntry('Un viaggio');
    await store.setInboxTags(store.inbox.single.id, ['Viaggi']);
    await expectLater(
      store.removeUnusedInboxCategory('Viaggi'),
      throwsStateError,
    );
    expect(store.inboxCategoryTags, ['Viaggi']);
    store.dispose();
  });

  test('organization tags normalize duplicates whitespace and cap', () {
    final values = normalizeOrganizationTags([
      ' viaggio ',
      'Viaggio',
      'famiglia   stretta',
      '',
      ...List<String>.generate(20, (i) => 'tag-$i'),
    ]);

    expect(values.first, 'viaggio');
    expect(values[1], 'famiglia stretta');
    expect(values.length, 12);
    expect(
      values.where((value) => value.toLowerCase() == 'viaggio').length,
      1,
    );
  });

  test('Inbox archive and tags survive restart', () async {
    final first = AgendaStore();
    await first.load();
    await first.addInboxEntry('Idea da sistemare');
    final id = first.inbox.single.id;

    await first.setInboxTags(id, ['idee', ' personale ', 'IDEE']);
    await first.toggleInboxArchived(id);

    expect(first.activeInboxEntries, isEmpty);
    expect(first.archivedInboxEntries.single.tags, ['idee', 'personale']);
    first.dispose();

    final second = AgendaStore();
    await second.load();
    expect(second.activeInboxEntries, isEmpty);
    expect(second.archivedInboxEntries.single.id, id);
    expect(second.archivedInboxEntries.single.tags, ['idee', 'personale']);
    second.dispose();
  });


  test('renaming Inbox tag changes active and archived notes, never diary', () async {
    final store = AgendaStore();
    await store.load();
    await store.addInboxEntry('Active idea');
    await store.addInboxEntry('Archived idea');
    final firstId = store.inbox.first.id;
    final secondId = store.inbox.last.id;
    await store.setInboxTags(firstId, ['idee', 'personale']);
    await store.setInboxTags(secondId, ['Idee']);
    await store.toggleInboxArchived(secondId);
    final date = DateTime(2026, 10, 31);
    await store.saveJournal(
      date,
      DayJournal(blocks: [
        DiaryBlock(
          id: 'preserve-diary-tags',
          type: DiaryBlockType.note,
          createdAt: date,
          text: 'Un ricordo',
          tags: ['idee'],
        ),
      ]),
    );

    expect(await store.renameInboxTag(' IDEE ', 'viaggi'), 2);
    expect(
      store.inbox.firstWhere((item) => item.id == firstId).tags,
      ['viaggi', 'personale'],
    );
    expect(
      store.inbox.firstWhere((item) => item.id == secondId).tags,
      ['viaggi'],
    );
    expect(store.inbox.firstWhere((item) => item.id == secondId).archived, true);
    expect(store.journal(date).blocks.single.tags, ['idee']);
    store.dispose();

    final reloaded = AgendaStore();
    await reloaded.load();
    expect(reloaded.inbox.firstWhere((e) => e.id == firstId).tags,
        ['viaggi', 'personale']);
    expect(reloaded.inbox.firstWhere((e) => e.id == secondId).tags,
        ['viaggi']);
    expect(reloaded.journal(date).blocks.single.tags, ['idee']);
    reloaded.dispose();
  });

  test('rename includes trashed Inbox notes and survives restart and restore',
      () async {
    final store = AgendaStore();
    await store.load();
    await store.createInboxCategory('Idee');
    await store.addInboxEntry('Active idea');
    await store.addInboxEntry('Archived idea');
    await store.addInboxEntry('Trashed idea');
    final activeId =
        store.inbox.firstWhere((e) => e.text == 'Active idea').id;
    final archiveId =
        store.inbox.firstWhere((e) => e.text == 'Archived idea').id;
    final trashedId =
        store.inbox.firstWhere((e) => e.text == 'Trashed idea').id;
    await store.setInboxTags(activeId, ['Idee', 'Personale']);
    await store.setInboxTags(archiveId, ['Idee']);
    await store.setInboxTags(trashedId, ['Idee', 'Casa']);
    await store.toggleInboxArchived(archiveId);
    await store.moveInboxToTrash(trashedId);
    final trashId = store.trash.single.id;
    final originalDeletedAt = store.trash.single.deletedAt;

    final day = DateTime(2026, 11, 14);
    await store.saveJournal(day, DayJournal(blocks: [
      DiaryBlock(
        id: 'diary-taxonomy-stays-private',
        type: DiaryBlockType.note,
        createdAt: day,
        text: 'Diary tags must not change',
        tags: ['Idee'],
      ),
    ]));

    expect(await store.renameInboxTag(' idee ', 'Progetti'), 3);
    expect(store.inbox.firstWhere((e) => e.id == activeId).tags,
        ['Progetti', 'Personale']);
    expect(store.inbox.firstWhere((e) => e.id == archiveId).tags,
        ['Progetti']);
    expect(store.inbox.firstWhere((e) => e.id == archiveId).archived, isTrue);
    expect(store.trash.single.id, trashId);
    expect(store.trash.single.deletedAt, originalDeletedAt);
    expect(store.trash.single.payload['tags'], ['Progetti', 'Casa']);
    expect(store.inboxCategoryTags, contains('Progetti'));
    expect(store.inboxCategoryTags, isNot(contains('Idee')));
    expect(store.journal(day).blocks.single.tags, ['Idee']);
    store.dispose();

    final restarted = AgendaStore();
    await restarted.load();
    expect(restarted.inboxCategoryTags, contains('Progetti'));
    expect(restarted.trash.single.id, trashId);
    expect(restarted.trash.single.payload['tags'], ['Progetti', 'Casa']);
    expect(await restarted.restoreTrashEntry(trashId), isTrue);
    expect(restarted.inbox.firstWhere((e) => e.id == trashedId).tags,
        ['Progetti', 'Casa']);
    expect(restarted.journal(day).blocks.single.tags, ['Idee']);
    restarted.dispose();
  });

  test('trash-only rename uses canonical Latin accent equality and dedupes',
      () async {
    final store = AgendaStore();
    await store.load();
    await store.addInboxEntry('Cafe note');
    final id = store.inbox.single.id;
    await store.setInboxTags(id, ['Cafe\u0301', 'Viaggi']);
    await store.moveInboxToTrash(id);
    expect(store.inbox, isEmpty);

    expect(await store.renameInboxTag('cafè', 'Viaggi'), 0);
    expect(await store.renameInboxTag('café', 'Viaggi'), 1);
    expect(store.trash.single.payload['tags'], ['Viaggi']);
    final trashId = store.trash.single.id;
    store.dispose();

    final restarted = AgendaStore();
    await restarted.load();
    expect(await restarted.restoreTrashEntry(trashId), isTrue);
    expect(restarted.inbox.single.tags, ['Viaggi']);
    restarted.dispose();
  });

  test('failed local batch leaves Inbox and Trash rename unchanged',
      () async {
    final store = AgendaStore();
    await store.load();
    await store.addInboxEntry('Live');
    await store.addInboxEntry('Deleted');
    final liveId = store.inbox.firstWhere((e) => e.text == 'Live').id;
    final deletedId = store.inbox.firstWhere((e) => e.text == 'Deleted').id;
    await store.setInboxTags(liveId, ['Idee']);
    await store.setInboxTags(deletedId, ['Idee']);
    await store.moveInboxToTrash(deletedId);

    LocalStateStore.instance.failNextBatchForTesting();
    await expectLater(
      store.renameInboxTag('Idee', 'Nuove idee'),
      throwsStateError,
    );
    expect(store.inbox.single.tags, ['Idee']);
    expect(store.trash.single.payload['tags'], ['Idee']);
    store.dispose();

    final restarted = AgendaStore();
    await restarted.load();
    expect(restarted.inbox.single.tags, ['Idee']);
    expect(restarted.trash.single.payload['tags'], ['Idee']);
    restarted.dispose();
  });

  test('renaming into existing tag deduplicates without destroying other tags',
      () async {
    final store = AgendaStore();
    await store.load();
    await store.addInboxEntry('Note');
    final id = store.inbox.single.id;
    await store.setInboxTags(id, ['idee', 'lavoro', 'casa']);
    expect(await store.renameInboxTag('idee', 'Lavoro'), 1);
    expect(store.inbox.single.tags, ['Lavoro', 'casa']);
    expect(await store.renameInboxTag('inesistente', 'altro'), 0);
    store.dispose();
  });


  test('Inbox category catalog and filter stay separated from diary tags',
      () async {
    final store = AgendaStore();
    await store.load();
    await store.addInboxEntry('Nota uno');
    await store.addInboxEntry('Nota due');
    final a = store.inbox.first.id;
    final b = store.inbox.last.id;
    await store.setInboxTags(a, ['Viaggi', 'personale']);
    await store.setInboxTags(b, ['viaggi']);
    await store.toggleInboxArchived(b);
    final day = DateTime(2026, 10, 30);
    await store.saveJournal(day, DayJournal(blocks: [
      DiaryBlock(
        id: 'diary-only-category',
        type: DiaryBlockType.note,
        createdAt: day,
        text: 'Diario',
        tags: ['esclusivo-diario'],
      ),
    ]));
    expect(store.inboxCategoryTags, ['personale', 'Viaggi']);
    expect(store.inboxEntriesInCategory('VIAGGI'), hasLength(1));
    expect(store.inboxEntriesInCategory('viaggi', includeArchived: true),
        hasLength(2));
    expect(store.inboxEntriesInCategory('viaggi').single.id, a);
    store.dispose();
  });

  test('diary pin archive and tags use ordinary journal persistence', () async {
    final store = AgendaStore();
    await store.load();
    final day = DateTime(2026, 9, 27);

    await store.saveJournal(
      day,
      DayJournal(
        blocks: [
          DiaryBlock(
            id: 'organized-memory',
            type: DiaryBlockType.note,
            createdAt: DateTime(2026, 9, 27, 8),
            text: 'Giornata in montagna',
          ),
        ],
      ),
    );

    await store.toggleDiaryPinned(day, 'organized-memory');
    await store.setDiaryTags(
      day,
      'organized-memory',
      ['montagna', 'Maya', 'montagna'],
    );
    await store.toggleDiaryArchived(day, 'organized-memory');

    final block = store.journal(day).blocks.single;
    expect(block.pinned, isTrue);
    expect(block.archived, isTrue);
    expect(block.tags, ['montagna', 'Maya']);

    store.dispose();

    final reloaded = AgendaStore();
    await reloaded.load();
    final restored = reloaded.journal(day).blocks.single;
    expect(restored.pinned, isTrue);
    expect(restored.archived, isTrue);
    expect(restored.tags, ['montagna', 'Maya']);
    reloaded.dispose();
  });

  test('organization metadata remains backward compatible', () {
    final inbox = InboxEntry.fromJson({
      'id': 'legacy-inbox',
      'text': 'Legacy',
      'createdAt': DateTime(2026, 9, 27).toIso8601String(),
      'pinned': true,
    });
    expect(inbox.pinned, isTrue);
    expect(inbox.archived, isFalse);
    expect(inbox.tags, isEmpty);

    final block = DiaryBlock.fromJson({
      'id': 'legacy-block',
      'type': DiaryBlockType.note.name,
      'createdAt': DateTime(2026, 9, 27).toIso8601String(),
      'text': 'Legacy diary',
    });
    expect(block.archived, isFalse);
    expect(block.pinned, isFalse);
    expect(block.tags, isEmpty);
  });
}
