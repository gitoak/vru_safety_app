import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import 'danger_zone_event_state.dart';

// New internal event for timer-based check
class _TimerCheckDangerZoneTriggered extends DangerZoneEvent {
  const _TimerCheckDangerZoneTriggered();
}

// Top-level function for background notification tap
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // print('Notification Tapped (Background/Terminated): ID(${notificationResponse.id}), ActionID(${notificationResponse.actionId}), Payload: ${notificationResponse.payload}');
  // Handle background tap if necessary, e.g., logging or specific background tasks.
}

class DangerZoneBloc extends Bloc<DangerZoneEvent, DangerZoneState> {
  FlutterLocalNotificationsPlugin? _notifications;
  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _dangerCheckTimer;
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<List<LatLng>> _dangerousPolygons = [];
  Position? _currentPosition;

  DangerZoneBloc() : super(DangerZoneInitial()) {
    on<InitializeDangerZoneSystem>(_onInitializeDangerZoneSystem);
    on<UserPositionChangedForDangerZone>(_onUserPositionChangedForDangerZone);
    on<DisposeDangerZoneSystem>(_onDisposeDangerZoneSystem);
    on<_TimerCheckDangerZoneTriggered>(_onTimerCheckDangerZoneTriggered);
  }

  Future<void> _onInitializeDangerZoneSystem(
      InitializeDangerZoneSystem event, Emitter<DangerZoneState> emit) async {
    _dangerousPolygons = event.dangerousPolygons;
    await _initializeAudioPlayer();
    await _initializeAndRequestPermissions();
    _startLocationUpdatesAndPeriodicChecks();
    emit(const DangerZoneMonitoring(isInDangerZone: false, hasAlertedForCurrentZone: false));
  }

  void _onUserPositionChangedForDangerZone(
      UserPositionChangedForDangerZone event, Emitter<DangerZoneState> emit) {
    _currentPosition = event.position;
    // Periodic check will handle the logic, or you can trigger a check here if needed immediately.
    // _checkIfInDangerZone(emit); // Potentially, if immediate reaction is desired.
  }

  void _onDisposeDangerZoneSystem(DisposeDangerZoneSystem event, Emitter<DangerZoneState> emit) {
    _dangerCheckTimer?.cancel();
    _positionStreamSubscription?.cancel();
    _audioPlayer.dispose();
    // No specific state change needed on dispose, or emit an Initial state if required.
  }

  Future<void> _initializeAudioPlayer() async {
    await _audioPlayer.setReleaseMode(ReleaseMode.stop);
    // _audioPlayer.onPlayerStateChanged.listen((PlayerState s) {
    //   // debugPrint('Current player state: $s');
    // });
  }

  Future<void> _initializeAndRequestPermissions() async {
    _notifications = FlutterLocalNotificationsPlugin();
    await _notifications?.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    await _notifications?.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.requestExactAlarmsPermission();
    await _notifications?.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
            alert: true, badge: true, sound: true);

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      // iOS settings can be added here if needed
    );
    await _notifications?.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  }

  void _onDidReceiveNotificationResponse(NotificationResponse notificationResponse) {
    // print('Notification Tapped (Foreground/Active): ID(${notificationResponse.id}), Payload: ${notificationResponse.payload}');
    // This callback is for when the app is in the foreground or background but active.
    // You might want to navigate or show something in the UI.
  }

  void _startLocationUpdatesAndPeriodicChecks() {
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5),
    ).listen((Position position) {
      add(UserPositionChangedForDangerZone(position));
    });

    _dangerCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      add(const _TimerCheckDangerZoneTriggered());
    });
  }

  void _onTimerCheckDangerZoneTriggered(
    _TimerCheckDangerZoneTriggered event, Emitter<DangerZoneState> emit) {
    if (state is DangerZoneMonitoring) {
      _checkIfInDangerZone(emit);
    }
  }

  void _checkIfInDangerZone(Emitter<DangerZoneState> emit) {
    if (_currentPosition == null) return;
    if (state is! DangerZoneMonitoring) return;

    final currentMonitoringState = state as DangerZoneMonitoring;
    final userPoint = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    bool inDanger = false;

    for (final polygon in _dangerousPolygons) {
      if (_pointInPolygon(userPoint, polygon)) {
        inDanger = true;
        break;
      }
    }

    if (inDanger && !currentMonitoringState.hasAlertedForCurrentZone) {
      emit(currentMonitoringState.copyWith(isInDangerZone: true, hasAlertedForCurrentZone: true));
      _triggerAlerts();
    } else if (!inDanger && currentMonitoringState.isInDangerZone) {
      // User has exited a danger zone they were previously in
      emit(currentMonitoringState.copyWith(isInDangerZone: false, hasAlertedForCurrentZone: false));
    } else if (inDanger && currentMonitoringState.isInDangerZone) {
      // User is still in the same danger zone, no new alert, but state reflects they are in danger.
      // This case is covered by not changing hasAlertedForCurrentZone until they exit.
    }
  }

  void _triggerAlerts() {
    _showDangerNotification();
    _playWarningSound();
    _vibrateDevice();
  }

  bool _pointInPolygon(LatLng point, List<LatLng> polygon) {
    if (polygon.isEmpty) return false;
    int intersectCount = 0;
    for (int j = 0; j < polygon.length -1; j++) { // Ensure we don't go out of bounds
        // Check if the polygon is closed, if not, connect last to first
        LatLng vertA = polygon[j];
        LatLng vertB = polygon[(j + 1) % polygon.length]; // Use modulo for safety, though typically last point == first

        if (_rayCastIntersect(point, vertA, vertB)) {
            intersectCount++;
        }
    }
     // If polygon isn't explicitly closed by repeating the first point at the end:
    if (polygon.first != polygon.last) {
        if (_rayCastIntersect(point, polygon.last, polygon.first)) {
            intersectCount++;
        }
    }
    return (intersectCount % 2) == 1; // Odd number of intersections means point is inside
}


  bool _rayCastIntersect(LatLng point, LatLng vertA, LatLng vertB) {
    double aY = vertA.latitude;
    double bY = vertB.latitude;
    double aX = vertA.longitude;
    double bX = vertB.longitude;
    double pY = point.latitude;
    double pX = point.longitude;

    // Edge cases for horizontal and vertical lines
    if (aY == bY) return false; // Horizontal line cannot be crossed by a horizontal ray unless point is on it
    if (pY < math.min(aY, bY) || pY >= math.max(aY, bY)) return false; // Point is not within Y-range of segment
    if (pX >= math.max(aX, bX)) return false; // Point is to the right of the segment

    if (aX == bX) return true; // Vertical line is crossed if pX < aX and pY is within Y-range

    double m_inv = (bX - aX) / (bY - aY); // Inverse slope
    double x_intersection = aX + m_inv * (pY - aY);

    return x_intersection > pX;
  }

  Future<void> _showDangerNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'danger_zone_channel', 
      'Danger Zone Alerts',
      channelDescription: 'Alerts when entering a danger zone',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await _notifications?.show(
      0, 
      'Danger Zone Alert',
      'You have entered a danger zone!',
      platformChannelSpecifics,
      payload: 'danger_zone',
    );
  }

  Future<void> _playWarningSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/warning_alarm.mp3'));
    } catch (e) {
      // print("Error playing sound: $e");
    }
  }

  Future<void> _vibrateDevice() async {
    final bool? hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) { // Explicitly check for true
      Vibration.vibrate(duration: 1000);
    }
  }

  @override
  Future<void> close() {
    add(DisposeDangerZoneSystem()); // Ensure resources are cleaned up
    return super.close();
  }
}
