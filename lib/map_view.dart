import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';

/// {@template MapView}
/// [MapView] is a widget that shows a map.
/// {@endtemplate}
class MapView extends StatefulWidget {
  /// Creates a [MapView].
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  /// Controls the behavior of the map when the user's location changes.
  late final StreamController<double?> _followCurrentLocationStreamController;
  List<Widget> polygons = [];
  MapController controller = MapController();
  Map jsonData = {};
  Completer completer = Completer();
  LatLngBounds? bound;
  Timer? timer;
  @override
  void initState() {
    _followCurrentLocationStreamController = StreamController<double?>();
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) async {
      await _readFile();
    });
  }

  @override
  void dispose() {
    _followCurrentLocationStreamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FlutterMap(
          mapController: controller,
          options: MapOptions(
            initialCenter: LatLng(37.4951332, 140.9990371),
            // initialZoom: 15,
            // maxZoom: 20,
            // minZoom: 15,
            // initialCameraFit: CameraFit.bounds(bounds: LatLngBounds())
            // Stop following the location marker on the map
            // if user interacted with the map.
            // onPositionChanged: (MapPosition position, bool hasGesture) {
            //   if (hasGesture && _alignOnUpdate != AlignOnUpdate.never) {
            //     setState(
            //       () => _alignOnUpdate = AlignOnUpdate.never,
            //     );
            //   }
            // },
            // onTap: (tapPosition, point) => setState(
            //   () => _alignOnUpdate = AlignOnUpdate.never,
            // ),message
            onMapEvent: (event) async {
              // print('event: ${event.source}');
              // if (event.source == MapEventSource.dragEnd ||
              //     event.source == MapEventSource.flingAnimationController ||
              //     event.source == MapEventSource.multiFingerEnd ||
              //     event.source == MapEventSource.doubleTapZoomAnimationController) {
              //   final eventBound = event.camera.visibleBounds;
              //   if (eventBound.northEast == bound?.northEast &&
              //       eventBound.northWest == bound?.northWest &&
              //       eventBound.southEast == bound?.southEast &&
              //       eventBound.southWest == bound?.southWest) return;
              //   bound = event.camera.visibleBounds;
              //   timer?.cancel();
              //   timer = Timer(Duration(milliseconds: 100), mapperData);
              // }
            },

            onMapReady: mapperData,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.treasurecontent.guardian.dev',
            ),
            ...polygons,
          ]);

  Future<void> _readFile() async {
    await Hive.initFlutter();
    Box<Map> box = await Hive.openBox('gmap');
    String key = 'geoJson';
    Map? data = box.get(key);

    dev.log('Reading json');
    print('data.runtimeType: ${data.runtimeType}');
    // final String jsonString =
    //     await rootBundle.loadString('assets/images/template.geojson');
    final now = DateTime.now();
    // if (data != null) {
    //   jsonData = data;
    // } else {
      Directory dir = Directory('/storage/emulated/0/Download');
      String path = dir.path + '/data2.json';
      jsonData = await compute(readFile, path);
      await box.put(key, jsonData as Map);
    // }

    dev.log('jsonData: $jsonData');
    print('Read file done');

    completer.complete();
  }

  mapperData() async {
    await completer.future;
    final map = {'bound': bound ?? controller.camera.visibleBounds, 'jsonData': jsonData};
    polygons = await compute(_mapper, map);
    setState(() {});
  }
}

Future<List<Widget>> _mapper(Map<String, dynamic> data) async {
  print('Looopeeeeeeeeeeeeeeeeeee: ${DateTime.now()}');

  List<Widget> polygons = [];
  final bound = data['bound'];
  final jsonData = data['jsonData'];
  for (final item in jsonData['features'] as List<dynamic>) {
    List<Polygon> pgons = [];
    List<OverlayImage> images = [];
    for (final coor in (item['geometry']?['coordinates'] as List<dynamic>?)!) {
      Color random = Color((Random().nextDouble() * 0xFFFFFF).toInt());
      Polygon polygon = Polygon(
        color: Colors.red.withOpacity(.2),
        borderColor: Colors.red,
        borderStrokeWidth: 1,
        isFilled: true,
        points: [],
      );

      for (final point in (coor as List<dynamic>)) {
        double x = double.parse(((point as List<dynamic>)[1] * 1.0 as double).toStringAsFixed(7));
        double y = double.parse(((point as List<dynamic>)[0] * 1.0 as double).toStringAsFixed(7));
        LatLng currentPoint = LatLng(x, y);
        // bool isContain = bound!.contains(currentPoint);
        bool isExisted =
            polygon.points.where((element) => element.latitude == currentPoint.latitude && element.longitude == currentPoint.longitude).isNotEmpty;
        if (!isExisted) {
          polygon.points.add(currentPoint);
        }
      }

      if (polygon.points.isNotEmpty) {
        pgons.add(polygon);
      }
    }
    if (pgons.isNotEmpty) {
      polygons.add(PolygonLayer(
        polygons: pgons,
        polygonCulling: true,
      ));
    }
  }
  print('Looopee Doneeeeeeeeeeeeeeeeeeeeeeee: ${DateTime.now()}');
  return polygons;
}

Future<Map<String, dynamic>> readFile(String path) async {
  File file = File(path);
  String data = file.readAsStringSync();
  return jsonDecode(data) as Map<String, dynamic>;
}
