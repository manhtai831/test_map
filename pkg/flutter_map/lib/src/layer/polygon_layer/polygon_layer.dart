import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/misc/offsets.dart';
import 'package:flutter_map/src/misc/simplify.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:polylabel/polylabel.dart'; // conflict with Path from UI

part 'label.dart';
part 'painter.dart';
part 'polygon.dart';
part 'projected_polygon.dart';

/// A polygon layer for [FlutterMap].
@immutable
class PolygonLayer extends StatefulWidget {
  /// [Polygon]s to draw
  final List<Polygon> polygons;

  /// Whether to cull polygons and polygon sections that are outside of the
  /// viewport
  ///
  /// Defaults to `true`.
  final bool polygonCulling;

  /// Distance between two neighboring polygon points, in logical pixels scaled
  /// to floored zoom.
  ///
  /// Increasing this value results in points further apart being collapsed and
  /// thus more simplified polygons. Higher values improve performance at the
  /// cost of visual fidelity and vice versa.
  ///
  /// Defaults to 0.5. Set to 0 to disable simplification.
  final double simplificationTolerance;

  /// Whether to draw per-polygon labels
  ///
  /// Defaults to `true`.
  final bool polygonLabels;

  /// Whether to draw labels last and thus over all the polygons
  ///
  /// Defaults to `false`.
  final bool drawLabelsLast;

  /// Create a new [PolygonLayer] for the [FlutterMap] widget.
  const PolygonLayer({
    super.key,
    required this.polygons,
    this.polygonCulling = true,
    this.simplificationTolerance = 0.5,
    this.polygonLabels = true,
    this.drawLabelsLast = false,
  });

  @override
  State<PolygonLayer> createState() => _PolygonLayerState();
}

class _PolygonLayerState extends State<PolygonLayer> {
  Iterable<_ProjectedPolygon>? _cachedProjectedPolygons;
  final _cachedSimplifiedPolygons = <int, Iterable<_ProjectedPolygon>>{};
  Iterable<_ProjectedPolygon>? culled;
  Timer? timer;
  @override
  void didUpdateWidget(PolygonLayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reuse cache
    if (widget.simplificationTolerance != 0 &&
        oldWidget.simplificationTolerance == widget.simplificationTolerance &&
        listEquals(oldWidget.polygons, widget.polygons)) {
      return;
    }

    // _cachedSimplifiedPolygons.clear();
    // _cachedProjectedPolygons = null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  recaculateWidget() {
    final camera = MapCamera.of(context);
    final projected = _cachedProjectedPolygons ??= widget.polygons.map((e) => _ProjectedPolygon.fromPolygon(camera.crs.projection, e));

    final simplified = widget.simplificationTolerance <= 0
        ? projected
        : _cachedSimplifiedPolygons[camera.zoom.floor()] ??= _computeZoomLevelSimplification(
            polygons: projected,
            pixelTolerance: widget.simplificationTolerance,
            camera: camera,
          );

    culled = _computeOverlapPolygon({'simplified': simplified, 'visibleBounds': camera.visibleBounds});
  }

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    recaculateWidget();

    if (!(culled != null && culled!.isNotEmpty)) {
      return const SizedBox();
    }

    return MobileLayerTransformer(
      child: CustomPaint(
        painter: _PolygonPainter(
          polygons: culled!,
          camera: camera,
          polygonLabels: widget.polygonLabels,
          drawLabelsLast: widget.drawLabelsLast,
        ),
        size: Size(camera.size.x, camera.size.y),
      ),
    );
  }

  static Iterable<_ProjectedPolygon> _computeOverlapPolygon(Map<String, dynamic> json) {
    Iterable<_ProjectedPolygon> simplified = json['simplified'] as Iterable<_ProjectedPolygon>;
    LatLngBounds visibleBounds = json['visibleBounds'] as LatLngBounds;
    return simplified.where(
      (p) => p.polygon.boundingBox.isOverlapping(visibleBounds),
    );
  }

  static Iterable<_ProjectedPolygon> _computeZoomLevelSimplification({
    required Iterable<_ProjectedPolygon> polygons,
    required double pixelTolerance,
    required MapCamera camera,
  }) {
    final tolerance = getEffectiveSimplificationTolerance(
      crs: camera.crs,
      zoom: camera.zoom.floor(),
      pixelTolerance: pixelTolerance,
    );
    return polygons.map((e) => _ProjectedPolygon._(
        polygon: e.polygon,
        points: simplifyPoints(
          points: e.points,
          tolerance: tolerance,
          highQuality: false,
        ),
        holePoints: e.holePoints?.map((e1) => simplifyPoints(
              points: e1,
              tolerance: tolerance,
              highQuality: false,
            ))));
  }
}
