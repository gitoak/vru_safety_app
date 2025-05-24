import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:vru_safety_app/bloc/navigation_event.dart';
import 'package:vru_safety_app/bloc/navigation_state.dart';
import 'package:vru_safety_app/services/location_service.dart';
import 'package:vru_safety_app/services/routing_service.dart';
import 'package:vru_safety_app/services/danger_zone_service.dart';
import 'package:vru_safety_app/utils/polyline_decoder.dart';

class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  final LocationService _locationService;
  final RoutingService _routingService;
  final DangerZoneService _dangerZoneService;

  NavigationBloc({
    required LocationService locationService,
    required RoutingService routingService,
    required DangerZoneService dangerZoneService,
  })  : _locationService = locationService,
        _routingService = routingService,
        _dangerZoneService = dangerZoneService,
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
    on<MapReady>(_onMapReady); // Added handler
  }

  Future<void> _onInitializeNavigation(
    InitializeNavigation event,
    Emitter<NavigationState> emit,
  ) async {
    emit(state.copyWith(pageLoading: true, error: null));
    await _locationService.initializeLocationAndCompass(
      onPositionUpdate: (position) => add(UpdateUserPosition(position)),
      onCompassUpdate: (heading) => add(UpdateCompassHeading(heading)),
      onError: (error) => add(ErrorOccurred(error)),
    );
    try {
      final dangerZones = await _dangerZoneService.loadDangerZones();
      add(DangerZonesLoaded(dangerZones));
      _updateDangerZoneMarkers(dangerZones, emit); // Pass emit here
      // Fetch initial route only after we have the first location
      if (state.userPosition != null) {
        await _fetchInitialRoute(emit);
      }
    } catch (e) {
      add(ErrorOccurred('Failed to load danger zones: $e'));
    }
    add(PageLoaded());
  }

  void _onMapReady(MapReady event, Emitter<NavigationState> emit) { // Added handler method
    emit(state.copyWith(isMapReady: true));
  }

  void _onUpdateUserPosition(
    UpdateUserPosition event,
    Emitter<NavigationState> emit,
  ) {
    emit(state.copyWith(userPosition: event.userPosition));
  }

  void _onUpdateCompassHeading(
    UpdateCompassHeading event,
    Emitter<NavigationState> emit,
  ) {
    emit(state.copyWith(compassHeading: event.heading));
  }

  Future<void> _onSearchAddress(
    SearchAddress event,
    Emitter<NavigationState> emit,
  ) async {
    if (state.userPosition == null) {
      add(ErrorOccurred("Current location not available. Cannot search for a route."));
      return;
    }
    add(RouteLoadingChanged(true));
    add(ErrorOccurred(null));
    add(RoutePointsUpdated(null));
    add(InstructionsUpdated([]));

    try {
      final destination = await _routingService.geocodeAddress(event.address);
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

  Future<void> _onSelectSuggestion(
    SelectSuggestion event,
    Emitter<NavigationState> emit,
  ) async {
    add(ShowSuggestionsChanged(false));
    add(SearchAddress(event.suggestion));
  }

  Future<void> _onFetchRoute(
    FetchRoute event,
    Emitter<NavigationState> emit,
  ) async {
    if (state.userPosition == null || state.destinationPosition == null) {
      add(ErrorOccurred("User location or destination not available."));
      return;
    }
    add(RouteLoadingChanged(true));
    await _fetchRouteInternal(state.userPosition!, state.destinationPosition!, emit);
    add(RouteLoadingChanged(false));
  }

  Future<void> _fetchInitialRoute(Emitter<NavigationState> emit) async {
    if (state.userPosition == null) {
      add(ErrorOccurred("User location not available to fetch initial route."));
      return;
    }
    // Default initial destination
    const initialDestination = LatLng(49.019, 12.102);
    add(DestinationPositionUpdated(initialDestination)); 
    await _fetchRouteInternal(state.userPosition!, initialDestination, emit);
  }

  Future<void> _fetchRouteInternal(
    LatLng start,
    LatLng end,
    Emitter<NavigationState> emit,
  ) async {
    try {
      final routeData = await _routingService.fetchRoute(start: start, end: end);
      final path = routeData['paths'][0];
      final points = path['points'];
      final decoded = decodePolyline(points);
      add(RoutePointsUpdated(decoded));
      add(InstructionsUpdated(path['instructions'] ?? []));
    } catch (e) {
      add(ErrorOccurred('Failed to fetch route: $e'));
    }
  }

  void _onToggleCompassMode(
    ToggleCompassMode event,
    Emitter<NavigationState> emit,
  ) {
    emit(state.copyWith(compassMode: !state.compassMode));
  }

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
      final suggestions = await _routingService.fetchSuggestions(event.input);
      add(SuggestionsUpdated(suggestions));
      add(ShowSuggestionsChanged(suggestions.isNotEmpty));
    } catch (e) {
      // Handle error, maybe show a message to the user
      debugPrint("Error fetching suggestions: $e");
    }
  }

  void _onPageLoaded(PageLoaded event, Emitter<NavigationState> emit) {
    emit(state.copyWith(pageLoading: false));
  }

  void _onRouteLoadingChanged(RouteLoadingChanged event, Emitter<NavigationState> emit) {
    emit(state.copyWith(routeLoading: event.isLoading));
  }

  void _onErrorOccurred(ErrorOccurred event, Emitter<NavigationState> emit) {
    emit(state.copyWith(error: event.error, status: NavigationStatus.error));
  }

  void _onRoutePointsUpdated(RoutePointsUpdated event, Emitter<NavigationState> emit) {
    emit(state.copyWith(routePoints: event.routePoints));
  }

  void _onInstructionsUpdated(InstructionsUpdated event, Emitter<NavigationState> emit) {
    emit(state.copyWith(instructions: event.instructions));
  }

  void _onDestinationPositionUpdated(DestinationPositionUpdated event, Emitter<NavigationState> emit) {
    emit(state.copyWith(destinationPosition: event.destinationPosition));
  }

  void _onDangerZonesLoaded(DangerZonesLoaded event, Emitter<NavigationState> emit) {
    emit(state.copyWith(dangerZonePolygons: event.dangerZonePolygons));
  }

  void _onDangerZoneMarkersUpdated(DangerZoneMarkersUpdated event, Emitter<NavigationState> emit) {
    emit(state.copyWith(dangerZoneMarkers: event.dangerZoneMarkers));
  }

  void _onShowSuggestionsChanged(ShowSuggestionsChanged event, Emitter<NavigationState> emit) {
    emit(state.copyWith(showSuggestions: event.showSuggestions));
  }

  void _onSuggestionsUpdated(SuggestionsUpdated event, Emitter<NavigationState> emit) {
    emit(state.copyWith(suggestions: event.suggestions));
  }

  void _updateDangerZoneMarkers(List<fm.Polygon> polygons, Emitter<NavigationState> emit) {
    final markers = polygons.map((polygon) {
      if (polygon.points.isEmpty) {
        // Return a dummy marker or handle as needed if points are empty
        return fm.Marker(point: const LatLng(0,0), builder: (_) => const SizedBox.shrink()); 
      }
      final center = polygon.points.reduce(
        (a, b) => LatLng(
          (a.latitude + b.latitude) / 2,
          (a.longitude + b.longitude) / 2,
        ),
      );
      return fm.Marker(
        point: center,
        builder: (ctx) => const Icon(Icons.warning, color: Colors.red, size: 30),
      );
    }).toList();
    add(DangerZoneMarkersUpdated(markers));
  }

  @override
  Future<void> close() {
    _locationService.dispose();
    return super.close();
  }
}
