import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import '../../../domain/repositories/location_repository.dart';
import '../../../domain/repositories/routing_repository.dart';
import '../../../domain/repositories/danger_zone_repository.dart';
import '../../../core/utils/polyline_decoder.dart';
import 'navigation_event.dart';
import 'navigation_state.dart';

/// BLoC responsible for handling navigation, routing, and danger zone logic.
class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  /// Repository for location updates and compass readings.
  final LocationRepository _locationRepository;

  /// Repository for route fetching and calculations.
  final RoutingRepository _routingRepository;

  /// Repository for loading and managing danger zones.
  final DangerZoneRepository _dangerZoneRepository;

  NavigationBloc({
    required LocationRepository locationRepository,
    required RoutingRepository routingRepository,
    required DangerZoneRepository dangerZoneRepository,
  }) : _locationRepository = locationRepository,
       _routingRepository = routingRepository,
       _dangerZoneRepository = dangerZoneRepository,
       super(const NavigationState()) {
    on<InitializeNavigation>(_onInitializeNavigation);
    on<UpdateUserPosition>(_onUpdateUserPosition);
    on<UpdateCompassHeading>(_onUpdateCompassHeading);
    on<SearchAddress>(_onSearchAddress);
    on<SelectSuggestion>(_onSelectSuggestion);
    on<FetchRoute>(_onFetchRoute);
    on<ToggleCompassMode>(_onToggleCompassMode);
    on<UpdateSuggestions>(_onUpdateSuggestions);
    on<PageLoaded>(_onPageLoaded);
    on<RouteLoadingChanged>(_onRouteLoadingChanged);
    on<ErrorOccurred>(_onErrorOccurred);
    on<RoutePointsUpdated>(_onRoutePointsUpdated);
    on<InstructionsUpdated>(_onInstructionsUpdated);
    on<DestinationPositionUpdated>(_onDestinationPositionUpdated);
    on<DangerZonesLoaded>(_onDangerZonesLoaded);
    on<DangerZoneMarkersUpdated>(_onDangerZoneMarkersUpdated);
    on<ShowSuggestionsChanged>(_onShowSuggestionsChanged);
    on<SuggestionsUpdated>(_onSuggestionsUpdated);
    on<MapReady>(_onMapReady);
  }  /// Initializes navigation system, location listeners, and danger zones.
  Future<void> _onInitializeNavigation(
    InitializeNavigation event,
    Emitter<NavigationState> emit,
  ) async {
    emit(state.copyWith(pageLoading: true, error: null));
    
    // Start location stream
    _locationRepository.getLocationStream().listen(
      (location) => add(UpdateUserPosition(LatLng(location.position.latitude, location.position.longitude))),
      onError: (error) => add(ErrorOccurred(error.toString())),
    );
    
    try {
      final dangerZones = await _dangerZoneRepository.getAllDangerZones();
      add(DangerZonesLoaded(dangerZones));

      if (state.userPosition != null) {
        await _fetchInitialRoute(emit);
      }
    } catch (e) {
      add(ErrorOccurred('Failed to load danger zones: $e'));
    }
    add(PageLoaded());
  }

  /// Sets state indicating the map is ready for interaction.
  void _onMapReady(MapReady event, Emitter<NavigationState> emit) {
    emit(state.copyWith(isMapReady: true));
  }

  /// Updates state with new user position.
  void _onUpdateUserPosition(
    UpdateUserPosition event,
    Emitter<NavigationState> emit,
  ) {
    emit(state.copyWith(userPosition: event.userPosition));
  }

  /// Updates state with new compass heading.
  void _onUpdateCompassHeading(
    UpdateCompassHeading event,
    Emitter<NavigationState> emit,
  ) {
    emit(state.copyWith(compassHeading: event.heading));
  }
  /// Handles address search, geocoding, and route fetching to result.
  Future<void> _onSearchAddress(
    SearchAddress event,
    Emitter<NavigationState> emit,
  ) async {
    if (state.userPosition == null) {
      add(
        ErrorOccurred(
          "Current location not available. Cannot search for a route.",
        ),
      );
      return;
    }
    add(RouteLoadingChanged(true));
    add(ErrorOccurred(null));
    add(RoutePointsUpdated(null));
    add(InstructionsUpdated([]));

    try {
      final destination = await _routingRepository.geocodeAddress(event.address);
      if (destination == null) {
        add(ErrorOccurred('Address not found.'));
        add(RouteLoadingChanged(false));
        return;
      }
      add(DestinationPositionUpdated(destination));
      await _fetchRouteInternal(state.userPosition!, destination, emit);
    } catch (e) {
      add(ErrorOccurred('Error: $e'));
    }
    add(RouteLoadingChanged(false));
  }
  /// Handles selection of a suggestion (auto-completes search).
  Future<void> _onSelectSuggestion(
    SelectSuggestion event,
    Emitter<NavigationState> emit,
  ) async {
    if (state.userPosition == null) {
      add(ErrorOccurred("Current location not available."));
      return;
    }

    add(ShowSuggestionsChanged(false));
    add(RouteLoadingChanged(true));
    add(ErrorOccurred(null));
    add(RoutePointsUpdated(null));
    add(InstructionsUpdated([]));

    try {
      final destination = await _routingRepository.geocodeAddress(event.suggestion);
      if (destination == null) {
        add(ErrorOccurred('Could not find the selected address.'));
        add(RouteLoadingChanged(false));
        return;
      }
      add(DestinationPositionUpdated(destination));
      await _fetchRouteInternal(state.userPosition!, destination, emit);
    } catch (e) {
      add(ErrorOccurred('Error: $e'));
    }
    add(RouteLoadingChanged(false));
  }

  /// Handles route fetching when location and destination are known.
  Future<void> _onFetchRoute(FetchRoute event, Emitter<NavigationState> emit) async {
    if (state.userPosition == null) {
      add(ErrorOccurred("Current location not available."));
      return;
    }
    final initialDestination = LatLng(event.destinationLat, event.destinationLng);
    add(DestinationPositionUpdated(initialDestination));
    await _fetchRouteInternal(state.userPosition!, initialDestination, emit);
  }
  /// Fetches route data between [start] and [end] and updates state.
  Future<void> _fetchRouteInternal(
    LatLng start,
    LatLng end,
    Emitter<NavigationState> emit,
  ) async {
    try {
      final routeData = await _routingRepository.fetchRoute(
        start: start,
        end: end,
      );
      final path = routeData['paths'][0];
      final points = path['points'];
      final decoded = decodePolyline(points);
      add(RoutePointsUpdated(decoded));
      add(InstructionsUpdated(path['instructions'] ?? []));
    } catch (e) {
      add(ErrorOccurred('Failed to fetch route: $e'));
    }
  }

  /// Toggles compass mode for navigation.
  void _onToggleCompassMode(
    ToggleCompassMode event,
    Emitter<NavigationState> emit,
  ) {
    emit(state.copyWith(compassMode: !state.compassMode));
  }

  /// Attempts to fetch initial route based on current location.
  Future<void> _fetchInitialRoute(Emitter<NavigationState> emit) async {
    // Placeholder logic for initial route
  }
  /// Updates address suggestions based on user input.
  Future<void> _onUpdateSuggestions(
    UpdateSuggestions event,
    Emitter<NavigationState> emit,
  ) async {
    if (event.input.isEmpty) {
      add(SuggestionsUpdated([]));
      add(ShowSuggestionsChanged(false));
      return;
    }
    try {
      final suggestions = await _routingRepository.fetchSuggestions(event.input);
      add(SuggestionsUpdated(suggestions));
      add(ShowSuggestionsChanged(suggestions.isNotEmpty));
    } catch (e) {
      debugPrint("Error fetching suggestions: $e");
    }
  }

  /// Marks that the page has finished loading.
  void _onPageLoaded(PageLoaded event, Emitter<NavigationState> emit) {
    emit(state.copyWith(pageLoading: false));
  }

  /// Updates route loading state.
  void _onRouteLoadingChanged(
    RouteLoadingChanged event,
    Emitter<NavigationState> emit,
  ) {
    emit(state.copyWith(routeLoading: event.isLoading));
  }

  /// Sets an error state with message.
  void _onErrorOccurred(ErrorOccurred event, Emitter<NavigationState> emit) {
    emit(state.copyWith(error: event.error, status: NavigationStatus.error));
  }

  /// Updates state with new route points for display.
  void _onRoutePointsUpdated(
    RoutePointsUpdated event,
    Emitter<NavigationState> emit,
  ) {
    emit(state.copyWith(routePoints: event.routePoints));
  }

  /// Updates navigation instructions.
  void _onInstructionsUpdated(
    InstructionsUpdated event,
    Emitter<NavigationState> emit,
  ) {
    emit(state.copyWith(instructions: event.instructions));
  }

  /// Updates selected destination position.
  void _onDestinationPositionUpdated(
    DestinationPositionUpdated event,
    Emitter<NavigationState> emit,
  ) {
    emit(state.copyWith(destinationPosition: event.destinationPosition));
  }

  /// Loads danger zone polygons into state.
  void _onDangerZonesLoaded(
    DangerZonesLoaded event,
    Emitter<NavigationState> emit,
  ) {
    emit(state.copyWith(dangerZonePolygons: event.dangerZonePolygons));
  }

  /// Updates state with new danger zone markers for the map.
  void _onDangerZoneMarkersUpdated(
    DangerZoneMarkersUpdated event,
    Emitter<NavigationState> emit,
  ) {
    emit(state.copyWith(dangerZoneMarkers: event.dangerZoneMarkers));
  }

  /// Updates whether address suggestions should be shown.
  void _onShowSuggestionsChanged(
    ShowSuggestionsChanged event,
    Emitter<NavigationState> emit,
  ) {
    emit(state.copyWith(showSuggestions: event.showSuggestions));
  }

  /// Updates suggestions in the UI.
  void _onSuggestionsUpdated(
    SuggestionsUpdated event,
    Emitter<NavigationState> emit,
  ) {
    emit(state.copyWith(suggestions: event.suggestions));
  }
  @override
  /// Disposes of resources when bloc is closed.
  Future<void> close() {
    _locationRepository.stopLocationStream();
    return super.close();
  }
}
