part of 'polygon_layer.dart';

@immutable
class _ProjectedPolygon {
  final Polygon polygon;
  final Iterable<DoublePoint> points;
  final Iterable<Iterable<DoublePoint>>? holePoints;

  const _ProjectedPolygon._({
    required this.polygon,
    required this.points,
    this.holePoints,
  });

  _ProjectedPolygon.fromPolygon(Projection projection, Polygon polygon)
      : this._(
          polygon: polygon,
          points: polygon.points.map((e) {
            final (x, y) = projection.projectXY(e);
            return DoublePoint(x, y);
          }),
          holePoints: () {
            final holes = polygon.holePointsList;
            if (holes == null) return null;
            return holes.map((e) => e.map((e1) {
                  final (x, y) = projection.projectXY(e1);
                  return DoublePoint(x, y);
                }));
          }(),
        );
}
