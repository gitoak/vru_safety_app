import 'dart:async';
import 'package:latlong2/latlong.dart';
import '../../domain/entities/user_location.dart';
import '../../domain/repositories/location_repository.dart';
import '../services/location_service.dart';

/// Implementation of LocationRepository using LocationService.
class LocationRepositoryImpl implements LocationRepository {  final LocationService _locationService;
  StreamController<UserLocation>? _locationStreamController;
  UserLocation? _lastKnownLocation;
  LocationAccuracy _currentAccuracy = LocationAccuracy.high;
  Timer? _locationUpdateTimer;

  LocationRepositoryImpl({
    LocationService? locationService,
  }) : _locationService = locationService ?? LocationService();

  @override
  Future<UserLocation> getCurrentLocation() async {
    try {
      final position = await _locationService.getCurrentLocation();
        final userLocation = UserLocation(
        position: LatLng(position.latitude, position.longitude),
        accuracy: position.accuracy,
        timestamp: DateTime.now(),
        speed: position.speed,
        heading: position.heading,
      );

      _lastKnownLocation = userLocation;
      return userLocation;
    } catch (e) {
      throw Exception('Failed to get current location: $e');
    }
  }

  @override
  Stream<UserLocation> getLocationStream() {
    _locationStreamController ??= StreamController<UserLocation>.broadcast();
    
    // Start location updates
    _startLocationUpdates();
    
    return _locationStreamController!.stream;
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await _locationService.isLocationServiceEnabled();
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> requestLocationPermission() async {
    try {
      return await _locationService.requestLocationPermission();
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> hasLocationPermission() async {
    try {
      return await _locationService.hasLocationPermission();
    } catch (e) {
      return false;
    }
  }
  @override
  Future<double> calculateDistanceTo(LatLng target) async {
    try {
      final currentLocation = await getCurrentLocation();
      return _locationService.calculateDistance(
        currentLocation.position,
        target,
      );
    } catch (e) {
      throw Exception('Failed to calculate distance: $e');
    }
  }

  @override
  Future<UserLocation?> getLastKnownLocation() async {
    try {
      final position = await _locationService.getLastKnownLocation();
      if (position == null) return null;      return UserLocation(
        position: LatLng(position.latitude, position.longitude),
        accuracy: position.accuracy,
        timestamp: DateTime.now(),
        speed: position.speed,
        heading: position.heading,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> startLocationTracking({
    Duration updateInterval = const Duration(seconds: 5),
  }) async {
    try {
      await _locationService.startLocationUpdates();
      _startLocationUpdates(updateInterval: updateInterval);
    } catch (e) {
      throw Exception('Failed to start location tracking: $e');
    }
  }

  @override
  Future<void> stopLocationTracking() async {
    try {
      await _locationService.stopLocationUpdates();
      _stopLocationUpdates();
    } catch (e) {
      print('Error stopping location tracking: $e');
    }
  }

  @override
  Future<bool> isLocationAccurate({double requiredAccuracy = 10.0}) async {
    try {
      final location = await getCurrentLocation();
      return location.accuracy! <= requiredAccuracy;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> stopLocationStream() async {
    await _locationStreamController?.close();
    _locationStreamController = null;
  }

  @override
  Future<void> cacheLocation(UserLocation location) async {
    _lastKnownLocation = location;
  }

  @override
  Future<LocationAccuracy> getLocationAccuracy() async {
    return _currentAccuracy;
  }

  @override
  Future<void> setLocationAccuracy(LocationAccuracy accuracy) async {
    _currentAccuracy = accuracy;
  }

  /// Starts periodic location updates.
  void _startLocationUpdates({
    Duration updateInterval = const Duration(seconds: 5),
  }) {
    _locationUpdateTimer?.cancel();
    
    _locationUpdateTimer = Timer.periodic(updateInterval, (timer) async {
      try {
        final location = await getCurrentLocation();
        _locationStreamController?.add(location);
      } catch (e) {
        print('Error getting location update: $e');
      }
    });
  }

  /// Stops location updates.
  void _stopLocationUpdates() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
  }
  void dispose() {
    _stopLocationUpdates();
    _locationStreamController?.close();
    _locationStreamController = null;
  }
}
