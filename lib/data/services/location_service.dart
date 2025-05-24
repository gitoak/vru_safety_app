import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Simple LocationService implementation for use with LocationRepository.
/// Provides basic location functionality using the Geolocator package.
class LocationService {
  /// Gets the current position of the device.
  Future<Position> getCurrentLocation() async {
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Checks if location services are enabled on the device.
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Requests location permissions from the user.
  Future<bool> requestLocationPermission() async {
    final permission = await Geolocator.requestPermission();
    return permission == LocationPermission.always ||
           permission == LocationPermission.whileInUse;
  }

  /// Checks if the app has location permissions.
  Future<bool> hasLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
           permission == LocationPermission.whileInUse;
  }

  /// Calculates the distance between two coordinates in meters.
  double calculateDistance(LatLng from, LatLng to) {
    return Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
  }

  /// Gets the last known location of the device.
  Future<Position?> getLastKnownLocation() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (e) {
      return null;
    }
  }

  /// Starts location updates (placeholder implementation).
  Future<void> startLocationUpdates() async {
    // This would typically start a location stream
    // For now, this is a placeholder
  }

  /// Stops location updates (placeholder implementation).
  Future<void> stopLocationUpdates() async {
    // This would typically stop a location stream
    // For now, this is a placeholder
  }
}
