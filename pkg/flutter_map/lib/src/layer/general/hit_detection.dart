import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';
import 'package:meta/meta.dart';

/// Result emmitted by hit notifiers (see [LayerHitNotifier]) when a hit is
/// detected on a feature within the respective layer
///
/// Not emitted if the hit was not over a feature.
@immutable
class LayerHitResult<R extends Object> {
  /// `hitValue`s from all features hit (which have `hitValue`s defined)
  ///
  /// If a feature is hit but has no `hitValue` defined, it will not be included.
  ///
  /// Ordered by their corresponding feature, first-to-last, visually
  /// top-to-bottom.
  final List<R> hitValues;

  /// Coordinates of the detected hit
  ///
  /// Note that this may not lie on a feature.
  final LatLng point;

  @internal
  const LayerHitResult({required this.hitValues, required this.point});
}

/// A [ValueNotifier] that notifies:
///
///  * a [LayerHitResult] when a hit is detected on a feature in a layer
///  * `null` when a hit is detected on the layer but not on a feature
typedef LayerHitNotifier<R extends Object> = ValueNotifier<LayerHitResult<R>?>;
