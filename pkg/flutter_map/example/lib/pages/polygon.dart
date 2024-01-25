import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/misc/tile_providers.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';
import 'package:latlong2/latlong.dart';

class PolygonPage extends StatelessWidget {
  static const String route = '/polygon';

  const PolygonPage({super.key});

  final _notFilledPoints = const [
    LatLng(51.5, -0.09),
    LatLng(53.3498, -6.2603),
    LatLng(48.8566, 2.3522),
  ];
  final _filledPoints = const [
    LatLng(55.5, -0.09),
    LatLng(54.3498, -6.2603),
    LatLng(52.8566, 2.3522),
  ];
  final _notFilledDotedPoints = const [
    LatLng(49.29, -2.57),
    LatLng(51.46, -6.43),
    LatLng(49.86, -8.17),
    LatLng(48.39, -3.49),
  ];
  final _filledDotedPoints = const [
    LatLng(46.35, 4.94),
    LatLng(46.22, -0.11),
    LatLng(44.399, 1.76),
  ];
  final _labelPoints = const [
    LatLng(60.16, -9.38),
    LatLng(60.16, -4.16),
    LatLng(61.18, -4.16),
    LatLng(61.18, -9.38),
  ];
  final _labelRotatedPoints = const [
    LatLng(59.77, -10.28),
    LatLng(58.21, -10.28),
    LatLng(58.21, -7.01),
    LatLng(59.77, -7.01),
    LatLng(60.77, -6.01),
  ];
  final _holeOuterPoints = const [
    LatLng(50, -18),
    LatLng(50, -14),
    LatLng(54, -14),
    LatLng(54, -18),
  ];
  final _holeInnerPoints = const [
    LatLng(51, -17),
    LatLng(51, -16),
    LatLng(52, -16),
    LatLng(52, -17),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Polygons')),
      drawer: const MenuDrawer(PolygonPage.route),
      body: Stack(
        children: [
          FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(51.5, -0.09),
              initialZoom: 5,
            ),
            children: [
              openStreetMapTileLayer,
              PolygonLayer(
                simplificationTolerance: 0,
                polygons: [
                
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
