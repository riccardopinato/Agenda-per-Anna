import 'dart:io';

import 'package:agenda_per_anna/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  testWidgets('Editorial memory surface remains accessible on narrow screens',
      (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    var opened = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          ),
        ),
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Center(
              child: AnnaEditorialSurface(
                key: const ValueKey<String>('ds4-visual-contract'),
                tone: AnnaEditorialSurfaceTone.featured,
                onTap: () => opened = true,
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_stories_outlined),
                    Text('Ricordo di prova', softWrap: true),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey<String>('ds4-visual-contract')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Ricordo di prova'));
    await tester.pump();
    expect(opened, isTrue);
    expect(tester.takeException(), isNull);
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
