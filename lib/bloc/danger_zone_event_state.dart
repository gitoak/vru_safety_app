import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

// --- Events ---
abstract class DangerZoneEvent extends Equatable {
  const DangerZoneEvent();

  @override
  List<Object?> get props => [];
}

class InitializeDangerZoneSystem extends DangerZoneEvent {
  final List<List<LatLng>> dangerousPolygons;
  const InitializeDangerZoneSystem(this.dangerousPolygons);

  @override
  List<Object?> get props => [dangerousPolygons];
}

class UserPositionChangedForDangerZone extends DangerZoneEvent {
  final Position position;
  const UserPositionChangedForDangerZone(this.position);

  @override
  List<Object?> get props => [position];
}

class DisposeDangerZoneSystem extends DangerZoneEvent {}

// --- States ---
abstract class DangerZoneState extends Equatable {
  const DangerZoneState();

  @override
  List<Object?> get props => [];
}

class DangerZoneInitial extends DangerZoneState {}

class DangerZoneMonitoring extends DangerZoneState {
  final bool isInDangerZone;
  final bool hasAlertedForCurrentZone; // To prevent continuous alerts

  const DangerZoneMonitoring({
    required this.isInDangerZone,
    required this.hasAlertedForCurrentZone,
  });

  @override
  List<Object?> get props => [isInDangerZone, hasAlertedForCurrentZone];

  DangerZoneMonitoring copyWith({
    bool? isInDangerZone,
    bool? hasAlertedForCurrentZone,
  }) {
    return DangerZoneMonitoring(
      isInDangerZone: isInDangerZone ?? this.isInDangerZone,
      hasAlertedForCurrentZone: hasAlertedForCurrentZone ?? this.hasAlertedForCurrentZone,
    );
  }
}

class DangerZoneError extends DangerZoneState {
  final String message;
  const DangerZoneError(this.message);

  @override
  List<Object?> get props => [message];
}
