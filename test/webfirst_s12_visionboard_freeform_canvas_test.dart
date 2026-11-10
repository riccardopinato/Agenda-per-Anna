import 'package:agenda_per_anna/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// The S12 canvas is source-only until manual two-PWA touch and restore QA.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('old S11 normalized coordinates retain their original world position',
      () {
    const olderPage = DiarySketchPage(
      id: 'legacy',
      strokes: const [
        DiarySketchStroke(
          tool: DiarySketchTool.rectangle,
          colorValue: 0xff000000,
          width: 2,
          points: [
            DiarySketchPoint(.08, .1), DiarySketchPoint(.46, .46),
          ],
        ),
      ],
    );
    const half = VisionBoardWorld.initialHalfExtent;
    final a = VisionBoardWorld.toScene(
      olderPage.strokes.first.points.first, half);
    expect(a.dx, closeTo(half - 320 + .08 * 640, .00001));
    expect(a.dy, closeTo(half - 320 + .10 * 640, .00001));
    final back = VisionBoardWorld.fromScene(a, half);
    expect(back.x, closeTo(.08, .00001));
    expect(back.y, closeTo(.10, .00001));
    expect(VisionBoardWorld.requiredHalfExtent([olderPage]),
        VisionBoardWorld.initialHalfExtent);
  });

  test('freeform coordinates may exceed old page bounds and survive JSON',
      () {
    const page = DiarySketchPage(
      id: 'freeform',
      strokes: const [
        DiarySketchStroke(
          tool: DiarySketchTool.arrow,
          colorValue: 0xffaa00aa,
          width: 4,
          points: [
            DiarySketchPoint(-7.2, 3.25),
            DiarySketchPoint(8.1, 5.5),
          ],
        ),
      ],
      textElements: const [
        DiarySketchTextElement(
          id: 'text-far', text: 'Freedom', x: -6.7, y: 6.2,
        ),
      ],
      imageElements: const [
        DiarySketchImageElement(
          id: 'photo-far', mediaAssetId: 'synthetic',
          x: 9.5, y: -8.2, width: .4, height: .5,
        ),
      ],
    );
    final restored = DiarySketchPage.fromJson(page.toLocalJson());
    expect(restored.strokes.single.tool, DiarySketchTool.arrow);
    expect(restored.strokes.single.points.first.x, -7.2);
    expect(restored.imageElements.single.x, 9.5);
    expect(restored.imageElements.single.y, -8.2);
    expect(restored.textElements.single.x, -6.7);
    final half = VisionBoardWorld.requiredHalfExtent([restored]);
    expect(half, greaterThan(VisionBoardWorld.initialHalfExtent));
    final scene = VisionBoardWorld.toScene(
      restored.strokes.single.points.last, half,
    );
    final roundtrip = VisionBoardWorld.fromScene(scene, half);
    expect(roundtrip.x, closeTo(8.1, .000001));
    expect(roundtrip.y, closeTo(5.5, .000001));
  });

  test('world pan expansion retains the same model coordinates', () {
    final camera = TransformationController(
      VisionBoardWorld.centeredCamera(
        const Size(320, 480), VisionBoardWorld.initialHalfExtent,
      ),
    );
    addTearDown(camera.dispose);
    final before = VisionBoardWorld.fromScene(
      camera.toScene(const Offset(160, 240)),
      VisionBoardWorld.initialHalfExtent,
    );
    expect(before.x, closeTo(.5, .000001));
    expect(before.y, closeTo(.5, .000001));
    final next = VisionBoardWorld.viewportHalfExtent(
      camera, const Size(320, 480), VisionBoardWorld.initialHalfExtent,
    );
    expect(next, VisionBoardWorld.initialHalfExtent);
    // Pan far to a new world area, then dynamically grow the viewport.
    final moved = camera.value.clone();
    moved.storage[12] += 4900;
    camera.value = moved;
    final expanded = VisionBoardWorld.viewportHalfExtent(
      camera, const Size(320, 480), VisionBoardWorld.initialHalfExtent,
    );
    expect(expanded, greaterThan(VisionBoardWorld.initialHalfExtent));
    final delta = expanded - VisionBoardWorld.initialHalfExtent;
    final shifted = camera.value.clone();
    shifted.storage[12] -= delta * shifted.getMaxScaleOnAxis();
    shifted.storage[13] -= delta * shifted.getMaxScaleOnAxis();
    camera.value = shifted;
    final world = VisionBoardWorld.fromScene(
      camera.toScene(const Offset(160, 240)), expanded,
    );
    final preservedWorld = VisionBoardWorld.fromScene(
      const Offset(0, 0),
      VisionBoardWorld.initialHalfExtent,
    );
    expect(world.x.isFinite, isTrue);
    expect(world.y.isFinite, isTrue);
    expect(preservedWorld.x.isFinite, isTrue);
  });

  test('arrow wings point backward, and remain finite', () {
    final a = VisionBoardWorld.arrowWing(
      Offset.zero, const Offset(100, 0),
    );
    final b = VisionBoardWorld.arrowWing(
      Offset.zero, const Offset(100, 0), left: false,
    );
    expect(a.dx, lessThan(100));
    expect(b.dx, lessThan(100));
    expect(a.dy, closeTo(-b.dy, .001));
    expect(VisionBoardWorld.arrowWing(
      Offset.zero, Offset.zero), Offset.zero);
  });

  testWidgets('Vision Board shows world viewer and add-content instead of page+',
      (tester) async {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(640, 1280);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
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
        initialPages: [DiarySketchPage(id: 'freeform-s12')],
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('vision-board-add-content')),
        findsOneWidget);
    expect(find.byIcon(Icons.add_box_outlined), findsNothing);
    final worldViewer = tester.widget<InteractiveViewer>(
        find.byType(InteractiveViewer));
    expect(worldViewer.constrained, isFalse);
    expect(worldViewer.scaleEnabled, isTrue);
    expect(worldViewer.minScale, lessThan(.5));
    expect(find.byTooltip('Centra la tela'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('vision-board-add-content')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 280));
    expect(find.text('Aggiungi alla tela'), findsWidgets);
    expect(find.text('Freccia'), findsWidgets);
    expect(find.text('Foto'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('legacy sketch still displays its familiar add-page button',
      (tester) async {
    tester.view.physicalSize = const Size(640, 1280);
    tester.view.devicePixelRatio = 2;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(const MaterialApp(
      locale: Locale('it'),
      home: DiarySketchbookScreen(
        initialPages: [DiarySketchPage(id: 'older-sketch')],
      ),
    ));
    await tester.pump();
    expect(find.byKey(const ValueKey('vision-board-add-content')),
        findsNothing);
    expect(find.byIcon(Icons.add_box_outlined), findsOneWidget);
  });
}
