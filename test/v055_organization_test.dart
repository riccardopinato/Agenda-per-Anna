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
