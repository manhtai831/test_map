import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

/// Immutable marker options for [RectMarker]. Circle markers are a more
/// simple and performant way to draw markers as the regular [Marker]
@immutable
class RectMarker {
  /// An optional [Key] for the [RectMarker].
  /// This key is not used internally.
  final Key? key;

  /// The center coordinates of the circle
  final LatLng point;

  /// The radius of the circle
  final double radius;

  /// The color of the circle area.
  final Color color;

  /// The stroke width for the circle border. Defaults to 0 (no border)
  final double borderStrokeWidth;

  /// The color of the circle border line. Needs [borderStrokeWidth] to be > 0
  /// to be visible.
  final Color borderColor;

  /// Set to true if the radius should use the unit meters.
  final bool useRadiusInMeter;

  /// Constructor to create a new [RectMarker] object
  const RectMarker({
    required this.point,
    required this.radius,
    this.key,
    this.useRadiusInMeter = false,
    this.color = const Color(0xFF00FF00),
    this.borderStrokeWidth = 0.0,
    this.borderColor = const Color(0xFFFFFF00),
  });
}

/// A layer that displays a list of [RectMarker] on the map
@immutable
class RectLayer extends StatefulWidget {
  /// The list of [RectMarker]s.
  final List<RectMarker> circles;

  /// Create a new [RectLayer] as a child for flutter map
  const RectLayer({super.key, required this.circles});

  @override
  State<RectLayer> createState() => _RectLayerState();
}

class _RectLayerState extends State<RectLayer> {
  final sizeByLongtitude = <double, Size>{};
  final sizeByLatitude = <double, Size>{};
  @override
  void initState() {
    super.initState();
    _caculateSizeMoreByOffset();
  }

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    return MobileLayerTransformer(
      child: CustomPaint(
        painter: RectPainter(
          widget.circles,
          camera,
          sizeByLongtitude,
          sizeByLatitude,
        ),
        size: Size(camera.size.x, camera.size.y),
        isComplex: true,
      ),
    );
  }

  void _caculateSizeMoreByOffset() {
    for (int i = 0; i < widget.circles.length - 1; i++) {
      final rect = widget.circles[i];

      final nextRect = widget.circles[i + 1];
      final diff = double.parse((nextRect.point.longitude - rect.point.longitude).toStringAsFixed(4));
      final diffLat = double.parse((nextRect.point.latitude - rect.point.latitude).toStringAsFixed(4));
      if (diff == 0.013) {
        sizeByLongtitude[rect.point.longitude] = Size(5.5, 0);
      }
      if (diffLat == 0.0084) {
        sizeByLatitude[nextRect.point.latitude] = Size(5.5, 0);
      }
    }
    print('sizeByOffset: ${sizeByLatitude} -----------------\n $sizeByLongtitude');
    if (mounted) setState(() {});
  }
}

/// The [CustomPainter] used to draw [RectMarker] for the [RectLayer].
@immutable
class RectPainter extends CustomPainter {
  /// Reference to the list of [RectMarker]s of the [RectLayer].
  final List<RectMarker> circles;

  final Map<double, Size> sizeByLongtitude;
  final Map<double, Size> sizeByLatitude;

  /// Reference to the [MapCamera].
  final MapCamera camera;

  /// Create a [RectPainter] instance by providing the required
  /// reference objects.
  const RectPainter(
    this.circles,
    this.camera,
    this.sizeByLongtitude,
    this.sizeByLatitude,
  );

  // double getRadius()=> 5.38 * camera.zoom;

  @override
  void paint(Canvas canvas, Size size) {
    const distance = Distance();
    final rect = Offset.zero & size;
    canvas.clipRect(rect);

    // Let's calculate all the points grouped by color and radius
    // final points = <Color, Map<double, List<Offset>>>{};
    // final pointsFilledBorder = <Color, Map<double, List<Offset>>>{};
    final pointsBorder = <RectMarker, Map<double, Map<List<Size>, Offset>>>{};
    for (final circle in circles) {
      final offset = camera.getOffsetFromOrigin(circle.point);
      // double radius = circle.radius;
      // if (circle.useRadiusInMeter) {
      //   final r = distance.offset(circle.point, circle.radius, 180);
      //   final delta = offset - camera.getOffsetFromOrigin(r);
      //   radius = delta.distance * 50;
      // }
      // points[circle.color] ??= {};
      // points[circle.color]![radius] ??= [];
      // points[circle.color]![radius]!.add(offset);

      if (circle.borderStrokeWidth > 0) {
        // Check if color have some transparency or not
        // As drawPoints is more efficient than drawCircle
        if (circle.color.alpha == 0xFF) {
          // double radiusBorder = circle.radius + circle.borderStrokeWidth;
          // if (circle.useRadiusInMeter) {
          //   final rBorder = distance.offset(circle.point, radiusBorder, 180);
          //   final deltaBorder = offset - camera.getOffsetFromOrigin(rBorder);
          //   radiusBorder = deltaBorder.distance * 50;
          // }
          // pointsFilledBorder[circle.borderColor] ??= {};
          // pointsFilledBorder[circle.borderColor]![radiusBorder] ??= [];
          // pointsFilledBorder[circle.borderColor]![radiusBorder]!.add(offset);
        } else {
          List<Size> rSize = [];
          if (circle.useRadiusInMeter) {
            rSize = getSizesInMetter(offset, circle, distance);
          }
          pointsBorder[circle] ??= {};
          pointsBorder[circle]![circle.borderStrokeWidth] ??= {};
          pointsBorder[circle]![circle.borderStrokeWidth]![rSize] = offset;
        }
      }
    }

    // Now that all the points are grouped, let's draw them
    final paintBorder = Paint()..style = PaintingStyle.stroke;
    for (final circle in pointsBorder.keys) {
      final fillColor = circle.color;
      final strokeColor = circle.borderColor;
      final strokeWidth = circle.borderStrokeWidth;

      for (final borderWidth in pointsBorder[circle]!.keys) {
        final pointsBySize = pointsBorder[circle]![borderWidth]!;
        for (final sizes in pointsBySize.keys) {
          final offset = pointsBySize[sizes]!;
          paintBorder
            ..style = PaintingStyle.fill
            ..color = fillColor;
          _paintCircle(canvas, offset, sizes[0], sizes[1], paintBorder);
          final LatLng rBorder = distance.offset(circle.point, strokeWidth, 180);
          final delta = offset - camera.getOffsetFromOrigin(rBorder);
          paintBorder
            ..style = PaintingStyle.stroke
            ..strokeWidth = delta.distance * 15
            ..color = strokeColor;
          _paintCircle(canvas, offset, sizes[0], sizes[1], paintBorder);
        }
      }
    }

    // Then the filled border in order to be under the circle
    // final paintPoint = Paint()
    //   ..isAntiAlias = false
    //   ..strokeCap = StrokeCap.round;
    // for (final color in pointsFilledBorder.keys) {
    //   final paint = paintPoint..color = color;
    //   final pointsByRadius = pointsFilledBorder[color]!;
    //   for (final radius in pointsByRadius.keys) {
    //     final pointsByRadiusColor = pointsByRadius[radius]!;
    //     final radiusPaint = paint..strokeWidth = radius * 2;
    //     _paintPoints(canvas, pointsByRadiusColor, radiusPaint);
    //   }
    // }

    // And then the circle
    // for (final color in points.keys) {
    //   final paint = paintPoint..color = color;
    //   final pointsByRadius = points[color]!;
    //   for (final radius in pointsByRadius.keys) {
    //     final pointsByRadiusColor = pointsByRadius[radius]!;
    //     final radiusPaint = paint..strokeWidth = radius * 2;
    //     _paintPoints(canvas, pointsByRadiusColor, radiusPaint);
    //   }
    // }
  }

  List<Size> getSizesInMetter(Offset offset, RectMarker circle, Distance distance) {
    Size csize = const Size(70, 60);
    Offset latlngToOffset(num distanceToMetter) {
      final LatLng rBorder = distance.offset(circle.point, distanceToMetter, 180);
      return offset - camera.getOffsetFromOrigin(rBorder);
    }

    final moreSizeLongtitude = sizeByLongtitude[circle.point.longitude];
    final moreSizeLatitude = sizeByLatitude[circle.point.latitude];
    if (moreSizeLatitude != null) {
      print('circle.point.latitude: ${circle.point.latitude} - ');
    }

    final distanceToMetter = moreSizeLongtitude == null ? 19.935208 : 21.61;
    final originOffset = latlngToOffset(20);
    final nextOffset = latlngToOffset(distanceToMetter);

    final originSize = Size(originOffset.distance * 53, originOffset.distance * 46);

    csize = Size(nextOffset.distance * 53, originOffset.distance * (moreSizeLatitude == null ? 46.055 : 46.615));

    return [originSize, csize];
  }

  void _paintPoints(Canvas canvas, List<Offset> offsets, Paint paint) {
    canvas.drawPoints(PointMode.points, offsets, paint);
  }

  void _paintCircle(Canvas canvas, Offset offset, Size origin, Size sFinal, Paint paint) {
    canvas.drawRect(Rect.fromLTWH(offset.dx - (origin.width / 2), offset.dy - (origin.height / 2), sFinal.width, sFinal.height), paint);
  }

  // void _paintCircle(Canvas canvas, Offset offset, double radius, Paint paint) {
  //   canvas.drawRect(Rect.fromCircle(center: offset,radius: radius), paint);
  // }

  @override
  bool shouldRepaint(RectPainter oldDelegate) => circles != oldDelegate.circles || camera != oldDelegate.camera;
}
