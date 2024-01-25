import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/misc/offsets.dart';
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
  /// Specific for rain data
  final sizeByLongtitude = <double, bool>{};

  /// Specific for rain data
  final sizeByLatitude = <double, bool>{};

  LatLng? latLng;
  @override
  void initState() {
    super.initState();
    _caculateSizeMoreByOffset();
  }

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    return MobileLayerTransformer(
      child: GestureDetector(
        onTapUp: _onTapUp,
        child: CustomPaint(
          painter: RectPainter(
            widget.circles,
            camera,
            sizeByLongtitude,
            sizeByLatitude,
            latLng,
          ),
          size: Size(camera.size.x, camera.size.y),
          isComplex: true,
        ),
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
        sizeByLongtitude[rect.point.longitude] = true;
      }
      if (diffLat == 0.0084) {
        sizeByLatitude[nextRect.point.latitude] = true;
      }
    }
    if (mounted) setState(() {});
  }

  void _onTapUp(TapUpDetails details) {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box != null) {
      final offset = box.globalToLocal(details.globalPosition);
        final camera = MapCamera.of(context);
      latLng = camera.offsetToCrs(offset);
      setState(() {});
    }
  }
}

/// The [CustomPainter] used to draw [RectMarker] for the [RectLayer].
@immutable
class RectPainter extends CustomPainter {
  /// Reference to the list of [RectMarker]s of the [RectLayer].
  final List<RectMarker> circles;

  /// Map longtitude must resize
  final Map<double, bool> sizeByLongtitude;

  /// Map latitude must resize
  final Map<double, bool> sizeByLatitude;

  /// Reference to the [MapCamera].
  final MapCamera camera;

  final LatLng? latLng;

  List<Rect> rects = [];

  /// Create a [RectPainter] instance by providing the required
  /// reference objects.
  RectPainter(
    this.circles,
    this.camera,
    this.sizeByLongtitude,
    this.sizeByLatitude,
    this.latLng,
  );

  // double getRadius()=> 5.38 * camera.zoom;

  @override
  void paint(Canvas canvas, Size size) {
    rects.clear();
    const distance = Distance();
    final rect = Offset.zero & size;
    canvas.clipRect(rect);
    final pointsBorder = <RectMarker, Map<double, Map<List<Size>, Offset>>>{};
    for (final circle in circles) {
      final offset = camera.getOffsetFromOrigin(circle.point);

      if (circle.borderStrokeWidth > 0) {
        List<Size> rSize = [];
        if (circle.useRadiusInMeter) {
          rSize = getSizesInMetter(offset, circle, distance);
        }
        pointsBorder[circle] ??= {};
        pointsBorder[circle]![circle.borderStrokeWidth] ??= {};
        pointsBorder[circle]![circle.borderStrokeWidth]![rSize] = offset;
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

          Rect rect = _createRect(offset, sizes[0], sizes[1]);
          _paintRect(canvas, rect, paintBorder);
          rects.add(rect);

          /// caculate border by zoom color
          final LatLng rBorder = distance.offset(circle.point, strokeWidth, 180);
          final delta = offset - camera.getOffsetFromOrigin(rBorder);
          paintBorder
            ..style = PaintingStyle.stroke
            ..strokeWidth = delta.distance * 15
            ..color = strokeColor;
          _paintRect(canvas, rect, paintBorder);
        }
      }
    }

    if (latLng != null) {
     
     final rOffset = camera.getOffsetFromOrigin(latLng!);

      final mRect = rects.firstWhereOrNull((element) => element.contains(rOffset));
      if (mRect != null) {
        paintBorder
          ..strokeWidth = 2
          ..color = Colors.red.withOpacity(.9);

        _paintRect(canvas, mRect, paintBorder);
      }
    }
  }

  /// Caculate size of square by zoom ratio
  List<Size> getSizesInMetter(Offset offset, RectMarker circle, Distance distance) {
    Size csize = const Size(70, 60);
    Offset latlngToOffset(num distanceToMetter) {
      final LatLng rBorder = distance.offset(circle.point, distanceToMetter, 180);
      return offset - camera.getOffsetFromOrigin(rBorder);
    }

    final moreSizeLongtitude = sizeByLongtitude[circle.point.longitude];
    final moreSizeLatitude = sizeByLatitude[circle.point.latitude];

    final distanceToMetter = moreSizeLongtitude == null ? 19.935208 : 21.61;
    final originOffset = latlngToOffset(20);
    final nextOffset = latlngToOffset(distanceToMetter);

    final originSize = Size(originOffset.distance * 53, originOffset.distance * 46);

    csize = Size(nextOffset.distance * 53, originOffset.distance * (moreSizeLatitude == null ? 46.055 : 46.615));

    return [originSize, csize];
  }

  Rect _createRect(Offset offset, Size origin, Size sFinal) {
    final Rect rect = Rect.fromLTWH(offset.dx - (origin.width / 2), offset.dy - (origin.height / 2), sFinal.width, sFinal.height);
    return rect;
  }

  void _paintRect(Canvas canvas, Rect rect, Paint paint) {
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(RectPainter oldDelegate) =>
      circles != oldDelegate.circles || camera != oldDelegate.camera || latLng != oldDelegate.latLng;
}
