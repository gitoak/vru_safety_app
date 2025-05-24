import 'package:equatable/equatable.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';

/// Base class for all navigation-related events in the app.
/// Provides the structure for events that trigger navigation state changes.
abstract class NavigationEvent extends Equatable {
  const NavigationEvent();

  @override
  List<Object?> get props => [];
}

/// Event to initialize the navigation system with required services.
class InitializeNavigation extends NavigationEvent {}

/// Event emitted when the user's GPS position is updated.
class UpdateUserPosition extends NavigationEvent {
  /// The new user position coordinates.
  final LatLng userPosition;

  const UpdateUserPosition(this.userPosition);

  @override
  List<Object?> get props => [userPosition];
}

/// Event emitted when the device compass heading changes.
class UpdateCompassHeading extends NavigationEvent {
  /// The new compass heading in degrees (null if unavailable).
  final double? heading;

  const UpdateCompassHeading(this.heading);

  @override
  List<Object?> get props => [heading];
}

/// Event to search for an address based on user input.
class SearchAddress extends NavigationEvent {
  /// The address string to search for.
  final String address;

  const SearchAddress(this.address);

  @override
  List<Object?> get props => [address];
}

/// Event to select a suggested address from the dropdown.
class SelectSuggestion extends NavigationEvent {
  /// The selected address suggestion.
  final String suggestion;

  const SelectSuggestion(this.suggestion);

  @override
  List<Object?> get props => [suggestion];
}

/// Event to fetch the route based on the selected destination and waypoints.
class FetchRoute extends NavigationEvent {
  /// The latitude of the destination.
  final double destinationLat;
  
  /// The longitude of the destination.
  final double destinationLng;

  const FetchRoute(this.destinationLat, this.destinationLng);

  @override
  List<Object?> get props => [destinationLat, destinationLng];
}

/// Event to toggle the compass mode between different views or settings.
class ToggleCompassMode extends NavigationEvent {}

/// Event to update the address input suggestions based on user input.
class UpdateSuggestions extends NavigationEvent {
  /// The current input in the address search field.
  final String input;

  const UpdateSuggestions(this.input);

  @override
  List<Object?> get props => [input];
}

/// Event to signal that the map is ready for interaction and display.
class MapReady extends NavigationEvent {}

/// Event to signal that the page containing the map has been loaded.
class PageLoaded extends NavigationEvent {}

/// Event to indicate the loading state of the route (e.g., in progress, completed).
class RouteLoadingChanged extends NavigationEvent {
  /// True if the route is currently being loaded, false otherwise.
  final bool isLoading;

  const RouteLoadingChanged(this.isLoading);

  @override
  List<Object?> get props => [isLoading];
}

/// Event to report an error that occurred during navigation or map processing.
class ErrorOccurred extends NavigationEvent {
  /// The error message or code.
  final String? error;

  const ErrorOccurred(this.error);

  @override
  List<Object?> get props => [error];
}

/// Event to update the route points for the navigation route.
class RoutePointsUpdated extends NavigationEvent {
  /// The new list of route points (coordinates) for navigation.
  final List<LatLng>? routePoints;

  const RoutePointsUpdated(this.routePoints);

  @override
  List<Object?> get props => [routePoints];
}

/// Event to update the navigation instructions (e.g., turn-by-turn directions).
class InstructionsUpdated extends NavigationEvent {
  /// The new list of navigation instructions.
  final List<dynamic> instructions;

  const InstructionsUpdated(this.instructions);

  @override
  List<Object?> get props => [instructions];
}

/// Event to update the destination position for the navigation.
class DestinationPositionUpdated extends NavigationEvent {
  /// The new destination position coordinates.
  final LatLng? destinationPosition;

  const DestinationPositionUpdated(this.destinationPosition);

  @override
  List<Object?> get props => [destinationPosition];
}

/// Event to load and display danger zones on the map (e.g., no-fly zones).
class DangerZonesLoaded extends NavigationEvent {
  /// The list of danger zone polygons to be displayed on the map.
  final List<fm.Polygon> dangerZonePolygons;

  const DangerZonesLoaded(this.dangerZonePolygons);

  @override
  List<Object?> get props => [dangerZonePolygons];
}

/// Event to update the markers for danger zones on the map.
class DangerZoneMarkersUpdated extends NavigationEvent {
  /// The list of danger zone markers to be displayed on the map.
  final List<fm.Marker> dangerZoneMarkers;

  const DangerZoneMarkersUpdated(this.dangerZoneMarkers);

  @override
  List<Object?> get props => [dangerZoneMarkers];
}

/// Event to change the visibility of the address suggestions dropdown.
class ShowSuggestionsChanged extends NavigationEvent {
  /// True to show the suggestions dropdown, false to hide it.
  final bool showSuggestions;

  const ShowSuggestionsChanged(this.showSuggestions);

  @override
  List<Object?> get props => [showSuggestions];
}

/// Event to update the list of address suggestions based on user input.
class SuggestionsUpdated extends NavigationEvent {
  /// The new list of address suggestions.
  final List<String> suggestions;

  const SuggestionsUpdated(this.suggestions);

  @override
  List<Object?> get props => [suggestions];
}
