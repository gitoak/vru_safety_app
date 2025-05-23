import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

// TOP-LEVEL FUNCTION FOR BACKGROUND NOTIFICATION TAPS
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // ignore: avoid_print
  print(
    'Notification Tapped (Background/Terminated): ID(${notificationResponse.id}), ActionID(${notificationResponse.actionId}), Payload: ${notificationResponse.payload}',
  );
  if (notificationResponse.input?.isNotEmpty ?? false) {
    // ignore: avoid_print
    print('Notification Action Input: ${notificationResponse.input}');
  }
  // TODO: Implement navigation or other logic based on the notification payload for background taps.
}

class DangerZoneAlertSystem extends StatefulWidget {
  final List<List<LatLng>> dangerousPolygons;
  const DangerZoneAlertSystem({Key? key, required this.dangerousPolygons})
    : super(key: key);

  @override
  State<DangerZoneAlertSystem> createState() => _DangerZoneAlertSystemState();
}

class _DangerZoneAlertSystemState extends State<DangerZoneAlertSystem> {
  bool _alerted = false;
  FlutterLocalNotificationsPlugin? _notifications;

  @override
  void initState() {
    super.initState();
    _initializeAndRequestPermissions();
    _startLocationMonitoring();
  }

  // Handler for when a notification is tapped (app in foreground or background)
  void _onDidReceiveNotificationResponse(
    NotificationResponse notificationResponse,
  ) {
    debugPrint(
      'Notification Tapped (Foreground/Background): ID(${notificationResponse.id}), Payload: ${notificationResponse.payload}',
    );
    // TODO: Implement navigation or other logic based on the notification payload.
    // Example: if (notificationResponse.payload == 'some_route') { Navigator.push(...); }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Notification tapped with payload: ${notificationResponse.payload ?? 'none'}',
          ),
        ),
      );
    }
  }

  Future<void> _initializeAndRequestPermissions() async {
    _notifications = FlutterLocalNotificationsPlugin();

    // Request notification permission for Android 13+
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notifications!
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    if (androidImplementation != null) {
      final bool? granted = await androidImplementation
          .requestNotificationsPermission();
      debugPrint("Android Notification permission granted: $granted");
      if (granted == false && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Notification permission denied. Please enable it in settings.',
            ),
          ),
        );
      }
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // For iOS, request permissions and configure foreground presentation options
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    await _notifications!.initialize(
      InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      ),
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
    debugPrint("FlutterLocalNotificationsPlugin initialized.");

    // Create notification channel (Android) - THIS IS CRUCIAL
    // If you change channel settings, YOU MUST UNINSTALL AND REINSTALL THE APP on Android.
    await androidImplementation?.createNotificationChannel(
      AndroidNotificationChannel(
        'danger_zone',
        'Gefahrenzonen',
        description: 'Warnungen bei Annäherung an Gefahrenzonen',
        importance:
            Importance.max, // Ensure this is MAX for heads-up notification
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
        showBadge: true,
      ),
    );
    debugPrint("Android notification channel created/updated.");

    // Request location permission
    LocationPermission locationPermission =
        await Geolocator.requestPermission();
    debugPrint("Location permission status: $locationPermission");
    if (locationPermission == LocationPermission.denied ||
        locationPermission == LocationPermission.deniedForever && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location permission denied. App functionality will be limited.',
          ),
        ),
      );
    }
  }

  void _showDangerNotification() async {
    if (_notifications == null) {
      debugPrint('Notifications plugin not initialized');
      return;
    }
    try {
      debugPrint('Attempting to show danger notifications...');
      // Main warning notification
      await _notifications!.show(
        0,
        'Warnung: Gefahrenzone',
        'Sie befinden sich in der Nähe einer Gefahrenzone!',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'danger_zone',
            'Gefahrenzonen',
            channelDescription: 'Warnungen bei Annäherung an Gefahrenzonen',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
            ticker: 'Gefahrenzone',
          ),
          iOS: DarwinNotificationDetails(presentSound: true),
        ),
      );
      debugPrint('notification sent');
      // Show a SnackBar as a fallback to confirm the button works
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Testbenachrichtigung ausgelöst (siehe Debug-Konsole)',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Notification error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Senden der Benachrichtigung: $e'),
          ),
        );
      }
    }
  }

  void _startLocationMonitoring() async {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position pos) async {
      final user = LatLng(pos.latitude, pos.longitude);
      // Call external API to check if user should be warned (GET version)
      final shouldWarn = await _checkShouldWarn(user);
      if (shouldWarn && !_alerted) {
        _alerted = true;
        _showDangerNotification();
      } else if (!shouldWarn) {
        _alerted = false;
      }
    });
  }

  Future<bool> _checkShouldWarn(LatLng user) async {
    try {
      // final uri = Uri.parse(
      //   'https://vruapi.jannik.dev/is_dangerous_road_nearby?coord=${user.latitude},${user.longitude}',
      // );
      final uri = Uri.parse(
        'https://vruapi.jannik.dev/is_dangerous_road_nearby?coord=${user.latitude},${user.longitude}',
      );
      debugPrint('Checking danger status with API: $uri'); // Log the URI

      final resp = await http.get(uri).timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        debugPrint('API Response Data: $data'); // Log the full API response

        if (data['success'] == true) {
          debugPrint(data);
          // Expecting { success: true/false, dangerous_roads_nearby: true/false }
          return data['dangerous_roads_nearby'] == true;
        } else {
          debugPrint(
            'API call successful but operation failed: ${data['message'] ?? 'No error message provided.'}',
          );
          return false; // API indicated failure
        }
      } else {
        debugPrint(
          'API request failed with status code: ${resp.statusCode}. Response body: ${resp.body}',
        );
      }
    } catch (e, s) {
      debugPrint('Error in _checkShouldWarn (API call): $e');
      debugPrint('Stack trace for API error: $s');
    }
    return false; // Default to false in case of any error or unexpected response
  }

  void _simulateDanger() {
    _showDangerNotification();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ElevatedButton(
        onPressed: _simulateDanger,
        child: const Text('Gefahrenzone-Testbenachrichtigung'),
      ),
    );
  }
}

// NOTE: If you have previously installed the app, you may need to uninstall and reinstall it to reset the notification channel settings on Android.
