import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

/// Entity representing a navigation route.
class Route extends Equatable {
  final String id;
  final List<LatLng> points;
  final List<RouteInstruction> instructions;
  final double totalDistance; // in meters
  final int totalTime; // in milliseconds
  final String profile; // foot, bike, car, etc.
  final List<double>? bbox; // bounding box
  final double ascend; // elevation gain in meters
  final double descend; // elevation loss in meters

  const Route({
    required this.id,
    required this.points,
    required this.instructions,
    required this.totalDistance,
    required this.totalTime,
    required this.profile,
    this.bbox,
    this.ascend = 0.0,
    this.descend = 0.0,
  });

  @override
  List<Object?> get props => [
    id,
    points,
    instructions,
    totalDistance,
    totalTime,
    profile,
    bbox,
    ascend,
    descend,
  ];

  Route copyWith({
    String? id,
    List<LatLng>? points,
    List<RouteInstruction>? instructions,
    double? totalDistance,
    int? totalTime,
    String? profile,
    List<double>? bbox,
    double? ascend,
    double? descend,
  }) {
    return Route(
      id: id ?? this.id,
      points: points ?? this.points,
      instructions: instructions ?? this.instructions,
      totalDistance: totalDistance ?? this.totalDistance,
      totalTime: totalTime ?? this.totalTime,
      profile: profile ?? this.profile,
      bbox: bbox ?? this.bbox,
      ascend: ascend ?? this.ascend,
      descend: descend ?? this.descend,
    );
  }

  /// Get human-readable duration string.
  String get formattedDuration {
    final duration = Duration(milliseconds: totalTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  /// Get human-readable distance string.
  String get formattedDistance {
    if (totalDistance >= 1000) {
      return '${(totalDistance / 1000).toStringAsFixed(1)} km';
    } else {
      return '${totalDistance.toInt()} m';
    }
  }
}

/// Entity representing a single route instruction.
class RouteInstruction extends Equatable {
  final String text;
  final double distance; // in meters
  final int time; // in milliseconds
  final int sign; // turn direction indicator
  final List<int> interval; // point indices in route
  final LatLng? coordinate;

  const RouteInstruction({
    required this.text,
    required this.distance,
    required this.time,
    required this.sign,
    required this.interval,
    this.coordinate,
  });

  @override
  List<Object?> get props => [text, distance, time, sign, interval, coordinate];

  RouteInstruction copyWith({
    String? text,
    double? distance,
    int? time,
    int? sign,
    List<int>? interval,
    LatLng? coordinate,
  }) {
    return RouteInstruction(
      text: text ?? this.text,
      distance: distance ?? this.distance,
      time: time ?? this.time,
      sign: sign ?? this.sign,
      interval: interval ?? this.interval,
      coordinate: coordinate ?? this.coordinate,
    );
  }
}
