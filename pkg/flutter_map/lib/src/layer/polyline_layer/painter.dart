part of 'polyline_layer.dart';

/// [CustomPainter] for [Polygon]s.
class _PolylinePainter<R extends Object> extends CustomPainter {
  /// Reference to the list of [Polyline]s.
  final List<Polyline<R>> polylines;

  /// Reference to the [MapCamera].
  final MapCamera camera;
  final LayerHitNotifier<R>? hitNotifier;
  final double minimumHitbox;

  final _hits = <R>[]; // Avoids repetitive memory reallocation

  /// Create a new [_PolylinePainter] instance
  _PolylinePainter({
    required this.polylines,
    required this.camera,
    required this.hitNotifier,
    required this.minimumHitbox,
  });

  List<Offset> getOffsets(Offset origin, List<LatLng> points) => List.generate(
        points.length,
        (index) => getOffset(origin, points[index]),
        growable: false,
      );

  Offset getOffset(Offset origin, LatLng point) {
    // Critically create as little garbage as possible. This is called on every frame.
    final projected = camera.project(point);
    return Offset(projected.x - origin.dx, projected.y - origin.dy);
  }

  @override
  bool? hitTest(Offset position) {
    if (hitNotifier == null) return null;

    _hits.clear();

    final origin = camera.project(camera.center).toOffset() - camera.size.toOffset() / 2;

    for (final polyline in polylines.reversed) {
      if (polyline.hitValue == null) continue;

      // TODO: For efficiency we'd ideally filter by bounding box here. However
      // we'd need to compute an extended bounding box that accounts account for
      // the stroke width.
      // if (!p.boundingBox.contains(touch)) {
      //   continue;
      // }

      final offsets = getOffsets(origin, polyline.points);
      final strokeWidth = polyline.useStrokeWidthInMeter
          ? _metersToStrokeWidth(
              origin,
              polyline.points.first,
              offsets.first,
              polyline.strokeWidth,
            )
          : polyline.strokeWidth;
      final hittableDistance = math.max(
        strokeWidth / 2 + polyline.borderStrokeWidth / 2,
        minimumHitbox,
      );

      for (int i = 0; i < offsets.length - 1; i++) {
        final o1 = offsets[i];
        final o2 = offsets[i + 1];

        final distance = math.sqrt(
          getSqSegDist(
            position.dx,
            position.dy,
            o1.dx,
            o1.dy,
            o2.dx,
            o2.dy,
          ),
        );

        if (distance < hittableDistance) {
          _hits.add(polyline.hitValue!);
          break;
        }
      }
    }

    if (_hits.isEmpty) {
      hitNotifier!.value = null;
      return false;
    }

    hitNotifier!.value = LayerHitResult(
      hitValues: _hits,
      point: camera.pointToLatLng(math.Point(position.dx, position.dy)),
    );
    return true;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    var path = ui.Path();
    var paint = Paint();

    void drawPaths() {
      canvas.drawPath(path, paint);
    }

    final origin = camera.project(camera.center).toOffset() - camera.size.toOffset() / 2;

    for (final polyline in polylines) {
      final offsets = getOffsets(origin, polyline.points);
      if (offsets.isEmpty) {
        continue;
      }
      paint 
        ..strokeWidth = 1
        ..strokeCap = polyline.strokeCap
        ..strokeJoin = polyline.strokeJoin
        ..style = PaintingStyle.stroke
        ..blendMode = BlendMode.srcOver;

      _paintLine(path, offsets);
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

  void _paintLine(ui.Path path, List<Offset> offsets) {
    if (offsets.isEmpty) {
      return;
    }
    path.addPolygon(offsets, false);
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
  bool shouldRepaint(_PolylinePainter<R> oldDelegate) => false;
}

const _distance = Distance();
