import 'package:equatable/equatable.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';

/// Enumeration of possible navigation system states.
enum NavigationStatus { 
  /// Initial state before any navigation operations.
  initial, 
  /// Loading state during navigation operations.
  loading, 
  /// Successfully loaded navigation data.
  loaded, 
  /// Error state when navigation operations fail.
  error 
}

/// Immutable state class that holds all navigation-related data.
/// Contains route information, user location, danger zones, and UI state.
class NavigationState extends Equatable {
  /// Current status of the navigation system.
  final NavigationStatus status;
  
  /// List of coordinates that form the current route.
  final List<LatLng>? routePoints;
  
  /// Whether the main page is in loading state.
  final bool pageLoading;
  
  /// Whether route calculation is in progress.
  final bool routeLoading;
  
  /// Error message if navigation operations fail.
  final String? error;
  
  /// Current user's GPS position.
  final LatLng? userPosition;
  
  /// Selected destination coordinates.
  final LatLng? destinationPosition;
  
  /// List of address suggestions for autocomplete.
  final List<String> suggestions;
  
  /// Whether to show address suggestions dropdown.
  final bool showSuggestions;
  
  /// Turn-by-turn navigation instructions.
  final List<dynamic> instructions;
  
  /// Whether compass mode is enabled for navigation.
  final bool compassMode;
  
  /// Polygons representing danger zones on the map.
  final List<fm.Polygon> dangerZonePolygons;
  
  /// Markers for danger zones on the map.
  final List<fm.Marker> dangerZoneMarkers;
  
  /// Current compass heading in degrees.
  final double? compassHeading;
  
  /// Whether the map widget is ready for interaction.
  final bool isMapReady;

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
    this.isMapReady = false,
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
    bool? isMapReady,
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
      isMapReady: isMapReady ?? this.isMapReady,
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
    isMapReady,
  ];
}
