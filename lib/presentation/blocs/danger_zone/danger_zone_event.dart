import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

/// Base class for all danger zone-related events.
abstract class DangerZoneEvent extends Equatable {
  const DangerZoneEvent();

  @override
  List<Object?> get props => [];
}

/// Event to initialize the danger zone monitoring system with defined polygons.
class InitializeDangerZoneSystem extends DangerZoneEvent {
  /// List of polygonal regions that define the danger zones.
  final List<List<LatLng>> dangerousPolygons;

  const InitializeDangerZoneSystem(this.dangerousPolygons);

  @override
  List<Object?> get props => [dangerousPolygons];
}

/// Event emitted when the user's GPS position changes.
class UserPositionChangedForDangerZone extends DangerZoneEvent {
  /// The updated user position.
  final Position position;

  const UserPositionChangedForDangerZone(this.position);

  @override
  List<Object?> get props => [position];
}

/// Event to dispose of resources and stop monitoring.
class DisposeDangerZoneSystem extends DangerZoneEvent {}
