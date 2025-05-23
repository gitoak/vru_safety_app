import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

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

  Future<void> _initializeAndRequestPermissions() async {
    _notifications = FlutterLocalNotificationsPlugin();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _notifications!.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    // Create notification channel with vibration and sound (Android)
    await _notifications!
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          AndroidNotificationChannel(
            'danger_zone',
            'Gefahrenzonen',
            description: 'Warnungen bei Annäherung an Gefahrenzonen',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
            showBadge: true,
          ),
        );
    // Request notification permission (iOS)
    final iosImplementation = _notifications!
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (iosImplementation != null) {
      await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
    // Request location permission
    await Geolocator.requestPermission();
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
      debugPrint('First notification sent');
      // Additional attention notification
      await _notifications!.show(
        1,
        'Achtung',
        'Sie sind in der Nähe einer Gefahrenzone, bitte seien Sie aufmerksam!',
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
      debugPrint('Second notification sent');
      if (await Vibration.hasVibrator()) {
        Vibration.vibrate(pattern: [0, 500, 200, 500]);
      }
      // Show a SnackBar as a fallback to confirm the button works
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Testbenachrichtigung ausgelöst (siehe Debug-Konsole)')),
        );
      }
    } catch (e) {
      debugPrint('Notification error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Senden der Benachrichtigung: $e')),
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
      final resp = await http.get(
        Uri.parse(
          'https://vruapi.jannik.dev/coordinate?coord=${user.latitude},${user.longitude}',
        ),
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        // Expecting { warn: true/false } from API
        return data['warn'] == true;
      }
    } catch (e) {
      debugPrint('Warning API error: $e');
    }
    return false;
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
