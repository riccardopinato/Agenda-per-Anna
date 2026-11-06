import 'dart:io';

import 'package:agenda_per_anna/local_state_store.dart';
import 'package:agenda_per_anna/main.dart';
import 'package:agenda_per_anna/media_asset_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await LocalStateStore.instance.resetForTesting();
    await MediaAssetStore.instance.resetForTesting();
    AnnaEditorialTodayMode.enabled.value = false;
  });

  tearDown(() async {
    AnnaEditorialTodayMode.enabled.value = false;
    await LocalStateStore.instance.resetForTesting();
    await MediaAssetStore.instance.resetForTesting();
  });

  test('DS4 preserves the single canonical memory projection and routes', () {
    final classic = File('lib/src/diary/diary_memories.dart').readAsStringSync();
    final editorial =
        File('lib/src/diary/editorial_memories.dart').readAsStringSync();
    final main = File('lib/main.dart').readAsStringSync();

    expect(main, contains("part 'src/diary/editorial_memories.dart';"));
    expect(classic, contains('widget.store.memoryRecallSnapshot('));
    expect(classic, contains('widget.store.memoryReferences('));
    expect(classic, contains('AnnaEditorialTodayMode.enabled.value'));
    expect(classic, contains('_editorialFeaturedMemory(context, record)'));
    expect(classic, contains('_editorialTimelineMemoryCard(context, record)'));
    expect(classic, contains('AnnaJournalPageHeader('));
    expect(classic, contains('AnnaEditorialHeader('));
    expect(classic, contains('ContextualMemoryPanel('));
    expect(classic, contains('_memoryExploreSurface('));
    expect(classic, contains('_memoryMonthSurface('));

    for (final contract in <String>[
      'memories-for-you-hero',
      'memories-for-you-surface',
      'memories-timeline-surface',
      'memories-timeline-list',
      'memories-memory-map-entry',
      'memories-then-now-entry',
      'memories-collections-entry',
      'memories-for-you',
      'memories-timeline',
      'memories-browse',
      'memories-editorial-featured',
      'memories-editorial-timeline-',
    ]) {
      expect('$classic\n$editorial', contains(contract));
    }
    expect(editorial, contains('block.hasPhotoMedia'));
    expect(editorial, contains('DiaryBlockType.sketch'));
    expect(editorial, contains('_coverPreview(context, record)'));
    expect(editorial, contains('_openRecord(record)'));
    expect(editorial, contains('_openPhoto(record)'));
    expect(editorial, isNot(contains('saveJournal(')));
    expect(editorial, isNot(contains('MemoryDatabase')));
    expect(editorial, isNot(contains('MemoryRepository')));
  });

  testWidgets('Editorial Ricordi shows a genuine saved note and Classic returns',
      (tester) async {
    await initializeDateFormatting('it_IT', null);
    final store = AgendaStore();
    await store.load();
    await store.continueWithoutAccount();

    final now = DateTime.now();
    final pastDay = DateTime(now.year - 1, now.month, now.day);
    await store.saveJournal(
      pastDay,
      DayJournal(blocks: [
        DiaryBlock(
          id: 'ds4-authentic-note',
          type: DiaryBlockType.note,
          text: 'Ricordo autentico DS4',
          createdAt: pastDay.add(const Duration(hours: 12)),
        ),
      ]),
    );

    AnnaEditorialTodayMode.enabled.value = true;
    await tester.pumpWidget(
      AgendaApp(store: store, bypassIdentityForTesting: true),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));

    await tester.tap(find.byKey(const ValueKey<String>('main-nav-memories')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));

    expect(find.byKey(const ValueKey<String>('memories-editorial-featured')),
        findsOneWidget);
    expect(find.textContaining('Ricordo autentico DS4'), findsWidgets);
    expect(find.byType(DiaryMediaImage), findsNothing);
    expect(tester.takeException(), isNull);

    AnnaEditorialTodayMode.enabled.value = false;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));
    expect(find.byKey(const ValueKey<String>('memories-editorial-featured')),
        findsNothing);
    expect(find.byKey(const ValueKey<String>('memories-editorial-hero')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    store.dispose();
  });

  test('Editorial memories preserve unmodified filters and authoring paths', () {
    final source = File('lib/src/diary/diary_memories.dart').readAsStringSync();
    for (final method in <String>[
      'Future<void> _showFilterSheet()',
      'Future<void> _showBrowseSheet()',
      'Widget _timelineView(',
      'Widget _daysView(',
      'Widget _monthsView(',
      'Widget _yearsView(',
      'Future<void> _openRecord(',
      'Future<void> _openPhoto(',
      'void _',
    ]) {
      expect(source, contains(method));
    }
    final newSource =
        File('lib/src/diary/editorial_memories.dart').readAsStringSync();
    for (final forbidden in <String>[
      'Supabase',
      'SharedPreferences',
      'MediaAssetStore',
      'saveJournal(',
      'setAgendaContentFilter(',
    ]) {
      expect(newSource, isNot(contains(forbidden)));
    }
  });
}
