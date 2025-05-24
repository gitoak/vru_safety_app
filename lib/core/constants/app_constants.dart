/// Application-wide constants and configuration values.
class AppConstants {
  /// Base URL for the Nominatim geocoding service.
  static const String nominatimBaseUrl = 'https://nominatim.openstreetmap.org';
  
  /// Base URL for the GraphHopper routing service.
  static const String graphHopperBaseUrl = 'https://graphhopper.jannik.dev';
  
  /// Application name displayed in UI.
  static const String appName = 'VRU Safety App';
  
  /// Application version.
  static const String appVersion = '1.0.0';
  
  /// Default zoom level for the map.
  static const double defaultMapZoom = 15.0;
  
  /// Maximum zoom level for the map.
  static const double maxMapZoom = 18.0;
  
  /// Minimum zoom level for the map.
  static const double minMapZoom = 3.0;
  
  /// Timeout duration for API requests in seconds.
  static const int apiTimeoutSeconds = 30;
  
  /// Maximum number of address suggestions to show.
  static const int maxAddressSuggestions = 5;
  
  /// Distance filter for location updates in meters.
  static const double locationDistanceFilter = 5.0;
  
  /// Interval for danger zone checks in seconds.
  static const int dangerZoneCheckIntervalSeconds = 5;
  
  /// Panic confirmation timeout in seconds.
  static const int panicConfirmationTimeoutSeconds = 10;
}
