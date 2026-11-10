part of '../../main.dart';

enum VisionBoardInsertAction { photo, text, arrow, draw }

/// S12: a single freely navigable Vision Board scene, without a new database
/// or a coordinate/schema migration. Existing S11 normalized points stay at
/// the same visual locations inside the initial 640-unit board region.
/// Positions outside [0,1] are legal for Vision Board *only*.
abstract final class VisionBoardWorld {
  // Original Sketchbook pages were rendered at aspectRatio 3 / 4.
  // Keep separate world pixel bases: older 0..1 drawings, photos and
  // preset rectangles must not be squashed to a square on reopen.
  static const double unit = 640;
  static const double unitY = unit * 4 / 3;
  static const double initialHalfExtent = 2048;
  static const double growth = 1024;
  static const double margin = 640;
  static const double minScale = 0.12;
  static const double maxScale = 8.0;

  static double origin(double halfExtent) => halfExtent - unit / 2;
  static double originY(double halfExtent) => halfExtent - unitY / 2;

  static Offset toScene(DiarySketchPoint point, double halfExtent) =>
      Offset(origin(halfExtent) + point.x * unit,
          originY(halfExtent) + point.y * unitY);

  static DiarySketchPoint fromScene(Offset scene, double halfExtent) =>
      DiarySketchPoint(
        (scene.dx - origin(halfExtent)) / unit,
        (scene.dy - originY(halfExtent)) / unitY,
      );

  /// Fits all board elements in Ricordi and diary thumbnails. Ordinary
  /// Sketchbook previews remain a fixed 3:4 sheet.
  static Rect contentBounds(DiarySketchPage page) {
    var minX = double.infinity;
    var minY = double.infinity;
    var maxX = double.negativeInfinity;
    var maxY = double.negativeInfinity;
    void include(double x, double y) {
      if (!x.isFinite || !y.isFinite) return;
      minX = min(minX, x);
      minY = min(minY, y);
      maxX = max(maxX, x);
      maxY = max(maxY, y);
    }

    for (final stroke in page.strokes) {
      for (final point in stroke.points) {
        include(point.x, point.y);
      }
    }
    for (final image in page.imageElements) {
      include(image.x, image.y);
      include(image.x + image.width, image.y + image.height);
    }
    for (final label in page.textElements) {
      include(label.x, label.y);
      include(label.x + label.text.length * label.fontSize * .55 / unit,
          label.y + label.fontSize * 1.6 / unitY);
    }
    if (!minX.isFinite || !minY.isFinite) {
      return const Rect.fromLTWH(0, 0, 1, 1);
    }
    return Rect.fromCenter(
      center: Offset((minX + maxX) / 2, (minY + maxY) / 2),
      width: max(.52, maxX - minX) * 1.18,
      height: max(.60, maxY - minY) * 1.18,
    );
  }

  static double requiredHalfExtent(Iterable<DiarySketchPage> pages) {
    var radius = 0.0;
    void include(double x, double y) {
      if (!x.isFinite || !y.isFinite) return;
      final px = (x - .5) * unit;
      final py = (y - .5) * unitY;
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
            label.y + label.fontSize * 2 / unitY);
      }
      for (final photo in page.imageElements) {
        include(photo.x, photo.y);
        include(photo.x + photo.width, photo.y + photo.height);
      }
    }
    return max(initialHalfExtent,
        ((radius + margin) / growth).ceilToDouble() * growth);
  }

  /// Matrix4's getMaxScaleOnAxis includes Z=1.0 and is not a reliable
  /// zoom factor for a 2D board below 100%. Use its X/Y 2D basis.
  static double cameraScale(Matrix4 matrix) =>
      sqrt(matrix.entry(0, 0) * matrix.entry(0, 0) +
          matrix.entry(1, 0) * matrix.entry(1, 0));

  /// Growth shifts scene origin by [delta] on both axes. Preserve the same
  /// logical world point at the viewport center even when zoomed below 1x.
  /// Matrix4.getMaxScaleOnAxis includes its Z axis and is unsafe here.
  static Matrix4 cameraAfterGrowth(Matrix4 current, double delta) {
    final next = current.clone();
    final scale = cameraScale(next);
    next.storage[12] -= delta * scale;
    next.storage[13] -= delta * scale;
    return next;
  }

  static Matrix4 centeredCamera(Size viewport, double halfExtent) {
    final scale = min(
      1.0,
      min(viewport.width * .84 / unit, viewport.height * .84 / unitY),
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
