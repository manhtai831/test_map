import 'dart:core';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/misc/simplify.dart';
import 'package:latlong2/latlong.dart';

part 'painter.dart';
part 'point_model.dart';

/// A [Polyline] (aka. LineString) layer for [FlutterMap].
@immutable
class RectLayer<R extends Object> extends StatefulWidget {
  /// [Polyline]s to draw
  final List<PointModel> points;

  /// Acceptable extent outside of viewport before culling polyline segments
  ///
  /// May need to be increased if the [Polyline.strokeWidth] +
  /// [Polyline.borderStrokeWidth] is large. See online documentation for more
  /// information.
  ///
  /// Defaults to 10. Set to `null` to disable culling.
  final double? cullingMargin;

  /// Distance between two mergeable polyline points, in decimal degrees scaled
  /// to floored zoom
  ///
  /// Increasing results in a more jagged, less accurate simplification, with
  /// improved performance; and vice versa.
  ///
  /// Note that this value is internally scaled using the current map zoom, to
  /// optimize visual performance in conjunction with improved performance with
  /// culling.
  ///
  /// Defaults to 0.5. Set to 0 to disable simplification.
  final double simplificationTolerance;

  /// A notifier to be notified when a hit test occurs on the layer
  ///
  /// If a notifier is not provided, hit testing is not performed.
  ///
  /// Notified with a [LayerHitResult] if any polylines are hit, otherwise
  /// notified with `null`.
  ///
  /// See online documentation for more detailed usage instructions. See the
  /// example project for an example implementation.
  final LayerHitNotifier<R>? hitNotifier;

  /// The minimum radius of the hittable area around each [Polyline] in logical
  /// pixels
  ///
  /// The entire visible area is always hittable, but if the visible area is
  /// smaller than this, then this will be the hittable area.
  ///
  /// Defaults to 10.
  final double minimumHitbox;

  /// Create a new [RectLayer] to use as child inside [FlutterMap.children].
  const RectLayer({
    super.key,
    required this.points,
    this.cullingMargin = 10,
    this.simplificationTolerance = 0.5,
    this.hitNotifier,
    this.minimumHitbox = 10,
  });

  @override
  State<RectLayer<R>> createState() => _RectLayerState<R>();
}

class _RectLayerState<R extends Object> extends State<RectLayer<R>> {
  final _cachedSimplifiedPolylines = <int, List<PointModel>>{};

  final _culledPolylines =
      <Polyline<R>>[]; // Avoids repetitive memory reallocation

  @override
  void didUpdateWidget(RectLayer<R> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // IF old yes & new no, clear
    // IF old no & new yes, compute
    // IF old no & new no, nothing
    // IF old yes & new yes & (different tolerance | different lines), both
    //    otherwise, nothing
    if (oldWidget.simplificationTolerance != 0 &&
        widget.simplificationTolerance != 0 &&
        (!listEquals(oldWidget.points, widget.points) ||
            oldWidget.simplificationTolerance !=
                widget.simplificationTolerance)) {
      _cachedSimplifiedPolylines.clear();
      _computeZoomLevelSimplification(MapCamera.of(context).zoom.floor());
    } else if (oldWidget.simplificationTolerance != 0 &&
        widget.simplificationTolerance == 0) {
      _cachedSimplifiedPolylines.clear();
    } else if (oldWidget.simplificationTolerance == 0 &&
        widget.simplificationTolerance != 0) {
      _computeZoomLevelSimplification(MapCamera.of(context).zoom.floor());
    }
  }

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);

    // final simplified = widget.simplificationTolerance == 0
    //     ? widget.polylines
    //     : _computeZoomLevelSimplification(camera.zoom.floor());

    // final culled = widget.cullingMargin == null
    //     ? simplified
    //     : _aggressivelyCullPolylines(
    //         polylines: simplified,
    //         camera: camera,
    //         cullingMargin: widget.cullingMargin!,
    //       );

    return MobileLayerTransformer(
      child: CustomPaint(
        painter: _RectPainter(
          points: widget.points,
          camera: camera,
          minimumHitbox: widget.minimumHitbox,
        ),
        size: Size(camera.size.x, camera.size.y),
      ),
    );
  }

  // TODO BEFORE v7: Use same algorithm as polygons
  List<PointModel> _computeZoomLevelSimplification(int zoom) =>
      _cachedSimplifiedPolylines[zoom] ??= widget.points
          .map(
            (polyline) => polyline.copyWithNewPoints(
              simplifyV2(
                points: polyline.point!,
                tolerance: widget.simplificationTolerance / math.pow(2, zoom),
                highQuality: true,
              ),
            ),
          )
          .toList();

  List<Polyline<R>> _aggressivelyCullPolylines({
    required List<Polyline<R>> polylines,
    required MapCamera camera,
    required double cullingMargin,
  }) {
    _culledPolylines.clear();

    final bounds = camera.visibleBounds;
    final margin = cullingMargin / math.pow(2, camera.zoom.floorToDouble());
    // The min(-90), max(180), ... are used to get around the limits of LatLng
    // the value cannot be greater or smaller than that
    final boundsAdjusted = LatLngBounds(
      LatLng(
        math.max(-90, bounds.southWest.latitude - margin),
        math.max(-180, bounds.southWest.longitude - margin),
      ),
      LatLng(
        math.min(90, bounds.northEast.latitude + margin),
        math.min(180, bounds.northEast.longitude + margin),
      ),
    );

    for (final polyline in polylines) {
      // Gradient poylines cannot be easily segmented
      if (polyline.gradientColors != null) {
        _culledPolylines.add(polyline);
        continue;
      }
      // pointer that indicates the start of the visible polyline segment
      int start = -1;
      bool fullyVisible = true;
      for (int i = 0; i < polyline.points.length - 1; i++) {
        //current pair
        final p1 = polyline.points[i];
        final p2 = polyline.points[i + 1];

        // segment is visible
        if (Bounds(
          math.Point(
            boundsAdjusted.southWest.longitude,
            boundsAdjusted.southWest.latitude,
          ),
          math.Point(
            boundsAdjusted.northEast.longitude,
            boundsAdjusted.northEast.latitude,
          ),
        ).aabbContainsLine(
            p1.longitude, p1.latitude, p2.longitude, p2.latitude)) {
          // segment is visible
          if (start == -1) {
            start = i;
          }
          if (!fullyVisible && i == polyline.points.length - 2) {
            final segment = polyline.points.sublist(start, i + 2);
            _culledPolylines.add(polyline.copyWithNewPoints(segment));
          }
        } else {
          fullyVisible = false;
          // if we cannot see the segment, then reset start
          if (start != -1) {
            // partial start
            final segment = polyline.points.sublist(start, i + 1);
            _culledPolylines.add(polyline.copyWithNewPoints(segment));
            start = -1;
          }
          if (start != -1) {
            start = i;
          }
        }
      }

      if (fullyVisible) _culledPolylines.add(polyline);
    }

    return _culledPolylines;
  }
}
