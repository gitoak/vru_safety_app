import 'package:latlong2/latlong.dart';
import '../entities/danger_zone.dart';

/// Repository interface for danger zone operations.
abstract class DangerZoneRepository {
  /// Fetches all danger zones from the data source.
  Future<List<DangerZone>> getAllDangerZones();

  /// Fetches danger zones within a specific radius of a location.
  Future<List<DangerZone>> getDangerZonesNearLocation({
    required LatLng location,
    required double radiusInMeters,
  });

  /// Fetches a specific danger zone by ID.
  Future<DangerZone?> getDangerZoneById(String id);

  /// Checks if a location is within any danger zone.
  Future<bool> isLocationInDangerZone(LatLng location);

  /// Gets all danger zones that contain the specified location.
  Future<List<DangerZone>> getDangerZonesContainingLocation(LatLng location);

  /// Updates the local cache of danger zones.
  Future<void> refreshDangerZones();

  /// Saves danger zones to local storage for offline access.
  Future<void> cacheDangerZones(List<DangerZone> dangerZones);

  /// Loads danger zones from local storage.
  Future<List<DangerZone>> getCachedDangerZones();
}
