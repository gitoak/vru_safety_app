import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'dart:async'; // Added for Timer
import 'package:audioplayers/audioplayers.dart'; // Added for custom sound

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
  Position? _currentPosition; // To store the latest known position
  Timer? _dangerCheckTimer; // Timer for periodic checks
  AudioPlayer _audioPlayer = AudioPlayer(); // Added AudioPlayer instance

  @override
  void initState() {
    super.initState();
    _initializeAudioPlayer(); // Initialize AudioPlayer settings
    _initializeAndRequestPermissions(); // Ensure permissions are requested
    _startLocationUpdatesAndPeriodicChecks(); // Start location updates and periodic checks
  }

  Future<void> _initializeAudioPlayer() async {
    await _audioPlayer.setReleaseMode(ReleaseMode.stop);
    // Optional: Set player mode if low latency is critical and available.
    // await _audioPlayer.setPlayerMode(PlayerMode.lowLatency);
    debugPrint("AudioPlayer initialized with ReleaseMode.stop");

    // Preload the sound if possible and desired, though play() will also load it.
    // await _audioPlayer.setSource(AssetSource('sounds/warning_alarm.mp3'));
    // debugPrint("AudioPlayer source set to warning_alarm.mp3");

    _audioPlayer.onPlayerStateChanged.listen((PlayerState s) {
      debugPrint('Current player state: $s');
    });
    _audioPlayer.onLog.listen((String log) {
      debugPrint('AudioPlayer Log: $log');
    });

  }

  @override
  void dispose() {
    _dangerCheckTimer?.cancel(); // Cancel the timer when the widget is disposed
    _audioPlayer.dispose(); // Dispose of the audio player
    super.dispose();
  }

  // Handler for when a notification is tapped (app in foreground or background)
  void _onDidReceiveNotificationResponse(
    NotificationResponse notificationResponse,
  ) {
    debugPrint(
      'Notification Tapped (Foreground/Background): ID(${notificationResponse.id}), Payload: ${notificationResponse.payload}',
    );
    // TODO: Implement navigation or other logic based on the notification payload.
    // Example: if (notificationResponse.payload == 'some_route') { Navigator.push(...); }\r
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
          requestSoundPermission: true, // Request general sound permission for app
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
      const AndroidNotificationChannel(
        'danger_zone_channel_v1', // Updated Channel ID
        'Gefahrenzonen Warnungen', // Updated Name for clarity
        description: 'Benachrichtigungen für Gefahrenzonen und Sicherheitswarnungen', // Updated description
        importance:
            Importance.max, // Ensure this is MAX for heads-up notification
        playSound: false, // Set to false as sound is handled manually
        enableVibration: false, // Set to false as vibration is handled manually
        vibrationPattern: null, // Set to null as vibration is handled manually
        showBadge: true,
      ),
    );
    debugPrint("Android notification channel 'danger_zone_channel_v1' created/updated.");

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
      debugPrint('Attempting to show danger notification with manual sound and vibration...');
      
      // 1. Play custom sound
      try {
        // Ensure any previous sound is stopped before playing a new one.
        await _audioPlayer.stop(); 
        await _audioPlayer.play(AssetSource('sounds/warning_alarm.mp3'));
        debugPrint("Custom warning sound playback initiated via AssetSource.");
      } catch (e) {
        debugPrint("Error playing sound: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error playing sound: $e')),
          );
        }
      }

      // 2. Trigger custom vibration
      try {
        bool? hasVibrator = await Vibration.hasVibrator();
        if (hasVibrator ?? false) {
          // Pattern: vibrate 500ms, pause 200ms, vibrate 500ms. Intensities for Android.
          // iOS does not support custom patterns or intensities via this plugin, it will be a default vibration.
          Vibration.vibrate(pattern: [0, 500, 200, 500], intensities: [0, 128, 0, 128]); 
          debugPrint("Custom vibration initiated.");
        } else {
          debugPrint("Device does not have a vibrator.");
        }
      } catch (e) {
        debugPrint("Error triggering vibration: $e");
         if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error triggering vibration: $e')),
          );
        }
      }

      // 3. Show the notification (configured for no default sound/vibration)
      await _notifications!.show(
        0, // Notification ID
        'Warnung: Gefahrenzone',
        'Sie befinden sich in der Nähe einer Gefahrenzone!',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'danger_zone_channel_v1', // Use the updated Channel ID
            'Gefahrenzonen Warnungen', // Match channel name
            channelDescription: 'Benachrichtigungen für Gefahrenzonen und Sicherheitswarnungen', // Match channel desc
            importance: Importance.max,
            priority: Priority.high,
            playSound: false, // Explicitly false
            enableVibration: false, // Explicitly false
            vibrationPattern: null, // Explicitly null
            ticker: 'Gefahrenzone',
          ),
          iOS: DarwinNotificationDetails(
            presentSound: false, // Explicitly false for iOS sound
            presentAlert: true,  // Show alert
            presentBadge: true,  // Update badge
          ),
        ),
        payload: 'danger_zone_alert_payload_${DateTime.now().millisecondsSinceEpoch}' // Example payload
      );
      debugPrint('Notification sent via channel danger_zone_channel_v1.');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Gefahrenwarnung ausgelöst (Benachrichtigung, Ton, Vibration)!', // Updated message
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e, s) {
      debugPrint('Error in _showDangerNotification: $e');
      debugPrint('Stack trace for _showDangerNotification error: $s');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Anzeigen der Gefahrenwarnung: $e'),
          ),
        );
      }
    }
  }

  void _startLocationUpdatesAndPeriodicChecks() async {
    // Start listening to position updates
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Update position if moved by 5 meters
      ),
    ).listen((Position pos) {
      if (mounted) {
        setState(() {
          _currentPosition = pos;
        });
        // Optional: Trigger an immediate check on significant location change if desired,
        // but the timer will handle periodic checks anyway.
        // _performDangerCheck(); 
      }
    }, onError: (error) {
      debugPrint("Error getting location stream: $error");
      // Handle location stream errors if necessary
    });

    // Start the periodic timer for danger checks
    _dangerCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _performDangerCheck();
    });
  }

  Future<void> _performDangerCheck() async {
    if (_currentPosition == null) {
      debugPrint("No current location available to check for danger.");
      return;
    }

    final userLocation = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    final shouldWarn = await _checkShouldWarn(userLocation);

    if (mounted) { // Check if the widget is still in the tree
      if (shouldWarn && !_alerted) {
        setState(() {
          _alerted = true;
        });
        _showDangerNotification();
      } else if (!shouldWarn && _alerted) { // Only reset if it was previously alerted
        setState(() {
          _alerted = false;
        });
        debugPrint("Danger condition cleared. Alerted state reset.");
      }
    }
  }

  Future<bool> _checkShouldWarn(LatLng user) async {
    try {
      final uri = Uri.parse(
        'https://vruapi.jannik.dev/is_dangerous_road_nearby?coord=${user.latitude},${user.longitude}',
      );
      debugPrint('Checking danger status with API: $uri'); // Log the URI

      final resp = await http.get(uri).timeout(const Duration(seconds: 10)); // Increased timeout

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        debugPrint('API Response Data: $data'); // Log the full API response

        if (data['success'] == true && data.containsKey('dangerous_roads_nearby')) {
          return data['dangerous_roads_nearby'] == true;
        } else {
          debugPrint(
            'API call successful but data format unexpected or operation failed: ${data['message'] ?? 'No error message provided.'}',
          );
          return false; 
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
    debugPrint("Simulate danger button pressed. Current alerted state: $_alerted");
    // This directly triggers the notification, sound, and vibration for testing purposes.
    _showDangerNotification(); 
    
    // If you want the test button to also toggle the _alerted state for UI consistency (optional):
    // if (mounted) {
    //   setState(() {
    //     _alerted = true; 
    //   });
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: _simulateDanger,
            child: const Text('Gefahrenzone-Testbenachrichtigung'),
          ),
          if (_currentPosition != null) 
            Text('Aktuelle Position: ${_currentPosition!.latitude.toStringAsFixed(5)}, ${_currentPosition!.longitude.toStringAsFixed(5)}'),
          Text(_alerted ? 'WARNUNG AKTIV' : 'Keine Warnung', style: TextStyle(color: _alerted ? Colors.red : Colors.green, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// NOTE: If you have previously installed the app, you may need to uninstall and reinstall it to reset the notification channel settings on Android.
