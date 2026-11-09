import 'dart:typed_data';

import 'package:agenda_per_anna/local_state_store.dart';
import 'package:agenda_per_anna/main.dart';
import 'package:agenda_per_anna/media_asset_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// S11-B source/widget evidence only; not browser/PWA/physical media QA.
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

  test('old sketch JSON remains an ordinary sketch without a migration', () {
    final oldBlock = DiaryBlock(
      id: 'legacy-sketch',
      type: DiaryBlockType.sketch,
      createdAt: DateTime(2025, 1, 2),
      pages: const [DiarySketchPage(id: 'old-page')],
    );
    expect(oldBlock.toJson().containsKey('creativeSubtype'), isFalse);
    final decoded = DiaryBlock.fromJson(oldBlock.toJson());
    expect(decoded.creativeSubtype, DiaryCreativeSubtype.sketch);
    expect(decoded.isPersonalVisionBoard, isFalse);
    expect(decoded.pages.single.id, 'old-page');

    final unknown = DiaryBlock.fromJson({
      ...oldBlock.toJson(),
      'creativeSubtype': 'future-unknown',
    });
    expect(unknown.isPersonalVisionBoard, isFalse);
    expect(unknown.creativeSubtype, DiaryCreativeSubtype.sketch);

    final unrelated = DiaryBlock.fromJson({
      ...oldBlock.toJson(),
      'type': 'note',
      'creativeSubtype': 'visionBoard',
    });
    expect(unrelated.isPersonalVisionBoard, isFalse);
  });

  test('S11-B original presets are bounded and localized in five languages', () {
    const languages = ['it', 'en', 'es', 'fr', 'pt'];
    const ids = ['blank', 'dreams', 'journeys', 'home', 'together', 'goals'];
    final baselines = visionBoardPresetsFor(const AnnaStrings('en'));
    expect(baselines.map((p) => p.id).toList(), ids);
    for (final code in languages) {
      final presets = visionBoardPresetsFor(AnnaStrings(code));
      expect(presets.map((p) => p.id).toList(), ids);
      expect(presets.every((p) =>
          p.title.trim().isNotEmpty && p.description.trim().isNotEmpty), isTrue);
      for (var i = 0; i < presets.length; i++) {
        final preset = presets[i];
        expect(preset.frames.every((frame) => frame.isValid), isTrue);
        expect(preset.frames.length, baselines[i].frames.length);
        final page = preset.createPage(pageId: 'preview-${preset.id}');
        expect(page.strokes.length, preset.frames.length);
        expect(page.textElements, isEmpty);
        expect(page.imageElements, isEmpty);
        for (final stroke in page.strokes) {
          expect(stroke.tool, DiarySketchTool.rectangle);
          expect(stroke.points, hasLength(2));
        }
      }
    }
    expect(
      visionBoardPresetsFor(const AnnaStrings('it'))
          .firstWhere((p) => p.id == 'dreams').title,
      'I miei sogni',
    );
  });

  test('board draft has explicit subtype; existing sketch contract is intact', () {
    final preset = visionBoardPresetsFor(const AnnaStrings('it'))[1];
    final draft = VisionBoardFoundation.draft(
      preset, createdAt: DateTime(2026, 11, 9, 16),
    );
    expect(draft.type, DiaryBlockType.sketch);
    expect(draft.isPersonalVisionBoard, isTrue);
    expect(draft.pages.single.strokes, hasLength(3));
    expect(draft.pages.single.imageElements, isEmpty);
    expect(draft.relatedBlockIds, isEmpty);
    expect(draft.personIds, isEmpty);
    expect(draft.toLocalJson()['creativeSubtype'], 'visionBoard');

    final decoded = DiaryBlock.fromJson(draft.toJson());
    expect(decoded.isPersonalVisionBoard, isTrue);
    expect(decoded.pages.single.strokes.length, 3);
    expect(decoded.copyWith(text: 'Changed').isPersonalVisionBoard, isTrue);
    expect(() => VisionBoardFoundation.draft(
      preset, createdAt: DateTime(2026), title: ' ',
    ), throwsFormatException);
  });

  test('draft is not persisted until the guarded user Save', () async {
    final store = AgendaStore();
    await store.load();
    await store.continueWithoutAccount();
    final day = DateTime(2026, 11, 9);
    final old = DiaryBlock(
      id: 'existing-note',
      type: DiaryBlockType.note,
      createdAt: day,
      text: 'Keep my existing text',
    );
    await store.saveJournal(
      day, DayJournal(beautiful: 'Keep my existing day', blocks: [old]),
    );
    final preset = visionBoardPresetsFor(const AnnaStrings('it'))[2];
    final draft = VisionBoardFoundation.draft(preset, createdAt: day);
    expect(store.journal(day).blocks, hasLength(1));

    final guard = Cap0160TagEditGuard(store);
    expect(await VisionBoardFoundation.saveDraft(
      store, day, draft, scopeGuard: guard,
    ), isTrue);
    final saved = store.journal(day);
    expect(saved.beautiful, 'Keep my existing day');
    expect(saved.blocks, hasLength(2));
    expect(saved.blocks.first.id, old.id);
    expect(saved.blocks.last.id, draft.id);
    expect(VisionBoardFoundation.personalBoards(store).single.block.id, draft.id);
    expect(await VisionBoardFoundation.saveDraft(
      store, day, draft, scopeGuard: guard,
    ), isFalse); // never overwrite or double-insert

    store.dispose();
    final reloaded = AgendaStore();
    await reloaded.load();
    await reloaded.continueWithoutAccount();
    final roundtrip = reloaded.journal(day).blocks.last;
    expect(roundtrip.isPersonalVisionBoard, isTrue);
    expect(roundtrip.pages.single.strokes, hasLength(3));
    expect(reloaded.journal(day).blocks.first.text, 'Keep my existing text');
    reloaded.dispose();
  });

  test('private gallery and write are blocked in shared-only scope', () async {
    final store = AgendaStore();
    await store.load();
    await store.continueWithoutAccount();
    final day = DateTime(2026, 11, 9);
    final draft = VisionBoardFoundation.draft(
      visionBoardPresetsFor(const AnnaStrings('en')).first,
      createdAt: day,
    );
    final guard = Cap0160TagEditGuard(store);
    store.agendaContentFilter = AgendaContentFilter.sharedOnly;
    expect(VisionBoardFoundation.personalBoards(store), isEmpty);
    expect(await VisionBoardFoundation.saveDraft(
      store, day, draft, scopeGuard: guard,
    ), isFalse);
    expect(store.journal(day).blocks, isEmpty);
    store.dispose();
  });

  test('stale A -> B -> A editor guard cannot save into a new scope', () async {
    final store = AgendaStore();
    await store.load();
    await store.continueWithoutAccount();
    final guard = Cap0160TagEditGuard(store);
    final oldEpoch = store.accountScopeEpoch;
    await store.activateCloudAccount('synthetic-board-B');
    await store.activateCloudAccount(null);
    expect(store.accountScopeEpoch, oldEpoch + 2);
    final day = DateTime(2026, 11, 9);
    final draft = VisionBoardFoundation.draft(
      visionBoardPresetsFor(const AnnaStrings('en'))[1],
      createdAt: day,
    );
    expect(await VisionBoardFoundation.saveDraft(
      store, day, draft, scopeGuard: guard,
    ), isFalse);
    expect(store.journal(day).blocks, isEmpty);
    store.dispose();
  });

  test('duplicate uses new IDs, keeps asset references, no private links', () {
    final original = DiaryBlock(
      id: 'original-board',
      type: DiaryBlockType.sketch,
      creativeSubtype: DiaryCreativeSubtype.visionBoard,
      createdAt: DateTime(2026, 11, 7),
      text: 'My own words',
      tags: const ['inspiration'],
      personIds: const ['personal-person'],
      relatedBlockIds: const ['personal-memory'],
      pages: const [
        DiarySketchPage(
          id: 'page-old',
          textElements: [
            DiarySketchTextElement(
              id: 'text-old', text: 'My words', x: 0.1, y: 0.2,
            ),
          ],
          imageElements: [
            DiarySketchImageElement(
              id: 'image-old', mediaAssetId: 'media-owned-by-store',
              x: 0.1, y: 0.3,
            ),
          ],
        ),
      ],
    );
    final copy = VisionBoardFoundation.duplicate(
      original, createdAt: DateTime(2026, 11, 9),
    );
    expect(copy.id, isNot(original.id));
    expect(copy.isPersonalVisionBoard, isTrue);
    expect(copy.text, original.text);
    expect(copy.pages.single.id, isNot(original.pages.single.id));
    expect(copy.pages.single.imageElements.single.id,
        isNot(original.pages.single.imageElements.single.id));
    expect(copy.pages.single.imageElements.single.mediaAssetId,
        'media-owned-by-store');
    expect(copy.pages.single.textElements.single.id,
        isNot(original.pages.single.textElements.single.id));
    expect(copy.personIds, isEmpty);
    expect(copy.relatedBlockIds, isEmpty);
    expect(original.pages.single.imageElements.single.id, 'image-old');
  });

  test('save rejects missing image without persisting an incomplete board',
      () async {
    final store = AgendaStore();
    await store.load();
    await store.continueWithoutAccount();
    final day = DateTime(2026, 11, 9);
    final base = VisionBoardFoundation.draft(
      visionBoardPresetsFor(const AnnaStrings('en'))[0],
      createdAt: day,
    );
    final page = base.pages.single.copyWith(imageElements: const [
      DiarySketchImageElement(
        id: 'missing-photo', mediaAssetId: 'missing-asset',
        x: 0.1, y: 0.2,
      ),
    ]);
    final bad = base.copyWith(pages: [page]);
    expect(await VisionBoardFoundation.saveDraft(
      store, day, bad, scopeGuard: Cap0160TagEditGuard(store),
    ), isFalse);
    expect(store.journal(day).blocks, isEmpty);

    final bytes = Uint8List.fromList([1, 2, 3, 4]);
    final storedId = await MediaAssetStore.instance.put(bytes);
    final valid = bad.copyWith(
      pages: [
        page.copyWith(imageElements: [
          DiarySketchImageElement(
            id: 'owned-photo', mediaAssetId: storedId,
            x: 0.1, y: 0.2,
          ),
        ]),
      ],
    );
    expect(await VisionBoardFoundation.saveDraft(
      store, day, valid, scopeGuard: Cap0160TagEditGuard(store),
    ), isTrue);
    expect(store.journal(day).blocks.single.pages.single.imageElements.single
        .mediaAssetId, storedId);
    store.dispose();
  });

  testWidgets('picker renders original previews at 320dp and saves nothing',
      (tester) async {
    VisionBoardPreset? selection;
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(640, 1280);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('it'),
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () async =>
                  selection = await showVisionBoardPresetPicker(context),
              child: const Text('Open presets'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Open presets'));
    await tester.pumpAndSettle();
    expect(find.text('Scegli una Vision Board'), findsOneWidget);
    expect(find.text('I miei sogni'), findsOneWidget);
    await tester.tap(find.text('I miei sogni'));
    await tester.pumpAndSettle();
    expect(selection?.id, 'dreams');
    expect(tester.takeException(), isNull);
  });
}
