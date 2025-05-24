import 'package:latlong2/latlong.dart';
import '../../domain/entities/danger_zone.dart';
import '../../domain/repositories/danger_zone_repository.dart';
import '../services/danger_zone_api_service.dart';

/// Implementation of DangerZoneRepository using API and local storage.
class DangerZoneRepositoryImpl implements DangerZoneRepository {
  final DangerZoneApiService _apiService;
  List<DangerZone> _cachedDangerZones = [];

  DangerZoneRepositoryImpl({
    DangerZoneApiService? apiService,
  }) : _apiService = apiService ?? DangerZoneApiService();

  @override
  Future<List<DangerZone>> getAllDangerZones() async {
    try {
      // Try to fetch from API first
      final apiData = await _apiService.fetchDangerZones();
      _cachedDangerZones = _mapApiDataToDangerZones(apiData);
      await cacheDangerZones(_cachedDangerZones);
      return _cachedDangerZones;
    } catch (e) {
      // Fall back to cached data if API fails
      return getCachedDangerZones();
    }
  }

  @override
  Future<List<DangerZone>> getDangerZonesNearLocation({
    required LatLng location,
    required double radiusInMeters,
  }) async {
    final allZones = await getAllDangerZones();
    return allZones.where((zone) {
      // Check if any point in the zone polygon is within radius
      return zone.polygon.any((point) {
        final distance = calculateDistance(location, point);
        return distance <= radiusInMeters;
      });
    }).toList();
  }

  @override
  Future<DangerZone?> getDangerZoneById(String id) async {
    final allZones = await getAllDangerZones();
    try {
      return allZones.firstWhere((zone) => zone.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> isLocationInDangerZone(LatLng location) async {
    final zones = await getDangerZonesContainingLocation(location);
    return zones.isNotEmpty;
  }

  @override
  Future<List<DangerZone>> getDangerZonesContainingLocation(LatLng location) async {
    final allZones = await getAllDangerZones();
    return allZones.where((zone) {
      return isPointInPolygon(location, zone.polygon);
    }).toList();
  }

  @override
  Future<void> refreshDangerZones() async {
    _cachedDangerZones.clear();
    await getAllDangerZones();
  }

  @override
  Future<void> cacheDangerZones(List<DangerZone> dangerZones) async {
    // In a real implementation, this would save to local storage
    // For now, just keep in memory
    _cachedDangerZones = dangerZones;
  }

  @override
  Future<List<DangerZone>> getCachedDangerZones() async {
    // In a real implementation, this would load from local storage
    return _cachedDangerZones;
  }

  /// Maps API response data to DangerZone entities.
  List<DangerZone> _mapApiDataToDangerZones(dynamic apiData) {
    // This would depend on the actual API response format
    // For now, return empty list
    return [];
  }

  /// Calculates distance between two points in meters.
  double calculateDistance(LatLng point1, LatLng point2) {
    // Simple distance calculation - in production use more accurate formula
    const double earthRadius = 6371000; // meters
    final double lat1Rad = point1.latitude * (3.14159 / 180);
    final double lat2Rad = point2.latitude * (3.14159 / 180);
    final double deltaLatRad = (point2.latitude - point1.latitude) * (3.14159 / 180);
    final double deltaLngRad = (point2.longitude - point1.longitude) * (3.14159 / 180);

    final double a = (deltaLatRad / 2).sin() * (deltaLatRad / 2).sin() +
        lat1Rad.cos() * lat2Rad.cos() *
        (deltaLngRad / 2).sin() * (deltaLngRad / 2).sin();
    final double c = 2 * a.sqrt().asin();

    return earthRadius * c;
  }
}
