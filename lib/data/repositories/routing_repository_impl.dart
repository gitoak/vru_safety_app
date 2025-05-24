import 'package:latlong2/latlong.dart';
import '../../domain/entities/route.dart' as domain;
import '../../domain/repositories/routing_repository.dart';
import '../services/graphhopper_api_service.dart';
import '../services/routing_service.dart';

/// Implementation of RoutingRepository using GraphHopper API and local routing service.
class RoutingRepositoryImpl implements RoutingRepository {
  final GraphHopperApiService _apiService;
  final RoutingService _routingService;

  RoutingRepositoryImpl({
    GraphHopperApiService? apiService,
    RoutingService? routingService,
  }) : _apiService = apiService ?? GraphHopperApiService(),
        _routingService = routingService ?? RoutingService();

  @override
  Future<domain.Route> calculateRoute({
    required LatLng start,
    required LatLng end,
    String profile = 'foot',
    String locale = 'en',
    bool includeInstructions = true,
  }) async {
    try {
      // Use GraphHopper API for route calculation
      final routeData = await _apiService.getRoute(
        start: start,
        end: end,
        profile: profile,
      );

      return _mapApiDataToRoute(routeData, profile);
    } catch (e) {
      throw Exception('Failed to calculate route: $e');
    }
  }

  @override
  Future<List<domain.Route>> calculateAlternativeRoutes({
    required LatLng start,
    required LatLng end,
    String profile = 'foot',
    String locale = 'en',
    int maxAlternatives = 3,
  }) async {
    try {
      // Get alternative routes from GraphHopper
      final routes = <domain.Route>[];
      
      // Main route
      final mainRoute = await calculateRoute(
        start: start,
        end: end,
        profile: profile,
        locale: locale,
      );
      routes.add(mainRoute);

      // Try to get alternatives (GraphHopper API supports this)
      try {
        final alternativeData = await _apiService.getAlternativeRoutes(
          start: start,
          end: end,
          profile: profile,
          maxAlternatives: maxAlternatives - 1,
        );

        for (final altData in alternativeData) {
          routes.add(_mapApiDataToRoute(altData, profile));
        }
      } catch (e) {
        // If alternatives fail, just return the main route
        print('Failed to get alternative routes: $e');
      }

      return routes;
    } catch (e) {
      throw Exception('Failed to calculate alternative routes: $e');
    }
  }

  @override
  Future<domain.Route> calculateSafeRoute({
    required LatLng start,
    required LatLng end,
    required List<String> dangerZoneIds,
    String profile = 'foot',
    String locale = 'en',
  }) async {
    try {
      // Use routing service for safety optimization
      // Note: This is a simplified implementation
      return await calculateRoute(
        start: start,
        end: end,
        profile: profile,
        locale: locale,
      );
    } catch (e) {
      throw Exception('Failed to calculate safe route: $e');
    }
  }

  @override
  Future<Duration> getEstimatedTravelTime({
    required LatLng start,
    required LatLng end,
    String profile = 'foot',
  }) async {
    try {
      final route = await calculateRoute(
        start: start,
        end: end,
        profile: profile,
      );
      return Duration(milliseconds: route.totalTime);
    } catch (e) {
      throw Exception('Failed to get estimated travel time: $e');
    }
  }

  @override
  Future<bool> isRouteAccessible({
    required domain.Route route,
    required String profile,
  }) async {
    // Simplified implementation - assume all routes are accessible
    return true;
  }

  @override
  Future<List<LatLng>> getNearbyPOIs({
    required domain.Route route,
    required double radiusInMeters,
    List<String> categories = const [],
  }) async {
    // Simplified implementation - return empty list
    return [];
  }

  @override
  Future<LatLng?> geocodeAddress(String address) async {
    try {
      return await _routingService.geocodeAddress(address);
    } catch (e) {
      throw Exception('Failed to geocode address: $e');
    }
  }

  @override
  Future<List<String>> fetchSuggestions(String input) async {
    try {
      return await _routingService.fetchSuggestions(input);
    } catch (e) {
      throw Exception('Failed to fetch suggestions: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> fetchRoute({
    required LatLng start,
    required LatLng end,
  }) async {
    try {
      return await _routingService.fetchRoute(start: start, end: end);
    } catch (e) {
      throw Exception('Failed to fetch route: $e');
    }
  }

  /// Maps API response data to domain Route entity.
  domain.Route _mapApiDataToRoute(
    Map<String, dynamic> apiData,
    String profile,
  ) {
    final paths = apiData['paths'] as List? ?? [];
    if (paths.isEmpty) {
      throw Exception('No route found in API response');
    }

    final firstPath = paths.first as Map<String, dynamic>;
    
    // Extract polyline points
    final coordinates = <LatLng>[];
    final points = firstPath['points'] as Map<String, dynamic>?;
    if (points != null && points['coordinates'] != null) {
      final coordList = points['coordinates'] as List;
      for (final coord in coordList) {
        if (coord is List && coord.length >= 2) {
          // GraphHopper returns [longitude, latitude]
          coordinates.add(LatLng(coord[1].toDouble(), coord[0].toDouble()));
        }
      }
    }

    // Extract instructions
    final instructions = <domain.RouteInstruction>[];
    final instructionList = firstPath['instructions'] as List? ?? [];
    for (final instruction in instructionList) {
      if (instruction is Map<String, dynamic>) {
        instructions.add(domain.RouteInstruction(
          text: instruction['text']?.toString() ?? '',
          distance: (instruction['distance'] as num?)?.toDouble() ?? 0.0,
          time: (instruction['time'] as num?)?.toInt() ?? 0,
          sign: (instruction['sign'] as num?)?.toInt() ?? 0,
          interval: (instruction['interval'] as List?)?.cast<int>() ?? [],
          coordinate: null, // Can be added if available in API response
        ));
      }
    }

    return domain.Route(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      points: coordinates,
      instructions: instructions,
      totalDistance: (firstPath['distance'] as num?)?.toDouble() ?? 0.0,
      totalTime: (firstPath['time'] as num?)?.toInt() ?? 0,
      profile: profile,
      ascend: (firstPath['ascend'] as num?)?.toDouble() ?? 0.0,
      descend: (firstPath['descend'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
