enum VisionBoardInsertAction { photo, text, arrow, draw }

part of '../../main.dart';

/// S12: a single freely navigable Vision Board scene, without a new database
/// or a coordinate/schema migration. Existing S11 normalized points stay at
/// the same visual locations inside the initial 640-unit board region.
/// Positions outside [0,1] are legal for Vision Board *only*.
abstract final class VisionBoardWorld {
  static const double unit = 640;
  static const double initialHalfExtent = 2048;
  static const double growth = 1024;
  static const double margin = 640;
  static const double minScale = 0.12;
  static const double maxScale = 8.0;

  static double origin(double halfExtent) => halfExtent - unit / 2;

  static Offset toScene(DiarySketchPoint point, double halfExtent) =>
      Offset(origin(halfExtent) + point.x * unit,
          origin(halfExtent) + point.y * unit);

  static DiarySketchPoint fromScene(Offset scene, double halfExtent) =>
      DiarySketchPoint(
        (scene.dx - origin(halfExtent)) / unit,
        (scene.dy - origin(halfExtent)) / unit,
      );

  static double requiredHalfExtent(Iterable<DiarySketchPage> pages) {
    var radius = 0.0;
    void include(double x, double y) {
      if (!x.isFinite || !y.isFinite) return;
      final px = (x - .5) * unit;
      final py = (y - .5) * unit;
      radius = max(radius, max(px.abs(), py.abs()));
    }
    for (final page in pages) {
      for (final stroke in page.strokes) {
        for (final point in stroke.points) {
          include(point.x, point.y);
        }
      }
      for (final label in page.textElements) {
        include(label.x, label.y);
        include(label.x + max(.1, label.text.length * label.fontSize / unit),
            label.y + label.fontSize * 2 / unit);
      }
      for (final photo in page.imageElements) {
        include(photo.x, photo.y);
        include(photo.x + photo.width, photo.y + photo.height);
      }
    }
    return max(initialHalfExtent,
        ((radius + margin) / growth).ceilToDouble() * growth);
  }

  static Matrix4 centeredCamera(Size viewport, double halfExtent) {
    final scale = min(
      1.0,
      min(viewport.width * .84 / unit, viewport.height * .84 / unit),
    ).clamp(minScale, 1.0);
    return Matrix4.identity()
      ..setEntry(0, 0, scale)
      ..setEntry(1, 1, scale)
      ..setTranslationRaw(
        viewport.width / 2 - halfExtent * scale,
        viewport.height / 2 - halfExtent * scale,
        0,
      );
  }

  static double viewportHalfExtent(
    TransformationController camera, Size viewport, double currentHalf,
  ) {
    var farthest = 0.0;
    for (final pixel in [
      Offset.zero, Offset(viewport.width, 0),
      Offset(0, viewport.height),
      Offset(viewport.width, viewport.height),
    ]) {
      final point = camera.toScene(pixel);
      farthest = max(farthest, max(
        (point.dx - currentHalf).abs(), (point.dy - currentHalf).abs(),
      ));
    }
    if (farthest <= currentHalf - margin / 2) return currentHalf;
    return max(currentHalf,
        ((farthest + margin) / growth).ceilToDouble() * growth);
  }

  static Offset arrowWing(Offset start, Offset tip, {bool left = true}) {
    final delta = tip - start;
    final length = delta.distance;
    if (length < .0001) return tip;
    final backwards = Offset(-delta.dx / length, -delta.dy / length);
    const angle = .48;
    final side = left ? 1.0 : -1.0;
    const wing = 23.0;
    return tip + Offset(
      (backwards.dx * cos(angle) - side * backwards.dy * sin(angle)) * wing,
      (backwards.dy * cos(angle) + side * backwards.dx * sin(angle)) * wing,
    );
  }

  static DiarySketchPoint insertAtCenter(
    TransformationController controller, Size viewport, double halfExtent,
  ) {
    if (viewport.width <= 0 || viewport.height <= 0) {
      return const DiarySketchPoint(.25, .25);
    }
    return fromScene(controller.toScene(
      Offset(viewport.width / 2, viewport.height / 2),
    ), halfExtent);
  }
}
