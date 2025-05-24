import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

/// Entity representing a dangerous road or area.
class DangerZone extends Equatable {
  final String id;
  final String name;
  final String description;
  final List<LatLng> polygon;
  final DangerLevel dangerLevel;
  final List<String> dangerTypes;
  final DateTime? lastUpdated;

  const DangerZone({
    required this.id,
    required this.name,
    required this.description,
    required this.polygon,
    required this.dangerLevel,
    required this.dangerTypes,
    this.lastUpdated,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    polygon,
    dangerLevel,
    dangerTypes,
    lastUpdated,
  ];

  DangerZone copyWith({
    String? id,
    String? name,
    String? description,
    List<LatLng>? polygon,
    DangerLevel? dangerLevel,
    List<String>? dangerTypes,
    DateTime? lastUpdated,
  }) {
    return DangerZone(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      polygon: polygon ?? this.polygon,
      dangerLevel: dangerLevel ?? this.dangerLevel,
      dangerTypes: dangerTypes ?? this.dangerTypes,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Enumeration of danger levels for zones.
enum DangerLevel {
  low,
  medium,
  high,
  critical,
}
