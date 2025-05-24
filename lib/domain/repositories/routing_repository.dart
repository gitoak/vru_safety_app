import 'package:latlong2/latlong.dart';
import '../entities/route.dart';

/// Repository interface for routing operations.
abstract class RoutingRepository {
  /// Calculates a route between two points.
  Future<Route> calculateRoute({
    required LatLng start,
    required LatLng end,
    String profile = 'foot',
    String locale = 'en',
    bool includeInstructions = true,
  });

  /// Calculates multiple alternative routes.
  Future<List<Route>> calculateAlternativeRoutes({
    required LatLng start,
    required LatLng end,
    String profile = 'foot',
    String locale = 'en',
    int maxAlternatives = 3,
  });

  /// Calculates a route that avoids specified danger zones.
  Future<Route> calculateSafeRoute({
    required LatLng start,
    required LatLng end,
    required List<String> dangerZoneIds,
    String profile = 'foot',
    String locale = 'en',
  });

  /// Gets the estimated travel time between two points.
  Future<Duration> getEstimatedTravelTime({
    required LatLng start,
    required LatLng end,
    String profile = 'foot',
  });

  /// Validates if a route is accessible for the given profile.
  Future<bool> isRouteAccessible({
    required Route route,
    required String profile,
  });
  /// Gets nearby points of interest along a route.
  Future<List<LatLng>> getNearbyPOIs({
    required Route route,
    required double radiusInMeters,
    List<String> categories = const [],
  });

  /// Converts an address string to coordinates using geocoding.
  Future<LatLng?> geocodeAddress(String address);

  /// Fetches address suggestions based on user input.
  Future<List<String>> fetchSuggestions(String input);

  /// Fetches route data in raw format (for backward compatibility).
  Future<Map<String, dynamic>> fetchRoute({
    required LatLng start,
    required LatLng end,
  });
}
