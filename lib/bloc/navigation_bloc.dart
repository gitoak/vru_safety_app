import 'package:equatable/equatable.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

// --- Events ---
abstract class NavigationEvent extends Equatable {
  const NavigationEvent();

  @override
  List<Object?> get props => [];
}

class InitializeNavigationRequested extends NavigationEvent {}

class SearchRouteRequested extends NavigationEvent {
  final String address;
  const SearchRouteRequested(this.address);

  @override
  List<Object?> get props => [address];
}

class UserPositionUpdated extends NavigationEvent {
  final Position position;
  const UserPositionUpdated(this.position);

  @override
  List<Object?> get props => [position];
}

class UserHeadingUpdated extends NavigationEvent {
  final double heading;
  const UserHeadingUpdated(this.heading);

  @override
  List<Object?> get props => [heading];
}

class AddressSuggestionsRequested extends NavigationEvent {
  final String input;
  const AddressSuggestionsRequested(this.input);

  @override
  List<Object?> get props => [input];
}

class AddressSuggestionSelected extends NavigationEvent {
  final String suggestion;
  const AddressSuggestionSelected(this.suggestion);

  @override
  List<Object?> get props => [suggestion];
}

// --- States ---
abstract class NavigationState extends Equatable {
  const NavigationState();

  @override
  List<Object?> get props => [];
}

class NavigationInitial extends NavigationState {}

class NavigationLoadInProgress extends NavigationState {}

class NavigationLoadSuccess extends NavigationState {
  final LatLng userPosition;
  final double userHeading;
  final List<LatLng>? routePoints;
  final List<dynamic> instructions;
  final LatLng? destinationPosition;
  final List<String> suggestions;
  final bool showSuggestions;
  final List<fm.Polygon<Object>> dangerZonePolygons;
  final String? currentAddressText; // To keep search bar text if needed

  const NavigationLoadSuccess({
    required this.userPosition,
    this.userHeading = 0.0,
    this.routePoints,
    this.instructions = const [],
    this.destinationPosition,
    this.suggestions = const [],
    this.showSuggestions = false,
    this.dangerZonePolygons = const [],
    this.currentAddressText,
  });

  @override
  List<Object?> get props => [
        userPosition,
        userHeading,
        routePoints,
        instructions,
        destinationPosition,
        suggestions,
        showSuggestions,
        dangerZonePolygons,
        currentAddressText,
      ];

  NavigationLoadSuccess copyWith({
    LatLng? userPosition,
    double? userHeading,
    List<LatLng>? routePoints,
    bool clearRoutePoints = false,
    List<dynamic>? instructions,
    bool clearInstructions = false,
    LatLng? destinationPosition,
    bool clearDestinationPosition = false,
    List<String>? suggestions,
    bool? showSuggestions,
    List<fm.Polygon<Object>>? dangerZonePolygons,
    String? currentAddressText,
    bool clearCurrentAddressText = false,
  }) {
    return NavigationLoadSuccess(
      userPosition: userPosition ?? this.userPosition,
      userHeading: userHeading ?? this.userHeading,
      routePoints: clearRoutePoints ? null : routePoints ?? this.routePoints,
      instructions: clearInstructions ? [] : instructions ?? this.instructions,
      destinationPosition: clearDestinationPosition ? null : destinationPosition ?? this.destinationPosition,
      suggestions: suggestions ?? this.suggestions,
      showSuggestions: showSuggestions ?? this.showSuggestions,
      dangerZonePolygons: dangerZonePolygons ?? this.dangerZonePolygons,
      currentAddressText: clearCurrentAddressText ? null : currentAddressText ?? this.currentAddressText,
    );
  }
}

class NavigationRouteSearchInProgress extends NavigationState {}

class NavigationLoadFailure extends NavigationState {
  final String message;
  const NavigationLoadFailure(this.message);

  @override
  List<Object?> get props => [message];
}
