import 'package:equatable/equatable.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';

abstract class NavigationEvent extends Equatable {
  const NavigationEvent();

  @override
  List<Object?> get props => [];
}

class InitializeNavigation extends NavigationEvent {}

class UpdateUserPosition extends NavigationEvent {
  final LatLng userPosition;

  const UpdateUserPosition(this.userPosition);

  @override
  List<Object?> get props => [userPosition];
}

class UpdateCompassHeading extends NavigationEvent {
  final double? heading;

  const UpdateCompassHeading(this.heading);

  @override
  List<Object?> get props => [heading];
}

class SearchAddress extends NavigationEvent {
  final String address;

  const SearchAddress(this.address);

  @override
  List<Object?> get props => [address];
}

class SelectSuggestion extends NavigationEvent {
  final String suggestion;

  const SelectSuggestion(this.suggestion);

  @override
  List<Object?> get props => [suggestion];
}

class FetchRoute extends NavigationEvent {}

class ToggleCompassMode extends NavigationEvent {}

class UpdateSuggestions extends NavigationEvent {
  final String input;

  const UpdateSuggestions(this.input);

  @override
  List<Object?> get props => [input];
}

class MapReady extends NavigationEvent {}

class PageLoaded extends NavigationEvent {}

class RouteLoadingChanged extends NavigationEvent {
  final bool isLoading;

  const RouteLoadingChanged(this.isLoading);

  @override
  List<Object?> get props => [isLoading];
}

class ErrorOccurred extends NavigationEvent {
  final String? error;

  const ErrorOccurred(this.error);

  @override
  List<Object?> get props => [error];
}

class RoutePointsUpdated extends NavigationEvent {
  final List<LatLng>? routePoints;

  const RoutePointsUpdated(this.routePoints);

  @override
  List<Object?> get props => [routePoints];
}

class InstructionsUpdated extends NavigationEvent {
  final List<dynamic> instructions;

  const InstructionsUpdated(this.instructions);

  @override
  List<Object?> get props => [instructions];
}

class DestinationPositionUpdated extends NavigationEvent {
  final LatLng? destinationPosition;

  const DestinationPositionUpdated(this.destinationPosition);

  @override
  List<Object?> get props => [destinationPosition];
}

class DangerZonesLoaded extends NavigationEvent {
  final List<fm.Polygon> dangerZonePolygons;

  const DangerZonesLoaded(this.dangerZonePolygons);

  @override
  List<Object?> get props => [dangerZonePolygons];
}

class DangerZoneMarkersUpdated extends NavigationEvent {
  final List<fm.Marker> dangerZoneMarkers;

  const DangerZoneMarkersUpdated(this.dangerZoneMarkers);

  @override
  List<Object?> get props => [dangerZoneMarkers];
}

class ShowSuggestionsChanged extends NavigationEvent {
  final bool showSuggestions;

  const ShowSuggestionsChanged(this.showSuggestions);

  @override
  List<Object?> get props => [showSuggestions];
}

class SuggestionsUpdated extends NavigationEvent {
  final List<String> suggestions;

  const SuggestionsUpdated(this.suggestions);

  @override
  List<Object?> get props => [suggestions];
}
