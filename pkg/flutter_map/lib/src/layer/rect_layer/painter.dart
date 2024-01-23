part of 'rect_layer.dart';

/// [CustomPainter] for [Polygon]s.
class _RectPainter extends CustomPainter {
  /// Reference to the list of [Polyline]s.
  final List<PointModel> points;

  /// Reference to the [MapCamera].
  final MapCamera camera;
  final double minimumHitbox;

  /// Create a new [_RectPainter] instance
  _RectPainter({
    required this.points,
    required this.camera,
    required this.minimumHitbox,
  });

  Offset getOffset(Offset origin, LatLng point) {
    // Critically create as little garbage as possible. This is called on every frame.
    final projected = camera.project(point);
    return Offset(projected.x - origin.dx, projected.y - origin.dy);
  }

  // @override
  // bool? hitTest(Offset position) {
  //   if (hitNotifier == null) return null;

  //   _hits.clear();

  //   final origin =
  //       camera.project(camera.center).toOffset() - camera.size.toOffset() / 2;

  //   for (final polyline in polylines.reversed) {
  //     if (polyline.hitValue == null) continue;

  //     // TODO: For efficiency we'd ideally filter by bounding box here. However
  //     // we'd need to compute an extended bounding box that accounts account for
  //     // the stroke width.
  //     // if (!p.boundingBox.contains(touch)) {
  //     //   continue;
  //     // }

  //     final offsets = getOffsets(origin, polyline.points);
  //     final strokeWidth = polyline.useStrokeWidthInMeter
  //         ? _metersToStrokeWidth(
  //             origin,
  //             polyline.points.first,
  //             offsets.first,
  //             polyline.strokeWidth,
  //           )
  //         : polyline.strokeWidth;
  //     final hittableDistance = math.max(
  //       strokeWidth / 2 + polyline.borderStrokeWidth / 2,
  //       minimumHitbox,
  //     );

  //     for (int i = 0; i < offsets.length - 1; i++) {
  //       final o1 = offsets[i];
  //       final o2 = offsets[i + 1];

  //       final distance = math.sqrt(
  //         getSqSegDist(
  //           position.dx,
  //           position.dy,
  //           o1.dx,
  //           o1.dy,
  //           o2.dx,
  //           o2.dy,
  //         ),
  //       );

  //       if (distance < hittableDistance) {
  //         _hits.add(polyline.hitValue!);
  //         break;
  //       }
  //     }
  //   }

  //   if (_hits.isEmpty) {
  //     hitNotifier!.value = null;
  //     return false;
  //   }

  //   hitNotifier!.value = LayerHitResult(
  //     hitValues: _hits,
  //     point: camera.pointToLatLng(math.Point(position.dx, position.dy)),
  //   );
  //   return true;
  // }

  Rect getRect(Offset offset, {double? width, double? height}) => Rect.fromLTWH(offset.dx - 70 / 2, offset.dy - 60 / 2, width ?? 70, height ?? 61);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    Rect? outRect;
    var path = ui.Path();
    var borderPath = ui.Path();
    // var filterPath = ui.Path();
    var paint = Paint();
    var needsLayerSaving = false;

    Paint? borderPaint;
    // Paint? filterPaint;
    int? lastHash;

    void drawPaths() {
      // final hasBorder = borderPaint != null && filterPaint != null;
      final hasBorder = borderPaint != null;
      if (hasBorder) {
        if (needsLayerSaving) {
          canvas.saveLayer(rect, Paint());
        }

        canvas.drawPath(borderPath, borderPaint!);
        borderPath = ui.Path();
        borderPaint = null;

        // if (needsLayerSaving) {
        //   canvas.drawPath(filterPath, filterPaint!);
        //   filterPath = ui.Path();
        //   filterPaint = null;

        //   canvas.restore();
        // }
      }
      canvas.drawPath(path, paint);
      path = ui.Path();
      paint = Paint();
    }

    final origin = camera.project(camera.center).toOffset() - camera.size.toOffset() / 2;

    for (final point in points) {
      final offset = getOffset(origin, point.point!);
      int nextIndex = points.indexOf(point) + 1;
      if (nextIndex < points.length) {
        double diff = double.parse((points[nextIndex].point!.longitude - point.point!.longitude).toStringAsFixed(4));
        print('double diff = longitude1 ${points[nextIndex].point!.longitude} - leng2 ${point.point!.longitude} = $diff;');

        if (diff == 0.013) {
          outRect = getRect(offset, width: 75);
        }
      }

      final hash = point.renderHashCode;
      if (needsLayerSaving || (lastHash != null && lastHash != hash)) {
        drawPaths();
      }
      lastHash = hash;
      needsLayerSaving = point.color.opacity < 1.0 || (point.gradientColors?.any((c) => c.opacity < 1.0) ?? false);

      // late final double strokeWidth;
      // if (point.useStrokeWidthInMeter) {
      //   strokeWidth = _metersToStrokeWidth(
      //     origin,
      //     point.point!,
      //     offset,
      //     point.strokeWidth,
      //   );
      // } else {
      //   strokeWidth = point.strokeWidth;
      // }

      final isDotted = point.isDotted;
      paint = Paint()
        ..strokeWidth = 1
        ..strokeCap = point.strokeCap
        ..strokeJoin = point.strokeJoin
        ..style = isDotted ? PaintingStyle.fill : PaintingStyle.stroke
        ..blendMode = BlendMode.srcOver;

      if (point.gradientColors == null) {
        paint.color = point.color;
      }

      if (point.borderStrokeWidth > 0.0) {
        // Outlined lines are drawn by drawing a thicker path underneath, then
        // stenciling the middle (in case the line fill is transparent), and
        // finally drawing the line fill.
        borderPaint = Paint()
          ..color = point.borderColor
          ..strokeWidth = 1
          ..strokeCap = point.strokeCap
          ..strokeJoin = point.strokeJoin
          ..style = PaintingStyle.stroke;

        // filterPaint = Paint()
        //   ..color = point.borderColor.withAlpha(255)
        //   ..strokeWidth = strokeWidth
        //   ..strokeCap = point.strokeCap
        //   ..strokeJoin = point.strokeJoin
        //   ..style = isDotted ? PaintingStyle.fill : PaintingStyle.stroke
        //   ..blendMode = BlendMode.dstOut;
      }

      // final radius = paint.strokeWidth / 2;
      // final borderRadius = (borderPaint?.strokeWidth ?? 0) / 2;

      // if (isDotted) {
      //   final spacing = strokeWidth * 1.5;
      //   if (borderPaint != null && filterPaint != null) {
      //     _paintDottedLine(borderPath, offsets, borderRadius, spacing);
      //     _paintDottedLine(filterPath, offsets, radius, spacing);
      //   }
      //   _paintDottedLine(path, offsets, radius, spacing);
      // } else {
      // if (borderPaint != null && filterPaint != null) {
      //   _paintLine(borderPath, offset);
      // _paintLine(filterPath, offset);
      // }
      _paintLine(borderPath, offset, rect: outRect);
      outRect = null;
      // _paintLine(path, offset);
      // }
    }

    drawPaths();
  }

  void _paintDottedLine(ui.Path path, List<Offset> offsets, double radius, double stepLength) {
    var startDistance = 0.0;
    for (var i = 0; i < offsets.length - 1; i++) {
      final o0 = offsets[i];
      final o1 = offsets[i + 1];
      final totalDistance = (o0 - o1).distance;
      var distance = startDistance;
      while (distance < totalDistance) {
        final f1 = distance / totalDistance;
        final f0 = 1.0 - f1;
        final offset = Offset(o0.dx * f0 + o1.dx * f1, o0.dy * f0 + o1.dy * f1);
        path.addOval(Rect.fromCircle(center: offset, radius: radius));
        distance += stepLength;
      }
      startDistance = distance < totalDistance ? stepLength - (totalDistance - distance) : distance - totalDistance;
    }
    path.addOval(Rect.fromCircle(center: offsets.last, radius: radius));
  }

  void _paintLine(ui.Path path, Offset offset, {Rect? rect}) {
    path.addRect(rect ?? getRect(offset));
  }

  ui.Gradient _paintGradient(Polyline polyline, List<Offset> offsets) =>
      ui.Gradient.linear(offsets.first, offsets.last, polyline.gradientColors!, _getColorsStop(polyline));

  List<double>? _getColorsStop(Polyline polyline) => (polyline.colorsStop != null && polyline.colorsStop!.length == polyline.gradientColors!.length)
      ? polyline.colorsStop
      : _calculateColorsStop(polyline);

  List<double> _calculateColorsStop(Polyline polyline) {
    final colorsStopInterval = 1.0 / polyline.gradientColors!.length;
    return polyline.gradientColors!.map((gradientColor) => polyline.gradientColors!.indexOf(gradientColor) * colorsStopInterval).toList();
  }

  double _metersToStrokeWidth(
    Offset origin,
    LatLng p0,
    Offset o0,
    double strokeWidthInMeters,
  ) {
    final r = _distance.offset(p0, strokeWidthInMeters, 180);
    final delta = o0 - getOffset(origin, r);
    return delta.distance;
  }

  @override
  bool shouldRepaint(_RectPainter oldDelegate) => false;
}

const _distance = Distance();
