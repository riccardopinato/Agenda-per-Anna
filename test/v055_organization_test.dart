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
