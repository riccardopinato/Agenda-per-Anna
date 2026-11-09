import 'package:agenda_per_anna/main.dart';
import 'package:agenda_per_anna/local_state_store.dart';
import 'package:agenda_per_anna/media_asset_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Synthetic S11-C checks. Does not certify installed Web/PWA, media export
/// from a real phone, shared sync, actual touch accessibility or Store.
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

  test('S11-B frames are actually used to arrange editable photos', () {
    final preset = visionBoardPresetsFor(const AnnaStrings('it'))
        .firstWhere((item) => item.id == 'dreams');
    final page = preset.createPage(pageId: 'original').copyWith(
      imageElements: const [
        DiarySketchImageElement(
          id: 'a', mediaAssetId: 'media-a', x: 0.01, y: 0.01,
        ),
        DiarySketchImageElement(
          id: 'b', mediaAssetId: 'media-b', x: 0.02, y: 0.02,
        ),
      ],
    );
    final result = VisionBoardCollage.arrange(
      page, VisionBoardCollageStyle.template,
    );
    expect(result.id, page.id);
    expect(result.imageElements.map((e) => e.mediaAssetId),
        ['media-a', 'media-b']);
    expect(result.imageElements.map((e) => e.id), ['a', 'b']);
    expect(result.imageElements.first.x, closeTo(0.08, 0.000001));
    expect(result.imageElements.first.width, closeTo(0.38, 0.000001));
    expect(result.imageElements[1].x, closeTo(0.54, 0.000001));
    expect(result.strokes.length, page.strokes.length);
    expect(page.imageElements.first.x, 0.01); // no mutation of original
  });

  test('grid and cascade keep every image and normalized bounds', () {
    final page = DiarySketchPage(
      id: 'collage-page',
      imageElements: [
        for (var i = 0; i < 9; i++)
          DiarySketchImageElement(
            id: 'image-$i', mediaAssetId: 'asset-$i',
            x: 0.01, y: 0.01,
          ),
      ],
    );
    for (final style in VisionBoardCollageStyle.values) {
      final arranged = VisionBoardCollage.arrange(page, style);
      expect(arranged.imageElements, hasLength(9));
      for (var i = 0; i < 9; i++) {
        final image = arranged.imageElements[i];
        expect(image.id, 'image-$i');
        expect(image.mediaAssetId, 'asset-$i');
        expect(image.x, greaterThanOrEqualTo(0));
        expect(image.y, greaterThanOrEqualTo(0));
        expect(image.x + image.width, lessThanOrEqualTo(1.000001));
        expect(image.y + image.height, lessThanOrEqualTo(1.000001));
      }
    }
    expect(VisionBoardCollage.arrange(
        const DiarySketchPage(id: 'empty'),
        VisionBoardCollageStyle.grid).imageElements, isEmpty);
    expect(page.imageElements.first.x, 0.01);
  });

  test('guarded editor update preserves identity, metadata and journal', () async {
    final store = AgendaStore();
    await store.load();
    await store.continueWithoutAccount();
    final day = DateTime(2026, 11, 9);
    final oldNote = DiaryBlock(
      id: 'existing-note', type: DiaryBlockType.note,
      createdAt: day, text: 'No data lost',
    );
    await store.saveJournal(
      day, DayJournal(beautiful: 'Original', blocks: [oldNote]),
    );
    final draft = VisionBoardFoundation.draft(
      visionBoardPresetsFor(const AnnaStrings('en'))[1],
      createdAt: day,
    );
    final guard = Cap0160TagEditGuard(store);
    expect(await VisionBoardFoundation.saveDraft(
      store, day, draft, scopeGuard: guard,
    ), isTrue);
    final source = store.journal(day).blocks.last;
    final editedPages = [
      source.pages.first.copyWith(textElements: const [
        DiarySketchTextElement(
          id: 'new-text', text: 'My goals', x: 0.1, y: 0.1,
        ),
      ]),
    ];
    expect(await saveExistingPrivateVisionBoard(
      store, day, source, editedPages, scopeGuard: guard,
    ), isTrue);
    final updated = store.journal(day).blocks.last;
    expect(updated.id, source.id);
    expect(updated.isPersonalVisionBoard, isTrue);
    expect(updated.pages.single.textElements.single.text, 'My goals');
    expect(store.journal(day).blocks.first.id, oldNote.id);
    expect(store.journal(day).beautiful, 'Original');
    // Stale references must not overwrite the newer version in this account.
    expect(await saveExistingPrivateVisionBoard(
      store, day, source, editedPages, scopeGuard: guard,
    ), isFalse);
    store.dispose();
  });

  test('editor write rejects A→B→A and shared-only transitions', () async {
    final store = AgendaStore();
    await store.load();
    await store.continueWithoutAccount();
    final day = DateTime(2026, 11, 9);
    final draft = VisionBoardFoundation.draft(
      visionBoardPresetsFor(const AnnaStrings('it'))[0],
      createdAt: day,
    );
    expect(await VisionBoardFoundation.saveDraft(
      store, day, draft, scopeGuard: Cap0160TagEditGuard(store),
    ), isTrue);
    final source = store.journal(day).blocks.single;
    final originalGuard = Cap0160TagEditGuard(store);
    await store.activateCloudAccount('test-board-account-B');
    await store.activateCloudAccount(null);
    expect(await saveExistingPrivateVisionBoard(
      store, day, source, source.pages, scopeGuard: originalGuard,
    ), isFalse);
    final fresh = store.journal(day).blocks.single;
    store.agendaContentFilter = AgendaContentFilter.sharedOnly;
    expect(await saveExistingPrivateVisionBoard(
      store, day, fresh, fresh.pages,
      scopeGuard: Cap0160TagEditGuard(store),
    ), isFalse);
    store.agendaContentFilter = AgendaContentFilter.all;
    expect(store.journal(day).blocks.single.pages, hasLength(1));
    store.dispose();
  });

  test('board edit rejects missing media and an archived board', () async {
    final store = AgendaStore();
    await store.load();
    await store.continueWithoutAccount();
    final day = DateTime(2026, 11, 9);
    final draft = VisionBoardFoundation.draft(
      visionBoardPresetsFor(const AnnaStrings('en'))[0],
      createdAt: day,
    );
    expect(await VisionBoardFoundation.saveDraft(
      store, day, draft, scopeGuard: Cap0160TagEditGuard(store),
    ), isTrue);
    final source = store.journal(day).blocks.single;
    final missingPage = source.pages.single.copyWith(imageElements: const [
      DiarySketchImageElement(
        id: 'lost', mediaAssetId: 'nonexistent', x: 0.1, y: 0.1,
      ),
    ]);
    expect(await saveExistingPrivateVisionBoard(
      store, day, source, [missingPage],
      scopeGuard: Cap0160TagEditGuard(store),
    ), isFalse);
    expect(store.journal(day).blocks.single.pages.single.imageElements, isEmpty);
    await store.saveJournal(
      day, DayJournal(blocks: [source.copyWith(archived: true)]),
    );
    expect(await saveExistingPrivateVisionBoard(
      store, day, source, source.pages,
      scopeGuard: Cap0160TagEditGuard(store),
    ), isFalse);
    store.dispose();
  });

  testWidgets('Vision Board editor confirms discard and retains draft on failed Save',
      (tester) async {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(640, 1280);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });
    var canSave = false;
    var attempts = 0;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('it'),
      supportedLocales: AnnaStrings.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(child: ElevatedButton(
            onPressed: () => Navigator.push<List<DiarySketchPage>>(
              context, MaterialPageRoute(
                builder: (_) => DiarySketchbookScreen(
                  initialPages: const [DiarySketchPage(id: 'test-blank')],
                  visionBoardMode: true,
                  onSavePages: (pages) async {
                    attempts++;
                    expect(pages, isNotEmpty);
                    return canSave;
                  },
                ),
              ),
            ),
            child: const Text('Open board editor'),
          )),
        ),
      ),
    ));
    await tester.tap(find.text('Open board editor'));
    await tester.pumpAndSettle();
    expect(find.text('La mia Vision Board'), findsOneWidget);
    expect(find.byKey(const ValueKey('vision-board-collage-menu')),
        findsOneWidget);

    // Make a real edit using the standard Sketchbook text tool.
    await tester.tap(find.byIcon(Icons.text_fields_outlined).first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Testo personale');
    await tester.tap(find.byType(FilledButton).last);
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Scartare le modifiche?'), findsOneWidget);
    await tester.tap(find.text('Continua a modificare'));
    await tester.pumpAndSettle();
    expect(find.text('La mia Vision Board'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();
    expect(attempts, 1);
    expect(find.text('La mia Vision Board'), findsOneWidget);
    expect(find.textContaining('bozza è ancora aperta'), findsWidgets);

    canSave = true;
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.text('Open board editor'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
