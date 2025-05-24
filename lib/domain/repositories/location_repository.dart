import '../entities/user_location.dart';

/// Repository interface for location operations.
abstract class LocationRepository {
  /// Gets the current user location.
  Future<UserLocation> getCurrentLocation();

  /// Starts listening to location updates.
  Stream<UserLocation> getLocationStream();

  /// Stops listening to location updates.
  Future<void> stopLocationStream();

  /// Checks if location permissions are granted.
  Future<bool> hasLocationPermission();

  /// Requests location permissions from the user.
  Future<bool> requestLocationPermission();

  /// Checks if location services are enabled.
  Future<bool> isLocationServiceEnabled();

  /// Gets the last known location from cache.
  Future<UserLocation?> getLastKnownLocation();

  /// Saves the current location to cache.
  Future<void> cacheLocation(UserLocation location);

  /// Gets location accuracy settings.
  Future<LocationAccuracy> getLocationAccuracy();

  /// Sets location accuracy settings.
  Future<void> setLocationAccuracy(LocationAccuracy accuracy);
}

/// Enumeration of location accuracy levels.
enum LocationAccuracy {
  lowest,
  low,
  medium,
  high,
  best,
}
