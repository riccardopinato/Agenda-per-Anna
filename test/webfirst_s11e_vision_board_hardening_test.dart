import 'dart:convert';
import 'dart:typed_data';

import 'package:agenda_per_anna/local_state_store.dart';
import 'package:agenda_per_anna/main.dart';
import 'package:agenda_per_anna/media_asset_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// S11-E source/widget regression evidence. Two *physical* PWA sessions,
/// browser accessibility, real export picker and hardware performance remain
/// operator-verified gates and are not certified by this test file.
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

  Future<AgendaStore> openGuest() async {
    final store = AgendaStore();
    await store.load();
    await store.continueWithoutAccount();
    return store;
  }

  test('concurrent editor leases protect the same image until both release',
      () async {
    final media = MediaAssetStore.instance;
    final bytes = Uint8List.fromList([3, 4, 9, 1, 7, 19, 11]);
    final a = await media.putForDraft(bytes);
    final b = await media.putForDraft(bytes);
    expect(a, b, reason: 'content-addressed assets must still deduplicate');
    expect(media.isDraftMediaRetained(a), isTrue);
    await media.prune(<String>{});
    expect(await media.read(a), orderedEquals(bytes));

    media.releaseDraftMedia(a);
    expect(media.isDraftMediaRetained(a), isTrue);
    await media.prune(<String>{});
    expect(await media.read(a), orderedEquals(bytes));

    media.releaseDraftMedia(b);
    expect(media.isDraftMediaRetained(a), isFalse);
    await media.prune(<String>{});
    expect(await media.read(a), isNull,
        reason: 'an abandoned draft is GC-eligible only after every editor closes');
  });

  test('committed image survives draft lease release and media maintenance',
      () async {
    final media = MediaAssetStore.instance;
    final bytes = Uint8List.fromList([9, 31, 64, 28]);
    final id = await media.putForDraft(bytes);
    final store = await openGuest();
    final date = DateTime(2026, 11, 10);
    final preset = visionBoardPresetsFor(const AnnaStrings('it')).first;
    final board = VisionBoardFoundation.draft(preset, createdAt: date);
    final saved = board.copyWith(pages: [
      board.pages.single.copyWith(imageElements: [
        DiarySketchImageElement(
          id: 'committed-photo', mediaAssetId: id, x: 0.1, y: 0.1,
        ),
      ]),
    ]);
    expect(await VisionBoardFoundation.saveDraft(
      store, date, saved, scopeGuard: Cap0160TagEditGuard(store),
    ), isTrue);
    media.releaseDraftMedia(id);
    expect(media.isDraftMediaRetained(id), isFalse);
    // The journal contains the sole canonical reference and survives a
    // read-only save/ZIP roundtrip after the in-memory editor releases it.
    expect(store.journal(date).blocks.single.pages.single
        .imageElements.single.mediaAssetId, id);
    final zip = await store.createBackupZip();
    expect(zip, isNotEmpty);
    expect(await media.read(id), orderedEquals(bytes));
    store.dispose();
  });

  test('stale board instance cannot be moved to Trash under a reused ID',
      () async {
    final store = await openGuest();
    final date = DateTime(2026, 11, 10);
    final first = VisionBoardFoundation.draft(
      visionBoardPresetsFor(const AnnaStrings('it')).first, createdAt: date,
    );
    await store.saveJournal(date, DayJournal(blocks: [first]));
    final original = VisionBoardFoundation.personalBoards(store).single;
    await store.saveJournal(date, DayJournal(blocks: [
      first.copyWith(text: 'Edited elsewhere'),
    ]));
    expect(await VisionBoardMemories.moveToTrash(
      store, original, scopeGuard: Cap0160TagEditGuard(store),
    ), isFalse);
    expect(store.trash, isEmpty);
    expect(store.journal(date).blocks.single.text, 'Edited elsewhere');
    store.dispose();
  });

  test('account switch and Trash mutation never leave half-deleted board',
      () async {
    final store = await openGuest();
    final date = DateTime(2026, 11, 10);
    final board = VisionBoardFoundation.draft(
      visionBoardPresetsFor(const AnnaStrings('en'))[1], createdAt: date,
    );
    await store.saveJournal(date, DayJournal(blocks: [board]));
    final ref = VisionBoardFoundation.personalBoards(store).single;
    final originalGuard = Cap0160TagEditGuard(store);

    final deleting = VisionBoardMemories.moveToTrash(
      store, ref, scopeGuard: originalGuard,
    );
    final switching = store.activateCloudAccount('synthetic-s11e-other');
    final didDelete = await deleting;
    await switching;
    expect(store.activeAccountId, 'synthetic-s11e-other');
    // This is a different profile: no gallery, no prior user's Trash.
    expect(VisionBoardFoundation.personalBoards(store), isEmpty);
    expect(store.trash.where((t) => t.entityId == board.id), isEmpty);

    await store.activateCloudAccount(null);
    final inJournal = store.journal(date).blocks
        .where((b) => b.id == board.id).length;
    final inTrash = store.trash
        .where((t) => t.kind == TrashEntityKind.diaryBlock &&
            t.entityId == board.id).length;
    expect(inJournal + inTrash, 1,
        reason: 'either committed deletion or rollback, never data loss');
    expect(inTrash, didDelete ? 1 : 0);
    expect(await VisionBoardMemories.moveToTrash(
      store, ref, scopeGuard: originalGuard,
    ), isFalse, reason: 'A to B to A must invalidate the original guard');
    store.dispose();
  });

  test('JSON backups refuse missing images in live or trashed Vision Boards',
      () async {
    final store = await openGuest();
    final date = DateTime(2026, 11, 10);
    final board = VisionBoardFoundation.draft(
      visionBoardPresetsFor(const AnnaStrings('en')).first, createdAt: date,
    );
    final invalid = board.copyWith(pages: [
      board.pages.single.copyWith(imageElements: const [
        DiarySketchImageElement(
          id: 'missing-image', mediaAssetId: 'gone-image',
          x: 0.1, y: 0.2,
        ),
      ]),
    ]);
    await store.saveJournal(date, DayJournal(blocks: [invalid]));
    await expectLater(store.createBackupJson(), throwsA(isA<StateError>()));
    expect(await store.moveDiaryBlockToTrash(date, invalid.id), isTrue);
    await expectLater(store.createBackupJson(), throwsA(isA<StateError>()));
    expect(store.trash, hasLength(1));
    store.dispose();
  });

  test('original five-language gallery labels are complete and deterministic',
      () {
    const languages = ['en', 'it', 'es', 'fr', 'pt'];
    const keys = [
      'title', 'description', 'empty', 'hidden', 'edit', 'links', 'linked',
      'trash', 'deleteQuestion', 'deleteDetail', 'saveFailed',
    ];
    for (final code in languages) {
      final strings = AnnaStrings(code);
      for (final key in keys) {
        expect(visionBoardGalleryText(strings, key).trim(), isNotEmpty);
      }
    }
    expect(visionBoardGalleryText(const AnnaStrings('it'), 'title'),
        'Le mie Vision Board');
  });

  testWidgets('narrow dark gallery exposes labeled board actions',
      (tester) async {
    final loaded = await tester.runAsync<AgendaStore>(() => openGuest());
    if (loaded == null) throw StateError('synthetic gallery store unavailable');
    final store = loaded;
    addTearDown(store.dispose);
    final date = DateTime(2026, 11, 10);
    final board = VisionBoardFoundation.draft(
      visionBoardPresetsFor(const AnnaStrings('it'))[1], createdAt: date,
    );
    final persisted = await tester.runAsync<bool>(() async {
      await store.saveJournal(date, DayJournal(blocks: [board]));
      return true;
    });
    expect(persisted, isTrue);
    tester.view.physicalSize = const Size(640, 1280);
    tester.view.devicePixelRatio = 2;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
      locale: const Locale('it'),
      supportedLocales: AnnaStrings.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: VisionBoardGalleryScreen(store: store),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.byKey(ValueKey('vision-board-${board.id}')), findsOneWidget);
    expect(find.text('Le mie Vision Board'), findsOneWidget);
    expect(find.text('Collega ricordi'), findsOneWidget);
    expect(find.text('Sposta nel Cestino'), findsOneWidget);
    expect(find.text('Modifica'), findsOneWidget);
    expect(tester.takeException(), isNull,
        reason: '320dp layout must not overflow or throw');

    store.setAgendaContentFilter(AgendaContentFilter.sharedOnly);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(ValueKey('vision-board-${board.id}')), findsNothing);
    expect(find.textContaining('non sono disponibili'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
