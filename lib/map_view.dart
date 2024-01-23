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
  List<PointModel> mPoints = [];
  MapController controller = MapController();
  Map jsonData = {};
  List<dynamic> rainData = [];
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
              if (event.source == MapEventSource.dragEnd ||
                  event.source == MapEventSource.flingAnimationController ||
                  event.source == MapEventSource.multiFingerEnd ||
                  event.source == MapEventSource.doubleTapZoomAnimationController) {
                final eventBound = event.camera.visibleBounds;
                if (eventBound.northEast == bound?.northEast &&
                    eventBound.northWest == bound?.northWest &&
                    eventBound.southEast == bound?.southEast &&
                    eventBound.southWest == bound?.southWest) return;
                bound = event.camera.visibleBounds;
                timer?.cancel();
                timer = Timer(Duration(milliseconds: 100), mapperData);
              }
            },

            onMapReady: mapperData,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.treasurecontent.guardian.dev',
            ),
            // ...polygons,
            RectLayer(
              points: mPoints,
            )
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
    String path = '${dir.path}/rain.json';
    // rainData = await compute(readFile, path);
    rainData = [
      [140.794, 37.3792, 2],
      [140.806, 37.3792, 1],
      [140.831, 37.3792, 7],
      [140.844, 37.3792, 9],
      [140.769, 37.3875, 2],
      [140.781, 37.3875, 3],
      [140.794, 37.3875, 0],
      [140.806, 37.3875, 0],
      [140.819, 37.3875, 9],
      [140.831, 37.3875, 8],
      [140.844, 37.3875, 3],
      [140.856, 37.3875, 4],
      [140.756, 37.3958, 1],
      [140.769, 37.3958, 4],
      [140.781, 37.3958, 3],
      [140.794, 37.3958, 4],
      [140.806, 37.3958, 7],
      [140.819, 37.3958, 1],
      [140.831, 37.3958, 5],
      [140.844, 37.3958, 4],
      [140.856, 37.3958, 2],
      [140.731, 37.4042, 0],
      [140.744, 37.4042, 4],
      [140.756, 37.4042, 6],
      [140.769, 37.4042, 3],
      [140.781, 37.4042, 0],
      [140.794, 37.4042, 5],
      [140.806, 37.4042, 8],
      [140.819, 37.4042, 8],
      [140.831, 37.4042, 0],
      [140.844, 37.4042, 5],
      [140.856, 37.4042, 9],
      [140.731, 37.4125, 6],
      [140.744, 37.4125, 8],
      [140.756, 37.4125, 5],
      [140.769, 37.4125, 7],
      [140.781, 37.4125, 4],
      [140.794, 37.4125, 6],
      [140.806, 37.4125, 2],
      [140.819, 37.4125, 7],
      [140.831, 37.4125, 0],
      [140.844, 37.4125, 8],
      [140.856, 37.4125, 8],
      [140.731, 37.4208, 3],
      [140.744, 37.4208, 2],
      [140.756, 37.4208, 1],
      [140.769, 37.4208, 1],
      [140.781, 37.4208, 0],
      [140.794, 37.4208, 8],
      [140.806, 37.4208, 0],
      [140.819, 37.4208, 4],
      [140.831, 37.4208, 5],
      [140.844, 37.4208, 4],
      [140.856, 37.4208, 4],
      [140.869, 37.4208, 8],
      [140.719, 37.4292, 3],
      [140.731, 37.4292, 8],
      [140.744, 37.4292, 0],
      [140.756, 37.4292, 0],
      [140.769, 37.4292, 9],
      [140.781, 37.4292, 7],
      [140.794, 37.4292, 1],
      [140.806, 37.4292, 6],
      [140.819, 37.4292, 8],
      [140.831, 37.4292, 8],
      [140.844, 37.4292, 7],
      [140.856, 37.4292, 1],
      [140.869, 37.4292, 9],
      [140.881, 37.4292, 2],
      [140.894, 37.4292, 4],
      [140.719, 37.4375, 9],
      [140.731, 37.4375, 4],
      [140.744, 37.4375, 3],
      [140.756, 37.4375, 3],
      [140.769, 37.4375, 4],
      [140.781, 37.4375, 7],
      [140.794, 37.4375, 2],
      [140.806, 37.4375, 0],
      [140.819, 37.4375, 9],
      [140.831, 37.4375, 5],
      [140.844, 37.4375, 4],
      [140.856, 37.4375, 2],
      [140.869, 37.4375, 2],
      [140.881, 37.4375, 5],
      [140.894, 37.4375, 7],
      [140.706, 37.4458, 7],
      [140.719, 37.4458, 4],
      [140.731, 37.4458, 8],
      [140.744, 37.4458, 2],
      [140.756, 37.4458, 1],
      [140.769, 37.4458, 9],
      [140.781, 37.4458, 7],
      [140.794, 37.4458, 0],
      [140.806, 37.4458, 4],
      [140.819, 37.4458, 2],
      [140.831, 37.4458, 6],
      [140.844, 37.4458, 7],
      [140.856, 37.4458, 3],
      [140.869, 37.4458, 9],
      [140.881, 37.4458, 9],
      [140.894, 37.4458, 9],
      [140.906, 37.4458, 2],
      [140.919, 37.4458, 2],
      [140.931, 37.4458, 7],
      [140.944, 37.4458, 1],
      [140.706, 37.4542, 8],
      [140.719, 37.4542, 9],
      [140.731, 37.4542, 8],
      [140.744, 37.4542, 9],
      [140.756, 37.4542, 5],
      [140.769, 37.4542, 8],
      [140.781, 37.4542, 3],
      [140.794, 37.4542, 8],
      [140.806, 37.4542, 9],
      [140.819, 37.4542, 0],
      [140.831, 37.4542, 8],
      [140.844, 37.4542, 4],
      [140.856, 37.4542, 3],
      [140.869, 37.4542, 1],
      [140.881, 37.4542, 2],
      [140.894, 37.4542, 6],
      [140.906, 37.4542, 7],
      [140.919, 37.4542, 2],
      [140.931, 37.4542, 4],
      [140.944, 37.4542, 5],
      [140.956, 37.4542, 0],
      [140.706, 37.4625, 8],
      [140.719, 37.4625, 4],
      [140.731, 37.4625, 3],
      [140.744, 37.4625, 3],
      [140.756, 37.4625, 4],
      [140.769, 37.4625, 9],
      [140.781, 37.4625, 9],
      [140.794, 37.4625, 3],
      [140.806, 37.4625, 2],
      [140.819, 37.4625, 4],
      [140.831, 37.4625, 6],
      [140.844, 37.4625, 3],
      [140.856, 37.4625, 3],
      [140.869, 37.4625, 2],
      [140.881, 37.4625, 4],
      [140.894, 37.4625, 8],
      [140.906, 37.4625, 1],
      [140.919, 37.4625, 3],
      [140.931, 37.4625, 9],
      [140.944, 37.4625, 4],
      [140.956, 37.4625, 8],
      [140.969, 37.4625, 3],
      [140.706, 37.4708, 7],
      [140.719, 37.4708, 5],
      [140.731, 37.4708, 0],
      [140.744, 37.4708, 3],
      [140.756, 37.4708, 2],
      [140.769, 37.4708, 0],
      [140.781, 37.4708, 0],
      [140.794, 37.4708, 3],
      [140.806, 37.4708, 5],
      [140.819, 37.4708, 1],
      [140.831, 37.4708, 1],
      [140.844, 37.4708, 9],
      [140.856, 37.4708, 3],
      [140.869, 37.4708, 4],
      [140.881, 37.4708, 7],
      [140.894, 37.4708, 7],
      [140.906, 37.4708, 4],
      [140.919, 37.4708, 1],
      [140.931, 37.4708, 9],
      [140.944, 37.4708, 1],
      [140.956, 37.4708, 8],
      [140.969, 37.4708, 4],
      [140.981, 37.4708, 7],
      [140.719, 37.4792, 4],
      [140.731, 37.4792, 3],
      [140.744, 37.4792, 9],
      [140.756, 37.4792, 9],
      [140.769, 37.4792, 1],
      [140.781, 37.4792, 1],
      [140.794, 37.4792, 9],
      [140.806, 37.4792, 1],
      [140.819, 37.4792, 8],
      [140.831, 37.4792, 4],
      [140.844, 37.4792, 2],
      [140.856, 37.4792, 6],
      [140.869, 37.4792, 8],
      [140.881, 37.4792, 6],
      [140.894, 37.4792, 3],
      [140.906, 37.4792, 9],
      [140.919, 37.4792, 9],
      [140.931, 37.4792, 6],
      [140.944, 37.4792, 0],
      [140.956, 37.4792, 8],
      [140.969, 37.4792, 5],
      [140.981, 37.4792, 4],
      [140.994, 37.4792, 2],
      [141.006, 37.4792, 6],
      [141.019, 37.4792, 3],
      [141.031, 37.4792, 8],
      [141.044, 37.4792, 8],
      [140.744, 37.4875, 5],
      [140.756, 37.4875, 2],
      [140.769, 37.4875, 4],
      [140.781, 37.4875, 0],
      [140.794, 37.4875, 1],
      [140.806, 37.4875, 3],
      [140.819, 37.4875, 1],
      [140.831, 37.4875, 6],
      [140.844, 37.4875, 9],
      [140.856, 37.4875, 5],
      [140.869, 37.4875, 5],
      [140.881, 37.4875, 4],
      [140.894, 37.4875, 3],
      [140.906, 37.4875, 7],
      [140.919, 37.4875, 8],
      [140.931, 37.4875, 9],
      [140.944, 37.4875, 0],
      [140.956, 37.4875, 6],
      [140.969, 37.4875, 7],
      [140.981, 37.4875, 9],
      [140.994, 37.4875, 1],
      [141.006, 37.4875, 9],
      [141.019, 37.4875, 6],
      [141.031, 37.4875, 9],
      [140.719, 37.4958, 5],
      [140.731, 37.4958, 7],
      [140.744, 37.4958, 4],
      [140.756, 37.4958, 5],
      [140.769, 37.4958, 6],
      [140.781, 37.4958, 4],
      [140.794, 37.4958, 3],
      [140.806, 37.4958, 9],
      [140.819, 37.4958, 0],
      [140.831, 37.4958, 4],
      [140.844, 37.4958, 4],
      [140.856, 37.4958, 9],
      [140.869, 37.4958, 1],
      [140.881, 37.4958, 4],
      [140.894, 37.4958, 4],
      [140.906, 37.4958, 9],
      [140.919, 37.4958, 7],
      [140.931, 37.4958, 1],
      [140.944, 37.4958, 5],
      [140.956, 37.4958, 5],
      [140.969, 37.4958, 9],
      [140.981, 37.4958, 4],
      [140.994, 37.4958, 7],
      [141.006, 37.4958, 3],
      [141.019, 37.4958, 6],
      [141.031, 37.4958, 0],
      [140.706, 37.5042, 5],
      [140.719, 37.5042, 6],
      [140.731, 37.5042, 4],
      [140.744, 37.5042, 2],
      [140.756, 37.5042, 0],
      [140.769, 37.5042, 9],
      [140.781, 37.5042, 9],
      [140.794, 37.5042, 8],
      [140.806, 37.5042, 6],
      [140.819, 37.5042, 8],
      [140.831, 37.5042, 9],
      [140.844, 37.5042, 9],
      [140.856, 37.5042, 6],
      [140.869, 37.5042, 2],
      [140.881, 37.5042, 9],
      [140.894, 37.5042, 6],
      [140.906, 37.5042, 3],
      [140.919, 37.5042, 1],
      [140.931, 37.5042, 4],
      [140.944, 37.5042, 6],
      [140.956, 37.5042, 1],
      [140.969, 37.5042, 1],
      [140.981, 37.5042, 7],
      [140.994, 37.5042, 9],
      [141.006, 37.5042, 7],
      [141.019, 37.5042, 7],
      [141.031, 37.5042, 0],
      [140.706, 37.5125, 8],
      [140.719, 37.5125, 8],
      [140.731, 37.5125, 8],
      [140.744, 37.5125, 6],
      [140.756, 37.5125, 8],
      [140.769, 37.5125, 1],
      [140.781, 37.5125, 2],
      [140.794, 37.5125, 5],
      [140.806, 37.5125, 5],
      [140.819, 37.5125, 1],
      [140.831, 37.5125, 1],
      [140.844, 37.5125, 4],
      [140.856, 37.5125, 3],
      [140.869, 37.5125, 5],
      [140.881, 37.5125, 7],
      [140.894, 37.5125, 4],
      [140.906, 37.5125, 9],
      [140.919, 37.5125, 9],
      [140.931, 37.5125, 3],
      [140.944, 37.5125, 4],
      [140.956, 37.5125, 2],
      [140.969, 37.5125, 2],
      [140.719, 37.5208, 6],
      [140.731, 37.5208, 2],
      [140.744, 37.5208, 8],
      [140.756, 37.5208, 4],
      [140.769, 37.5208, 4],
      [140.781, 37.5208, 4],
      [140.794, 37.5208, 9],
      [140.806, 37.5208, 7],
      [140.819, 37.5208, 2],
      [140.831, 37.5208, 3],
      [140.844, 37.5208, 6],
      [140.856, 37.5208, 6],
      [140.869, 37.5208, 3],
      [140.881, 37.5208, 8],
      [140.894, 37.5208, 3],
      [140.931, 37.5208, 7],
      [140.944, 37.5208, 9],
      [140.694, 37.5292, 5],
      [140.706, 37.5292, 9],
      [140.719, 37.5292, 7],
      [140.731, 37.5292, 0],
      [140.744, 37.5292, 7],
      [140.756, 37.5292, 4],
      [140.769, 37.5292, 1],
      [140.781, 37.5292, 2],
      [140.794, 37.5292, 7],
      [140.806, 37.5292, 5],
      [140.819, 37.5292, 2],
      [140.831, 37.5292, 7],
      [140.844, 37.5292, 4],
      [140.856, 37.5292, 8],
      [140.869, 37.5292, 5],
      [140.881, 37.5292, 6],
      [140.894, 37.5292, 8],
      [140.694, 37.5375, 7],
      [140.706, 37.5375, 0],
      [140.719, 37.5375, 3],
      [140.731, 37.5375, 6],
      [140.744, 37.5375, 0],
      [140.756, 37.5375, 4],
      [140.769, 37.5375, 0],
      [140.781, 37.5375, 4],
      [140.794, 37.5375, 2],
      [140.806, 37.5375, 1],
      [140.819, 37.5375, 6],
      [140.831, 37.5375, 6],
      [140.844, 37.5375, 0],
      [140.856, 37.5375, 4],
      [140.869, 37.5375, 4],
      [140.881, 37.5375, 3],
      [140.694, 37.5458, 1],
      [140.706, 37.5458, 4],
      [140.719, 37.5458, 4],
      [140.731, 37.5458, 6],
      [140.744, 37.5458, 2],
      [140.756, 37.5458, 8],
      [140.769, 37.5458, 0],
      [140.781, 37.5458, 3],
      [140.794, 37.5458, 7],
      [140.806, 37.5458, 8],
      [140.819, 37.5458, 0],
      [140.831, 37.5458, 4],
      [140.844, 37.5458, 3],
      [140.856, 37.5458, 8],
      [140.869, 37.5458, 4],
      [140.706, 37.5542, 7],
      [140.719, 37.5542, 5],
      [140.731, 37.5542, 6],
      [140.744, 37.5542, 3],
      [140.756, 37.5542, 6],
      [140.769, 37.5542, 0],
      [140.781, 37.5542, 6],
      [140.794, 37.5542, 6],
      [140.806, 37.5542, 9],
      [140.819, 37.5542, 6],
      [140.831, 37.5542, 9],
      [140.844, 37.5542, 3],
      [140.706, 37.5625, 4],
      [140.719, 37.5625, 0],
      [140.731, 37.5625, 9],
      [140.744, 37.5625, 8],
      [140.756, 37.5625, 1],
      [140.769, 37.5625, 1],
      [140.781, 37.5625, 5],
      [140.794, 37.5625, 1],
      [140.806, 37.5625, 9],
      [140.819, 37.5625, 1],
      [140.831, 37.5625, 0],
      [140.844, 37.5625, 3],
      [140.706, 37.5708, 8],
      [140.719, 37.5708, 5],
      [140.731, 37.5708, 1],
      [140.744, 37.5708, 3],
      [140.756, 37.5708, 8],
      [140.769, 37.5708, 6],
      [140.781, 37.5708, 5],
      [140.794, 37.5708, 4],
      [140.806, 37.5708, 0],
      [140.819, 37.5708, 1],
      [140.831, 37.5708, 4],
      [140.731, 37.5792, 0],
      [140.744, 37.5792, 9],
      [140.756, 37.5792, 7],
      [140.769, 37.5792, 1],
      [140.781, 37.5792, 9],
      [140.794, 37.5792, 2],
      [140.806, 37.5792, 6],
      [140.831, 37.5792, 5],
      [140.731, 37.5875, 9],
      [140.744, 37.5875, 5],
      [140.756, 37.5875, 0],
      [140.769, 37.5875, 3],
      [140.781, 37.5875, 6],
      [140.794, 37.5875, 7],
      [140.806, 37.5875, 5],
      [140.731, 37.5958, 6],
      [140.744, 37.5958, 2],
      [140.756, 37.5958, 8]
    ];
    // await box.put(key, jsonData as Map);
    // }

    dev.log('jsonData: $rainData');
    print('Read file done');

    completer.complete();
  }

  mapperData() async {
    await completer.future;
    // final map = {'bound': bound ?? controller.camera.visibleBounds, 'jsonData': jsonData};
    final map = {'bound': bound ?? controller.camera.visibleBounds, 'jsonData': rainData};
    mPoints = await compute(_mapperPoint, map);
    // polygons = await compute(_mapper, map);
    setState(() {});
  }
}

Future<List<Widget>> _mapper(Map<String, dynamic> data) async {
  List<Widget> polygons = [];
  final bound = data['bound'];
  final jsonData = data['jsonData'];

  print('Looopeeeeeeeeeeeeeeeeeee: Length draw ${(jsonData['features'] as List<dynamic>).length} ${DateTime.now()}');

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

Future<List<PointModel>> _mapperPoint(Map<String, dynamic> data) async {
  print('Looopeeeeeeeeeeeeeeeeeee: ${DateTime.now()}');
  final bound = data['bound'];
  final jsonData = data['jsonData'];
  List<PointModel> pgons = [];
  LatLng? lastPoint;
  bool isNew = true;
  for (final item in jsonData as List<dynamic>) {
    double x = double.parse(((item as List<dynamic>)[1] * 1.0 as double).toStringAsFixed(4));
    double y = double.parse(((item as List<dynamic>)[0] * 1.0 as double).toStringAsFixed(4));
    LatLng currentPoint = LatLng(x, y);
    lastPoint ??= currentPoint;

    if (lastPoint.latitude != currentPoint.latitude) {
      print(
          '(currentPoint.latitude(${currentPoint.latitude}) - lastPoint.latitude(${lastPoint.latitude})): ${double.parse((currentPoint.latitude - lastPoint.latitude).toStringAsFixed(4))}');
      double diff = double.parse((currentPoint.latitude - lastPoint.latitude).toStringAsFixed(4));
      if (diff < 0.0083) {
        isNew = false;
        x = lastPoint.latitude;
      } else if (diff > 0.0083) {
        x = double.parse((lastPoint.latitude + 0.0083).toStringAsFixed(4));
      }
      currentPoint = LatLng(x, y);
    }
    // if (lastPoint.longitude != currentPoint.longitude && !isNew) {
    //   double diff = double.parse((currentPoint.longitude - lastPoint.longitude).toStringAsFixed(4));
    //   print('(currentPoint.latitude(${currentPoint.longitude}) - lastPoint.latitude(${lastPoint.longitude})): ${diff}');

    //   if (diff > 0.012) {
    //     y = double.parse((lastPoint.longitude + 0.012).toStringAsFixed(4));
    //   }
    //   currentPoint = LatLng(x, y);
    // }
    isNew = true;
    lastPoint = currentPoint;
    PointModel polygon = PointModel(
      color: Colors.red.withOpacity(.2),
      borderColor: Colors.red,
      borderStrokeWidth: 1,
      point: currentPoint,
    );
        bool isContain = bound!.contains(currentPoint);
        if(isContain){
    pgons.add(polygon);
        }

  }
  print('Looopee Doneeeeeeeeeeeeeeeeeeeeeeee:${pgons.length} - ${DateTime.now()}');
  return pgons;
}

// Future<Map<String, dynamic>> readFile(String path) async {
//   File file = File(path);
//   String data = file.readAsStringSync();
//   return jsonDecode(data) as Map<String, dynamic>;
// }

Future<List<dynamic>> readFile(String path) async {
  File file = File(path);
  String data = file.readAsStringSync();
  return jsonDecode(data) as List<dynamic>;
}
