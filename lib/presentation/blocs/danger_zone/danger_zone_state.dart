import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

/// Base class for all danger zone-related states.
abstract class DangerZoneState extends Equatable {
  const DangerZoneState();

  @override
  List<Object?> get props => [];
}

/// Initial state before monitoring begins.
class DangerZoneInitial extends DangerZoneState {}

/// State representing the loading phase during danger zone system initialization.
class DangerZoneLoading extends DangerZoneState {}

/// State indicating successful danger zone system initialization.
class DangerZoneInitialized extends DangerZoneState {
  /// Current user position
  final Position? currentPosition;
  /// Whether user is currently in a danger zone
  final bool isInDangerZone;
  /// List of active danger zones
  final List<List<LatLng>> dangerZones;

  const DangerZoneInitialized({
    this.currentPosition,
    this.isInDangerZone = false,
    this.dangerZones = const [],
  });

  @override
  List<Object?> get props => [currentPosition, isInDangerZone, dangerZones];

  DangerZoneInitialized copyWith({
    Position? currentPosition,
    bool? isInDangerZone,
    List<List<LatLng>>? dangerZones,
  }) {
    return DangerZoneInitialized(
      currentPosition: currentPosition ?? this.currentPosition,
      isInDangerZone: isInDangerZone ?? this.isInDangerZone,
      dangerZones: dangerZones ?? this.dangerZones,
    );
  }
}

/// State representing an active danger zone alert.
class DangerZoneAlert extends DangerZoneState {
  /// Current position when alert was triggered
  final Position position;
  /// Distance to danger zone
  final double distanceToDangerZone;
  /// Alert message
  final String alertMessage;

  const DangerZoneAlert({
    required this.position,
    required this.distanceToDangerZone,
    required this.alertMessage,
  });

  @override
  List<Object?> get props => [position, distanceToDangerZone, alertMessage];
}

/// State indicating user has safely exited danger zone.
class DangerZoneExited extends DangerZoneState {
  final Position position;

  const DangerZoneExited(this.position);

  @override
  List<Object?> get props => [position];
}

/// State representing an error in the danger zone system.
class DangerZoneError extends DangerZoneState {
  final String message;

  const DangerZoneError(this.message);

  @override
  List<Object?> get props => [message];
}
