import 'package:equatable/equatable.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';

enum NavigationStatus { initial, loading, loaded, error }

class NavigationState extends Equatable {
  final NavigationStatus status;
  final List<LatLng>? routePoints;
  final bool pageLoading;
  final bool routeLoading;
  final String? error;
  final LatLng? userPosition;
  final LatLng? destinationPosition;
  final List<String> suggestions;
  final bool showSuggestions;
  final List<dynamic> instructions;
  final bool compassMode;
  final List<fm.Polygon> dangerZonePolygons;
  final List<fm.Marker> dangerZoneMarkers;
  final double? compassHeading; // Added for compass heading
  final bool isMapReady; // Added to track map readiness

  const NavigationState({
    this.status = NavigationStatus.initial,
    this.routePoints,
    this.pageLoading = true,
    this.routeLoading = false,
    this.error,
    this.userPosition,
    this.destinationPosition,
    this.suggestions = const [],
    this.showSuggestions = false,
    this.instructions = const [],
    this.compassMode = false,
    this.dangerZonePolygons = const [],
    this.dangerZoneMarkers = const [],
    this.compassHeading,
    this.isMapReady = false, // Initialize to false
  });

  NavigationState copyWith({
    NavigationStatus? status,
    List<LatLng>? routePoints,
    bool? pageLoading,
    bool? routeLoading,
    String? error,
    LatLng? userPosition,
    LatLng? destinationPosition,
    List<String>? suggestions,
    bool? showSuggestions,
    List<dynamic>? instructions,
    bool? compassMode,
    List<fm.Polygon>? dangerZonePolygons,
    List<fm.Marker>? dangerZoneMarkers,
    double? compassHeading,
    bool? isMapReady, // Add to copyWith
  }) {
    return NavigationState(
      status: status ?? this.status,
      routePoints: routePoints ?? this.routePoints,
      pageLoading: pageLoading ?? this.pageLoading,
      routeLoading: routeLoading ?? this.routeLoading,
      error: error ?? this.error,
      userPosition: userPosition ?? this.userPosition,
      destinationPosition: destinationPosition ?? this.destinationPosition,
      suggestions: suggestions ?? this.suggestions,
      showSuggestions: showSuggestions ?? this.showSuggestions,
      instructions: instructions ?? this.instructions,
      compassMode: compassMode ?? this.compassMode,
      dangerZonePolygons: dangerZonePolygons ?? this.dangerZonePolygons,
      dangerZoneMarkers: dangerZoneMarkers ?? this.dangerZoneMarkers,
      compassHeading: compassHeading ?? this.compassHeading,
      isMapReady: isMapReady ?? this.isMapReady, // Handle in copyWith
    );
  }

  @override
  List<Object?> get props => [
        status,
        routePoints,
        pageLoading,
        routeLoading,
        error,
        userPosition,
        destinationPosition,
        suggestions,
        showSuggestions,
        instructions,
        compassMode,
        dangerZonePolygons,
        dangerZoneMarkers,
        compassHeading,
        isMapReady, // Add to props
      ];
}
