import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter/painting.dart'; // Added import for Color
import '../services/nominatim_api_service.dart';
import '../services/graphhopper_api_service.dart';
import 'navigation_event_state.dart'; // Assuming your events and states are in this file

class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  final NominatimApiService _nominatimApiService;
  final GraphHopperApiService _graphHopperApiService;
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<CompassEvent>? _compassSubscription;

  NavigationBloc({
    required NominatimApiService nominatimApiService,
    required GraphHopperApiService graphHopperApiService,
  })  : _nominatimApiService = nominatimApiService,
        _graphHopperApiService = graphHopperApiService,
        super(NavigationInitial()) {
    on<InitializeNavigationRequested>(_onInitializeNavigationRequested);
    on<SearchRouteRequested>(_onSearchRouteRequested);
    on<UserPositionUpdated>(_onUserPositionUpdated);
    on<UserHeadingUpdated>(_onUserHeadingUpdated);
    on<AddressSuggestionsRequested>(_onAddressSuggestionsRequested);
    on<AddressSuggestionSelected>(_onAddressSuggestionSelected);
  }

  Future<void> _onInitializeNavigationRequested(
    InitializeNavigationRequested event, Emitter<NavigationState> emit) async {
    emit(NavigationLoadInProgress());
    try {
      // Initialize location services and get initial position
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        emit(const NavigationLoadFailure('Location services are disabled. Please enable them.'));
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          emit(const NavigationLoadFailure('Location permissions are denied.'));
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        emit(const NavigationLoadFailure('Location permissions are permanently denied.'));
        return;
      }

      Position initialPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final userPosition = LatLng(initialPosition.latitude, initialPosition.longitude);

      // Start listening to position and compass updates
      _positionStreamSubscription?.cancel();
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5),
      ).listen((position) {
        add(UserPositionUpdated(position));
      });

      _compassSubscription?.cancel();
      _compassSubscription = FlutterCompass.events?.listen((event) {
        add(UserHeadingUpdated(event.heading ?? 0.0));
      });
      
      // Load danger zones (simplified, replace with actual logic)
      final dangerZones = _loadFallbackDangerZones(); 

      // Fetch initial route (optional, can be triggered by UI)
      // For now, emitting success state without initial route
      emit(NavigationLoadSuccess(
        userPosition: userPosition,
        dangerZonePolygons: dangerZones,
      ));

    } catch (e) {
      emit(NavigationLoadFailure('Error initializing navigation: $e'));
    }
  }

  Future<void> _onSearchRouteRequested(SearchRouteRequested event, Emitter<NavigationState> emit) async {
    if (state is! NavigationLoadSuccess) return; // Ensure we have a user position
    final currentState = state as NavigationLoadSuccess;

    emit(NavigationRouteSearchInProgress());
    try {
      final address = event.address.trim();
      if (address.isEmpty) {
        emit(const NavigationLoadFailure('Please enter a destination address.'));
        // Re-emit previous success state to keep UI consistent
        emit(currentState.copyWith(currentAddressText: address)); 
        return;
      }

      final destination = await _nominatimApiService.geocodeAddress(address);
      if (destination == null) {
        emit(const NavigationLoadFailure('Address not found.'));
        emit(currentState.copyWith(currentAddressText: address));
        return;
      }

      final routeData = await _graphHopperApiService.fetchRoute(
        start: currentState.userPosition,
        end: destination,
      );

      emit(currentState.copyWith(
        routePoints: routeData['points'] as List<LatLng>?,
        instructions: routeData['instructions'] as List<dynamic>? ?? [],
        destinationPosition: destination,
        currentAddressText: address, // Keep the searched address
        showSuggestions: false, // Hide suggestions after search
      ));
    } catch (e) {
      emit(NavigationLoadFailure('Error searching route: $e'));
      emit(currentState); // Revert to previous success state on error
    }
  }

  void _onUserPositionUpdated(UserPositionUpdated event, Emitter<NavigationState> emit) {
    if (state is NavigationLoadSuccess) {
      final currentState = state as NavigationLoadSuccess;
      final newPosition = LatLng(event.position.latitude, event.position.longitude);
      emit(currentState.copyWith(userPosition: newPosition));
      // Optionally, re-fetch route if user deviates significantly
    }
  }

  void _onUserHeadingUpdated(UserHeadingUpdated event, Emitter<NavigationState> emit) {
    if (state is NavigationLoadSuccess) {
      final currentState = state as NavigationLoadSuccess;
      emit(currentState.copyWith(userHeading: event.heading));
    }
  }

  Future<void> _onAddressSuggestionsRequested(AddressSuggestionsRequested event, Emitter<NavigationState> emit) async {
    if (state is! NavigationLoadSuccess) return;
    final currentState = state as NavigationLoadSuccess;

    if (event.input.isEmpty) {
      emit(currentState.copyWith(suggestions: [], showSuggestions: false, currentAddressText: event.input));
      return;
    }
    try {
      final suggestions = await _nominatimApiService.fetchSuggestions(event.input);
      emit(currentState.copyWith(
        suggestions: suggestions,
        showSuggestions: suggestions.isNotEmpty,
        currentAddressText: event.input,
      ));
    } catch (e) {
      // Handle error, maybe log it or show a generic error
      emit(currentState.copyWith(suggestions: [], showSuggestions: false, currentAddressText: event.input));
    }
  }

  void _onAddressSuggestionSelected(AddressSuggestionSelected event, Emitter<NavigationState> emit) {
     if (state is! NavigationLoadSuccess) return;
    final currentState = state as NavigationLoadSuccess;
    // Trigger a new search with the selected suggestion
    // The SearchRouteRequested handler will update the state
    add(SearchRouteRequested(event.suggestion));
    // Update currentAddressText immediately and hide suggestions
    emit(currentState.copyWith(currentAddressText: event.suggestion, showSuggestions: false));
  }

  // Placeholder for danger zone loading logic
  List<fm.Polygon> _loadFallbackDangerZones() {
    return [
      fm.Polygon(
        points: [
          const LatLng(49.010, 12.098),
          const LatLng(49.019, 12.098),
          const LatLng(49.019, 12.102),
          const LatLng(49.010, 12.102),
        ],
        color: const Color(0x4DFF0000), // Colors.red.withOpacity(0.3)
        borderColor: const Color(0xFFFF0000), // Colors.red
        borderStrokeWidth: 2.0,
      ),
    ];
  }

  @override
  Future<void> close() {
    _positionStreamSubscription?.cancel();
    _compassSubscription?.cancel();
    return super.close();
  }
}
