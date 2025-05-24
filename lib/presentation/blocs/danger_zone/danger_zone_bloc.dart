import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart';
import 'package:vru_safety_app/data/services/audio_service.dart';
import 'package:vru_safety_app/data/services/notification_service.dart';
import 'package:vru_safety_app/data/services/vibrations_service.dart';
import '../../../data/services/danger_zone_api_service.dart';
import '../../../core/utils/geometry_utils.dart';
import 'danger_zone_event.dart';
import 'danger_zone_state.dart';

/// Background notification tap handler.
@pragma('vm:entry-point')
void notificationTapBackground(notificationResponse) {
  debugPrint('Background notification tapped: ${notificationResponse.payload}');
}

/// BLoC responsible for managing danger zone detection and alerting.
/// Coordinates location monitoring, polygon-based danger detection, API-based checks,
/// and multi-modal alerts (notifications, audio, vibration).
class DangerZoneBloc extends Bloc<DangerZoneEvent, DangerZoneState> {
  final NotificationService _notificationService;
  final AudioService _audioService;
  final VibrationService _vibrationService;
  final DangerZoneApiService _apiService;

  // Internal state
  StreamSubscription<Position>? _positionSubscription;
  Timer? _dangerCheckTimer;
  List<List<LatLng>> _dangerousPolygons = [];
  Position? _currentPosition;

  // Configuration
  static const Duration _checkInterval = Duration(seconds: 5);
  static const LocationSettings _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 5, // Update every 5 meters
  );

  DangerZoneBloc({
    NotificationService? notificationService,
    AudioService? audioService,
    VibrationService? vibrationService,
    DangerZoneApiService? apiService,
  })  : _notificationService = notificationService ?? NotificationService(),
        _audioService = audioService ?? AudioService(),
        _vibrationService = vibrationService ?? VibrationService(),
        _apiService = apiService ?? DangerZoneApiService(),
        super(DangerZoneInitial()) {
    
    on<InitializeDangerZoneSystem>(_onInitialize);
    on<UserPositionChangedForDangerZone>(_onPositionChanged);
    on<DisposeDangerZoneSystem>(_onDispose);
  }

  /// Initializes the danger zone monitoring system.
  Future<void> _onInitialize(
    InitializeDangerZoneSystem event,
    Emitter<DangerZoneState> emit,
  ) async {
    emit(DangerZoneLoading());

    try {
      // Initialize services
      await _notificationService.initialize();
      await _audioService.initialize();
      await _vibrationService.initialize();

      // Store danger zones
      _dangerousPolygons = event.dangerousPolygons;

      // Start location monitoring
      await _startLocationMonitoring();

      emit(DangerZoneInitialized(
        dangerZones: _dangerousPolygons,
      ));
    } catch (e) {
      emit(DangerZoneError('Failed to initialize danger zone system: $e'));
    }
  }

  /// Handles position changes and checks for danger zones.
  Future<void> _onPositionChanged(
    UserPositionChangedForDangerZone event,
    Emitter<DangerZoneState> emit,
  ) async {
    _currentPosition = event.position;
    
    try {
      final userLatLng = LatLng(event.position.latitude, event.position.longitude);
      final isInDangerZone = _isUserInDangerZone(userLatLng);
      
      if (isInDangerZone) {
        await _triggerDangerAlert(event.position);
        emit(DangerZoneAlert(
          position: event.position,
          distanceToDangerZone: 0.0,
          alertMessage: 'You are entering a danger zone!',
        ));
      } else {
        // Check if user was previously in danger zone and has now exited
        if (state is DangerZoneAlert) {
          emit(DangerZoneExited(event.position));
        } else {
          emit(DangerZoneInitialized(
            currentPosition: event.position,
            isInDangerZone: false,
            dangerZones: _dangerousPolygons,
          ));
        }
      }
    } catch (e) {
      emit(DangerZoneError('Error processing position update: $e'));
    }
  }

  /// Disposes resources and stops monitoring.
  Future<void> _onDispose(
    DisposeDangerZoneSystem event,
    Emitter<DangerZoneState> emit,
  ) async {
    await _stopLocationMonitoring();
    await _notificationService.dispose();
    await _audioService.dispose();
    await _vibrationService.dispose();
    emit(DangerZoneInitial());
  }

  /// Starts location monitoring stream.
  Future<void> _startLocationMonitoring() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: _locationSettings,
    ).listen(
      (position) => add(UserPositionChangedForDangerZone(position)),
      onError: (error) => add(DisposeDangerZoneSystem()),
    );
  }

  /// Stops location monitoring.
  Future<void> _stopLocationMonitoring() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _dangerCheckTimer?.cancel();
    _dangerCheckTimer = null;
  }

  /// Checks if user is within any danger zone polygon.
  bool _isUserInDangerZone(LatLng userPosition) {
    for (final polygon in _dangerousPolygons) {
      if (isPointInPolygon(userPosition, polygon)) {
        return true;
      }
    }
    return false;
  }

  /// Triggers multi-modal danger alert.
  Future<void> _triggerDangerAlert(Position position) async {
    try {
      // Show notification
      await _notificationService.showDangerAlert(
        'Danger Zone Alert',
        'You are entering a dangerous area. Please be cautious.',
      );

      // Play audio alert
      await _audioService.playDangerSound();

      // Trigger vibration
      await _vibrationService.vibrateForDanger();
    } catch (e) {
      debugPrint('Error triggering danger alert: $e');
    }
  }

  @override
  Future<void> close() async {
    await _stopLocationMonitoring();
    return super.close();
  }
}
