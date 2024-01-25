import 'dart:math';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/misc/offsets.dart';
import 'package:latlong2/latlong.dart' as latlng;

import 'layer.dart';

class PolygonLayerOptions extends LayerOptions {
  final List<PolygonV2> polygons;
  final bool polygonCulling;

  /// screen space culling of polygons based on bounding box
  PolygonLayerOptions({
    this.polygons = const [],
    this.polygonCulling = false,
    super.rebuild,
  }) {
    if (polygonCulling) {
      for (var polygon in polygons) {
        polygon.boundingBox = LatLngBounds.fromPoints(polygon.points);
      }
    }
  }
}

class PolygonV2 {
  final List<latlng.LatLng> points;
  final List<Offset> offsets = [];
  final List<List<latlng.LatLng>>? holePointsList;
  final List<List<Offset>>? holeOffsetsList;
  final Color color;
  final double borderStrokeWidth;
  final Color borderColor;
  final bool disableHolesBorder;
  final bool isDotted;
  LatLngBounds? boundingBox;

  PolygonV2({
    required this.points,
    this.holePointsList,
    this.color = const Color(0xFF00FF00),
    this.borderStrokeWidth = 0.0,
    this.borderColor = const Color(0xFFFFFF00),
    this.disableHolesBorder = false,
    this.isDotted = false,
  }) : holeOffsetsList = null == holePointsList || holePointsList.isEmpty ? null : List.generate(holePointsList.length, (_) => []);
}

class PolygonLayerV2 extends StatelessWidget {
  final PolygonLayerOptions polygonOpts;
  // final Stream stream;

  PolygonLayerV2(this.polygonOpts);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints bc) {
        // TODO unused BoxContraints should remove?
        final size = Size(bc.maxWidth, bc.maxHeight);
        return _build(context, size);
      },
    );
  }

  Widget _build(BuildContext context, Size size) {
    final map = MapCamera.of(context);
    var polygons = <Widget>[];

    for (var polygon in polygonOpts.polygons) {
      polygon.offsets.clear();

      if (null != polygon.holeOffsetsList) {
        for (var offsets in polygon.holeOffsetsList!) {
          offsets.clear();
        }
      }

      if (polygonOpts.polygonCulling && !polygon.boundingBox!.isOverlapping(map.visibleBounds)) {
        // skip this polygon as it's offscreen
        continue;
      }

      _fillOffsets(polygon.offsets, polygon.points, map);

      if (null != polygon.holePointsList) {
        for (var i = 0, len = polygon.holePointsList!.length; i < len; ++i) {
          _fillOffsets(polygon.holeOffsetsList![i], polygon.holePointsList![i], map);
        }
      }

      polygons.add(
        CustomPaint(
          painter: PolygonPainter(polygon),
          size: size,
        ),
      );
    }

    return Container(
      child: Stack(
        children: polygons,
      ),
    );
  }

  void _fillOffsets(final List<Offset> offsets, final List<latlng.LatLng> points, MapCamera map) {
    final origin = (map.project(map.center) - map.size / 2).toOffset();

    final rOffsets = getOffsets(map, origin, points);
    offsets.addAll(rOffsets);
  }
}

class PolygonPainter extends CustomPainter {
  final PolygonV2 polygonOpt;

  PolygonPainter(this.polygonOpt);

  @override
  void paint(Canvas canvas, Size size) {
    if (polygonOpt.offsets.isEmpty) {
      return;
    }
    final rect = Offset.zero & size;
    _paintPolygon(canvas, rect);
  }

  void _paintBorder(Canvas canvas) {
    if (polygonOpt.borderStrokeWidth > 0.0) {
      var borderRadius = (polygonOpt.borderStrokeWidth / 2);

      final borderPaint = Paint()
        ..color = polygonOpt.borderColor
        ..strokeWidth = polygonOpt.borderStrokeWidth;

      if (polygonOpt.isDotted) {
        var spacing = polygonOpt.borderStrokeWidth * 1.5;
        _paintDottedLine(canvas, polygonOpt.offsets, borderRadius, spacing, borderPaint);

        if (!polygonOpt.disableHolesBorder && null != polygonOpt.holeOffsetsList) {
          for (var offsets in polygonOpt.holeOffsetsList!) {
            _paintDottedLine(canvas, offsets, borderRadius, spacing, borderPaint);
          }
        }
      } else {
        _paintLine(canvas, polygonOpt.offsets, borderRadius, borderPaint);

        if (!polygonOpt.disableHolesBorder && null != polygonOpt.holeOffsetsList) {
          for (var offsets in polygonOpt.holeOffsetsList!) {
            _paintLine(canvas, offsets, borderRadius, borderPaint);
          }
        }
      }
    }
  }

  void _paintDottedLine(Canvas canvas, List<Offset> offsets, double radius, double stepLength, Paint paint) {
    var startDistance = 0.0;
    for (var i = 0; i < offsets.length - 1; i++) {
      var o0 = offsets[i];
      var o1 = offsets[i + 1];
      var totalDistance = _dist(o0, o1);
      var distance = startDistance;
      while (distance < totalDistance) {
        var f1 = distance / totalDistance;
        var f0 = 1.0 - f1;
        var offset = Offset(o0.dx * f0 + o1.dx * f1, o0.dy * f0 + o1.dy * f1);
        canvas.drawCircle(offset, radius, paint);
        distance += stepLength;
      }
      startDistance = distance < totalDistance ? stepLength - (totalDistance - distance) : distance - totalDistance;
    }
    canvas.drawCircle(offsets.last, radius, paint);
  }

  void _paintLine(Canvas canvas, List<Offset> offsets, double radius, Paint paint) {
    canvas.drawPoints(PointMode.lines, [...offsets, offsets[0]], paint);
    for (var offset in offsets) {
      canvas.drawCircle(offset, radius, paint);
    }
  }

  void _paintPolygon(Canvas canvas, Rect rect) {
    final paint = Paint();

    if (null != polygonOpt.holeOffsetsList) {
      canvas.saveLayer(rect, paint);
      paint.style = PaintingStyle.fill;

      for (var offsets in polygonOpt.holeOffsetsList!) {
        Path path = Path();
        path.addPolygon(offsets, true);
        canvas.drawPath(path, paint);
      }

      paint
        ..color = polygonOpt.color
        ..blendMode = BlendMode.srcOut;

      var path = Path();
      path.addPolygon(polygonOpt.offsets, true);
      canvas.drawPath(path, paint);

      _paintBorder(canvas);

      canvas.restore();
    } else {
      canvas.clipRect(rect);
      paint
        ..style = PaintingStyle.fill
        ..color = polygonOpt.color;

      var path = Path();
      path.addPolygon(polygonOpt.offsets, true);
      canvas.drawPath(path, paint);

      _paintBorder(canvas);
    }
  }

  @override
  bool shouldRepaint(PolygonPainter other) => false;

  double _dist(Offset v, Offset w) {
    return sqrt(_dist2(v, w));
  }

  double _dist2(Offset v, Offset w) {
    return _sqr(v.dx - w.dx) + _sqr(v.dy - w.dy);
  }

  double _sqr(double x) {
    return x * x;
  }
}
