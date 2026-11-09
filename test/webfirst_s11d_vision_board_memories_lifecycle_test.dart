import 'dart:typed_data';

import 'package:agenda_per_anna/local_state_store.dart';
import 'package:agenda_per_anna/main.dart';
import 'package:agenda_per_anna/media_asset_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// S11-D synthetic coverage, not manual real-browser or 2-device QA.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await LocalStateStore.instance.resetForTesting();
    await MediaAssetStore.instance.resetForTesting();
  });
  tearDown(() async {
    await LocalStateStore.instance.resetForTesting();
    await MediaAssetStore.instance.resetForTesting();
  });

  Future<AgendaStore> initializedStore() async {
    final store = AgendaStore();
    await store.load();
    await store.continueWithoutAccount();
    return store;
  }

  test('private gallery shows only live Vision Boards, not ordinary sketches',
      () async {
    final store = await initializedStore();
    final day = DateTime(2026, 11, 9);
    final board = VisionBoardFoundation.draft(
      visionBoardPresetsFor(const AnnaStrings('it'))[1], createdAt: day,
    );
    await store.saveJournal(day, DayJournal(blocks: [
      DiaryBlock(id: 'ordinary-sketch', type: DiaryBlockType.sketch,
        createdAt: day, pages: const [DiarySketchPage(id: 'old')]),
      board,
      board.copyWith(archived: true),
    ]));
    final refs = VisionBoardFoundation.personalBoards(store);
    // The duplicate id is synthetic; archived copy does not enter the gallery.
    expect(refs, hasLength(1));
    expect(refs.single.block.id, board.id);
    expect(VisionBoardMemories.current(store, refs.single), isNotNull);
    store.agendaContentFilter = AgendaContentFilter.sharedOnly;
    expect(VisionBoardFoundation.personalBoards(store), isEmpty);
    expect(VisionBoardMemories.current(store, refs.single), isNull);
    store.dispose();
  });

  test('link only current personal memories; dedupe, cap and roundtrip',
      () async {
    final store = await initializedStore();
    final day = DateTime(2026, 11, 9);
    final board = VisionBoardFoundation.draft(
      visionBoardPresetsFor(const AnnaStrings('it'))[2], createdAt: day,
    );
    final notes = [
      for (var i = 0; i < 15; i++)
        DiaryBlock(id: 'memory-$i', type: DiaryBlockType.note,
          createdAt: day, text: 'Ricordo $i'),
    ];
    await store.saveJournal(day, DayJournal(blocks: [board, ...notes]));
    final ref = VisionBoardFoundation.personalBoards(store).single;
    final guard = Cap0160TagEditGuard(store);
    expect(await VisionBoardMemories.saveLinks(
      store, ref,
      ['memory-0', 'memory-0', 'missing', board.id, ...notes.map((n) => n.id)],
      scopeGuard: guard,
    ), isTrue);
    final linkedBoard = VisionBoardFoundation.personalBoards(store).single;
    expect(linkedBoard.block.relatedBlockIds.length, 12);
    expect(linkedBoard.block.relatedBlockIds.toSet().length, 12);
    expect(linkedBoard.block.relatedBlockIds, isNot(contains(board.id)));
    expect(VisionBoardMemories.linked(store, linkedBoard), hasLength(12));
    expect(VisionBoardMemories.current(store, ref), isNull);
    expect(await VisionBoardMemories.saveLinks(
      store, ref, ['memory-0'], scopeGuard: guard,
    ), isFalse);
    store.dispose();
  });

  test('A to B to A, archived and shared-only fail closed', () async {
    final store = await initializedStore();
    final day = DateTime(2026, 11, 9);
    final board = VisionBoardFoundation.draft(
      visionBoardPresetsFor(const AnnaStrings('en')).first, createdAt: day,
    );
    await store.saveJournal(day, DayJournal(blocks: [
      board,
      DiaryBlock(id: 'target', type: DiaryBlockType.note,
        createdAt: day, text: 'Personal target'),
    ]));
    final ref = VisionBoardFoundation.personalBoards(store).single;
    final stale = Cap0160TagEditGuard(store);
    await store.activateCloudAccount('synthetic-new-account');
    await store.activateCloudAccount(null);
    expect(await VisionBoardMemories.saveLinks(
      store, ref, ['target'], scopeGuard: stale,
    ), isFalse);
    expect(await VisionBoardMemories.moveToTrash(
      store, ref, scopeGuard: stale,
    ), isFalse);
    final current = VisionBoardFoundation.personalBoards(store).single;
    store.agendaContentFilter = AgendaContentFilter.sharedOnly;
    expect(await VisionBoardMemories.saveLinks(
      store, current, ['target'],
      scopeGuard: Cap0160TagEditGuard(store),
    ), isFalse);
    expect(VisionBoardMemories.linked(store, current), isEmpty);
    store.agendaContentFilter = AgendaContentFilter.all;
    await store.saveJournal(day, DayJournal(blocks: [
      current.block.copyWith(archived: true),
    ]));
    expect(await VisionBoardMemories.moveToTrash(
      store, current, scopeGuard: Cap0160TagEditGuard(store),
    ), isFalse);
    store.dispose();
  });

  test('board Cestino restore preserves pages, links and media asset ID',
      () async {
    final store = await initializedStore();
    final day = DateTime(2026, 11, 9);
    final assetId = await MediaAssetStore.instance.put(
      Uint8List.fromList([5, 10, 20, 40]),
    );
    final draft = VisionBoardFoundation.draft(
      visionBoardPresetsFor(const AnnaStrings('it'))[1], createdAt: day,
    );
    final photo = DiarySketchImageElement(
      id: 'owned-image', mediaAssetId: assetId, x: 0.1, y: 0.1,
    );
    final board = draft.copyWith(
      pages: [draft.pages.first.copyWith(imageElements: [photo])],
      relatedBlockIds: const ['linked-memory'],
    );
    await store.saveJournal(day, DayJournal(blocks: [
      board,
      DiaryBlock(id: 'linked-memory', type: DiaryBlockType.note,
        createdAt: day, text: 'Resta'),
    ]));
    final ref = VisionBoardFoundation.personalBoards(store).single;
    expect(await VisionBoardMemories.moveToTrash(
      store, ref, scopeGuard: Cap0160TagEditGuard(store),
    ), isTrue);
    expect(VisionBoardFoundation.personalBoards(store), isEmpty);
    final trashed = store.trash.singleWhere((t) =>
      t.kind == TrashEntityKind.diaryBlock && t.entityId == board.id,
    );
    expect(await MediaAssetStore.instance.read(assetId), isNotNull);
    expect(await store.restoreTrashEntry(trashed.id), isTrue);
    final restored = VisionBoardFoundation.personalBoards(store).single.block;
    expect(restored.id, board.id);
    expect(restored.pages.first.imageElements.first.mediaAssetId, assetId);
    expect(restored.relatedBlockIds, ['linked-memory']);
    expect(await MediaAssetStore.instance.read(assetId), isNotNull);
    store.dispose();
  });

  test('ZIP backup preserves private board references and image bytes',
      () async {
    final store = await initializedStore();
    final day = DateTime(2026, 11, 9);
    final bytes = Uint8List.fromList(
      List<int>.generate(128, (i) => i % 251),
    );
    final assetId = await MediaAssetStore.instance.put(bytes);
    final board = VisionBoardFoundation.draft(
      visionBoardPresetsFor(const AnnaStrings('en'))[1], createdAt: day,
    );
    await store.saveJournal(day, DayJournal(blocks: [
      board.copyWith(
        relatedBlockIds: const ['note-1'],
        pages: [board.pages.single.copyWith(imageElements: [
          DiarySketchImageElement(
            id: 'image-1', mediaAssetId: assetId, x: 0.1, y: 0.1,
          ),
        ])],
      ),
      DiaryBlock(id: 'note-1', type: DiaryBlockType.note,
        createdAt: day, text: 'Private reference'),
    ]));
    final zip = await store.createBackupZip();
    expect(zip, isNotEmpty);
    store.dispose();
    await MediaAssetStore.instance.resetForTesting();

    final restored = AgendaStore();
    await restored.restoreBackupZip(zip, merge: false);
    final boards = restored.journal(day).blocks.where(
      (b) => b.isPersonalVisionBoard).toList();
    expect(boards, hasLength(1));
    expect(boards.single.relatedBlockIds, ['note-1']);
    expect(boards.single.pages.single.imageElements.single.mediaAssetId, assetId);
    expect(await MediaAssetStore.instance.read(assetId), orderedEquals(bytes));
    restored.dispose();
  });

  test('ZIP and open export fail closed for missing live or trashed board media',
      () async {
    final store = await initializedStore();
    final day = DateTime(2026, 11, 9);
    final preset = visionBoardPresetsFor(const AnnaStrings('it'))[0];
    final board = VisionBoardFoundation.draft(
      preset, createdAt: day,
    );
    final bad = board.copyWith(pages: [
      board.pages.single.copyWith(imageElements: const [
        DiarySketchImageElement(
          id: 'missing', mediaAssetId: 'unavailable-media-id',
          x: 0.1, y: 0.1,
        ),
      ]),
    ]);
    await store.saveJournal(day, DayJournal(blocks: [bad]));
    await expectLater(
      store.createBackupZip(), throwsA(isA<StateError>()),
    );
    await expectLater(
      store.createOpenExportZip(), throwsA(isA<StateError>()),
    );
    expect(await store.moveDiaryBlockToTrash(day, bad.id), isTrue);
    await expectLater(
      store.createBackupZip(), throwsA(isA<StateError>()),
    );
    expect(store.trash.where(
      (t) => t.kind == TrashEntityKind.diaryBlock), hasLength(1),
    );
    store.dispose();
  });

  testWidgets('Ricordi gallery shows boards, links and restores private boundary',
      (tester) async {
    final store = await initializedStore();
    addTearDown(store.dispose);
    final day = DateTime(2026, 11, 9);
    final board = VisionBoardFoundation.draft(
      visionBoardPresetsFor(const AnnaStrings('it'))[1], createdAt: day,
    );
    await store.saveJournal(day, DayJournal(blocks: [board]));
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(640, 1280);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('it'),
      supportedLocales: AnnaStrings.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: VisionBoardGalleryScreen(store: store),
    ));
    // A finite set of frames avoids the 10-minute pumpAndSettle watchdog
    // when a separate app-level ticker keeps scheduling transient frames.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Le mie Vision Board'), findsOneWidget);
    expect(find.byKey(ValueKey('vision-board-${board.id}')), findsOneWidget);
    expect(find.text('Collega ricordi'), findsOneWidget);
    // Change the actual store filter while the gallery stays mounted:
    // the resulting agenda/shared notifications must hide private content.
    store.setAgendaContentFilter(AgendaContentFilter.sharedOnly);
    // A finite set of frames avoids the 10-minute pumpAndSettle watchdog
    // when a separate app-level ticker keeps scheduling transient frames.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(ValueKey('vision-board-${board.id}')), findsNothing);
    expect(find.textContaining('non sono disponibili'), findsOneWidget);
    store.setAgendaContentFilter(AgendaContentFilter.all);
    // A finite set of frames avoids the 10-minute pumpAndSettle watchdog
    // when a separate app-level ticker keeps scheduling transient frames.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(ValueKey('vision-board-${board.id}')), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isFalse,
      reason: 'The static private gallery must not maintain a perpetual ticker');
    expect(tester.takeException(), isNull);
  });
}
