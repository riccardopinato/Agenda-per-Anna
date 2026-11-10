import 'dart:typed_data';

import 'package:agenda_per_anna/local_state_store.dart';
import 'package:agenda_per_anna/main.dart';
import 'package:agenda_per_anna/media_asset_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// S13 synthetic release regressions. Never treat these widget/store tests as
/// physical PWA, touch, assistive-technology or performance certification.
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

  test('30 scattered photos, text and arrow survive edit and ZIP recovery',
      () async {
    final store = await openGuest();
    final day = DateTime(2026, 11, 10);
    final original = VisionBoardFoundation.draft(
      visionBoardPresetsFor(const AnnaStrings('it')).first,
      createdAt: day,
    );
    final bytesById = <String, Uint8List>{};
    final photos = <DiarySketchImageElement>[];
    for (var i = 0; i < 30; i++) {
      final bytes = Uint8List.fromList(List<int>.generate(
        96, (j) => (i * 17 + j * 11) % 256,
      ));
      final id = await MediaAssetStore.instance.put(bytes);
      bytesById[id] = bytes;
      photos.add(DiarySketchImageElement(
        id: 'photo-$i',
        mediaAssetId: id,
        x: (i % 6 - 3) * 3.5,
        y: (i ~/ 6 - 2) * 2.75,
        width: .65,
        height: .42,
      ));
    }
    expect(bytesById, hasLength(30),
        reason: 'the stress fixture must use 30 distinct media assets');

    final page = original.pages.single.copyWith(
      imageElements: photos,
      textElements: const [
        DiarySketchTextElement(
          id: 's13-text', text: 'La mia visione',
          x: -9.4, y: 6.1,
        ),
      ],
      strokes: const [
        DiarySketchStroke(
          tool: DiarySketchTool.arrow,
          colorValue: 0xffa23a63,
          width: 3,
          points: [
            DiarySketchPoint(-10, -5),
            DiarySketchPoint(8, 7),
          ],
        ),
      ],
    );
    final board = original.copyWith(pages: [page]);
    final guard = Cap0160TagEditGuard(store);
    expect(await VisionBoardFoundation.saveDraft(
      store, day, board, scopeGuard: guard,
    ), isTrue);
    final source = VisionBoardFoundation.personalBoards(store).single.block;
    expect(source.pages.single.imageElements, hasLength(30));
    expect(source.pages.single.strokes.single.tool, DiarySketchTool.arrow);
    expect(VisionBoardWorld.requiredHalfExtent(source.pages),
        greaterThan(VisionBoardWorld.initialHalfExtent));

    final edited = source.pages.single.copyWith(imageElements: [
      for (final photo in photos)
        photo.copyWith(x: photo.x + .4, y: photo.y - .2),
    ]);
    expect(await saveExistingPrivateVisionBoard(
      store, day, source, [edited], scopeGuard: guard,
    ), isTrue);
    final saved = VisionBoardFoundation.personalBoards(store).single.block;
    expect(saved.id, board.id);
    expect(saved.pages.single.imageElements, hasLength(30));
    expect(saved.pages.single.imageElements.first.x,
        closeTo(photos.first.x + .4, .000001));
    expect(saved.pages.single.textElements.single.text, 'La mia visione');

    final zip = await store.createBackupZip();
    expect(zip, isNotEmpty);
    store.dispose();
    await MediaAssetStore.instance.resetForTesting();

    final imported = AgendaStore();
    await imported.restoreBackupZip(zip, merge: false);
    final restored = imported.journal(day).blocks
        .singleWhere((b) => b.isPersonalVisionBoard);
    expect(restored.id, board.id);
    expect(restored.pages.single.imageElements, hasLength(30));
    expect(restored.pages.single.strokes.single.tool, DiarySketchTool.arrow);
    expect(restored.pages.single.textElements.single.x, -9.4);
    for (final photo in restored.pages.single.imageElements) {
      expect(await MediaAssetStore.instance.read(photo.mediaAssetId),
          orderedEquals(bytesById[photo.mediaAssetId]!));
    }
    imported.dispose();
  });

  test('repeated pan, low zoom and growth preserve logical insertion points',
      () {
    const viewport = Size(360, 640);
    const center = Offset(180, 320);
    final controller = TransformationController(
      VisionBoardWorld.centeredCamera(
        viewport, VisionBoardWorld.initialHalfExtent,
      ),
    );
    addTearDown(controller.dispose);
    var half = VisionBoardWorld.initialHalfExtent;

    // Explicitly exercise a zoom below 1.0, where getMaxScaleOnAxis
    // accidentally reports the Z=1 axis rather than the 2D camera scale.
    final zoomed = controller.value.clone();
    zoomed.setEntry(0, 0, .20);
    zoomed.setEntry(1, 1, .20);
    zoomed.setTranslationRaw(
      center.dx - half * .20, center.dy - half * .20, 0,
    );
    controller.value = zoomed;
    expect(VisionBoardWorld.cameraScale(controller.value),
        closeTo(.20, .000001));

    for (var i = 0; i < 8; i++) {
      final moved = controller.value.clone();
      moved.storage[12] += i.isEven ? 1250 : -2200;
      moved.storage[13] += i.isEven ? -1650 : 1350;
      controller.value = moved;

      final before = VisionBoardWorld.insertAtCenter(
        controller, viewport, half,
      );
      final nextHalf = VisionBoardWorld.viewportHalfExtent(
        controller, viewport, half,
      );
      if (nextHalf > half) {
        controller.value = VisionBoardWorld.cameraAfterGrowth(
          controller.value, nextHalf - half,
        );
        half = nextHalf;
      }
      final after = VisionBoardWorld.insertAtCenter(
        controller, viewport, half,
      );
      expect(after.x, closeTo(before.x, .000001));
      expect(after.y, closeTo(before.y, .000001));
      expect(after.x.isFinite && after.y.isFinite, isTrue);
    }
    expect(half, greaterThan(VisionBoardWorld.initialHalfExtent));
  });

  testWidgets('320dp board keeps add-content reachable without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(640, 1280);
    tester.view.devicePixelRatio = 2;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const MaterialApp(
      locale: Locale('it'),
      supportedLocales: AnnaStrings.supportedLocales,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: DiarySketchbookScreen(
        visionBoardMode: true,
        initialPages: [
          DiarySketchPage(
            id: 's13-narrow',
            strokes: [
              DiarySketchStroke(
                tool: DiarySketchTool.arrow,
                colorValue: 0xff000000,
                width: 2,
                points: [
                  DiarySketchPoint(-9, 5),
                  DiarySketchPoint(8, -4),
                ],
              ),
            ],
          ),
        ],
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final add = find.byKey(const ValueKey('vision-board-add-content'));
    expect(add, findsOneWidget);
    expect(tester.getTopLeft(add).dx, greaterThanOrEqualTo(0));
    expect(tester.getBottomRight(add).dx, lessThanOrEqualTo(320));
    expect(find.byIcon(Icons.add_box_outlined), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(add);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 280));
    expect(find.text('Aggiungi alla tela'), findsWidgets);
    expect(find.text('Foto'), findsWidgets);
    expect(find.text('Freccia'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
