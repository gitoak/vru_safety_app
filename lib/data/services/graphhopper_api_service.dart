import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/polyline_decoder.dart';

/// Unified service for GraphHopper API routing functionality.
/// Consolidates previous GraphHopperApiService and GraphHopperApiManager.
class GraphHopperApiService {
  final String? _apiKey;

  GraphHopperApiService({String? apiKey}) : _apiKey = apiKey;

  /// Fetches a route between two points using GraphHopper API.
  /// 
  /// Returns a map containing:
  /// - 'points': List of decoded LatLng points for the route
  /// - 'instructions': List of turn-by-turn instructions
  /// - 'distance': Total distance in meters
  /// - 'time': Total time in milliseconds
  Future<Map<String, dynamic>> fetchRoute({
    required LatLng start,
    required LatLng end,
    String profile = 'foot',
    String locale = 'en',
    bool instructions = true,
    bool calcPoints = true,
  }) async {
    try {
      final uri = _buildRouteUri(
        start: start,
        end: end,
        profile: profile,
        locale: locale,
        instructions: instructions,
        calcPoints: calcPoints,
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _processRouteResponse(data);
      } else {
        throw GraphHopperException(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is GraphHopperException) rethrow;
      throw GraphHopperException('Failed to fetch route: $e');
    }
  }

  /// Builds the URI for the GraphHopper route request.
  Uri _buildRouteUri({
    required LatLng start,
    required LatLng end,
    required String profile,
    required String locale,
    required bool instructions,
    required bool calcPoints,
  }) {
    final queryParams = <String, String>{
      'point': '${start.latitude},${start.longitude}',
      'point': '${end.latitude},${end.longitude}',
      'profile': profile,
      'locale': locale,
      'instructions': instructions.toString(),
      'calc_points': calcPoints.toString(),
    };

    if (_apiKey != null && _apiKey!.isNotEmpty) {
      queryParams['key'] = _apiKey!;
    }

    return Uri.parse(AppConstants.graphHopperBaseUrl)
        .resolve('/route')
        .replace(queryParameters: queryParams);
  }

  /// Processes the GraphHopper API response and extracts route data.
  Map<String, dynamic> _processRouteResponse(Map<String, dynamic> data) {
    if (data['paths'] == null || (data['paths'] as List).isEmpty) {
      throw GraphHopperException('No paths found in GraphHopper response');
    }

    final path = data['paths'][0] as Map<String, dynamic>;
    final result = <String, dynamic>{};

    // Extract route points
    if (path['points'] != null) {
      final points = path['points'] as String;
      result['points'] = decodePolyline(points);
    } else {
      result['points'] = <LatLng>[];
    }

    // Extract instructions
    result['instructions'] = path['instructions'] as List<dynamic>? ?? [];

    // Extract distance and time
    result['distance'] = path['distance'] as num? ?? 0;
    result['time'] = path['time'] as num? ?? 0;

    // Extract additional metadata
    result['bbox'] = path['bbox'] as List<dynamic>?;
    result['ascend'] = path['ascend'] as num? ?? 0;
    result['descend'] = path['descend'] as num? ?? 0;

    return result;
  }
  /// Gets route information between two points.
  /// Simplified version that returns the raw response.
  Future<Map<String, dynamic>> getRoute({
    required LatLng start,
    required LatLng end,
    String profile = 'foot',
  }) async {
    return fetchRoute(start: start, end: end, profile: profile);
  }

  /// Gets alternative routes between two points.
  Future<List<Map<String, dynamic>>> getAlternativeRoutes({
    required LatLng start,
    required LatLng end,
    String profile = 'foot',
    int maxAlternatives = 3,
  }) async {
    try {
      final uri = _buildAlternativeRoutesUri(
        start: start,
        end: end,
        profile: profile,
        maxAlternatives: maxAlternatives,
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        
        if (data['paths'] == null) {
          throw GraphHopperException('No paths found in GraphHopper response');
        }

        final paths = data['paths'] as List;
        final alternatives = <Map<String, dynamic>>[];

        // Skip the first path (main route) and process alternatives
        for (int i = 1; i < paths.length && i <= maxAlternatives; i++) {
          final path = paths[i] as Map<String, dynamic>;
          alternatives.add(_processAlternativeRoute(path));
        }

        return alternatives;
      } else {
        throw GraphHopperException(
          'Failed to fetch alternative routes: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is GraphHopperException) rethrow;
      throw GraphHopperException('Error getting alternative routes: $e');
    }
  }

  /// Builds URI for alternative routes request.
  Uri _buildAlternativeRoutesUri({
    required LatLng start,
    required LatLng end,
    required String profile,
    required int maxAlternatives,
  }) {
    final queryParams = <String, String>{
      'point': '${start.latitude},${start.longitude}',
      'point': '${end.latitude},${end.longitude}',
      'profile': profile,
      'instructions': 'true',
      'calc_points': 'true',
      'alternative_route.max_paths': (maxAlternatives + 1).toString(),
      'alternative_route.max_weight_factor': '1.4',
      'alternative_route.max_share_factor': '0.6',
    };

    if (_apiKey != null && _apiKey!.isNotEmpty) {
      queryParams['key'] = _apiKey!;
    }

    return Uri.parse(AppConstants.graphHopperBaseUrl)
        .resolve('/route')
        .replace(queryParameters: queryParams);
  }

  /// Processes an alternative route from the API response.
  Map<String, dynamic> _processAlternativeRoute(Map<String, dynamic> path) {
    final result = <String, dynamic>{};

    // Extract route points
    if (path['points'] != null) {
      final points = path['points'] as String;
      result['points'] = decodePolyline(points);
    } else {
      result['points'] = <LatLng>[];
    }

    // Extract instructions
    result['instructions'] = path['instructions'] as List<dynamic>? ?? [];

    // Extract distance and time
    result['distance'] = path['distance'] as num? ?? 0;
    result['time'] = path['time'] as num? ?? 0;

    // Extract additional metadata
    result['bbox'] = path['bbox'] as List<dynamic>?;
    result['ascend'] = path['ascend'] as num? ?? 0;
    result['descend'] = path['descend'] as num? ?? 0;

    return result;
  }
}

/// Exception thrown by GraphHopper API operations.
class GraphHopperException implements Exception {
  final String message;
  final int? statusCode;

  const GraphHopperException(this.message, {this.statusCode});

  @override
  String toString() => 'GraphHopperException: $message';
}
