import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

/// Entity representing user location and status.
class UserLocation extends Equatable {
  final LatLng position;
  final double? accuracy;
  final double? altitude;
  final double? heading; // direction in degrees
  final double? speed; // speed in m/s
  final DateTime timestamp;
  final bool isInDangerZone;
  final List<String> activeDangerZones;

  const UserLocation({
    required this.position,
    this.accuracy,
    this.altitude,
    this.heading,
    this.speed,
    required this.timestamp,
    this.isInDangerZone = false,
    this.activeDangerZones = const [],
  });

  @override
  List<Object?> get props => [
    position,
    accuracy,
    altitude,
    heading,
    speed,
    timestamp,
    isInDangerZone,
    activeDangerZones,
  ];

  UserLocation copyWith({
    LatLng? position,
    double? accuracy,
    double? altitude,
    double? heading,
    double? speed,
    DateTime? timestamp,
    bool? isInDangerZone,
    List<String>? activeDangerZones,
  }) {
    return UserLocation(
      position: position ?? this.position,
      accuracy: accuracy ?? this.accuracy,
      altitude: altitude ?? this.altitude,
      heading: heading ?? this.heading,
      speed: speed ?? this.speed,
      timestamp: timestamp ?? this.timestamp,
      isInDangerZone: isInDangerZone ?? this.isInDangerZone,
      activeDangerZones: activeDangerZones ?? this.activeDangerZones,
    );
  }

  /// Get human-readable speed string.
  String get formattedSpeed {
    if (speed == null) return 'Unknown';
    final kmh = speed! * 3.6; // Convert m/s to km/h
    return '${kmh.toStringAsFixed(1)} km/h';
  }

  /// Get human-readable accuracy string.
  String get formattedAccuracy {
    if (accuracy == null) return 'Unknown';
    return '±${accuracy!.toInt()} m';
  }
}
