import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
// Geolocator, notifications, vibration, audioplayers are now handled by the Bloc
// import 'package:geolocator/geolocator.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:vibration/vibration.dart';
// import 'dart:async';
// import 'package:audioplayers/audioplayers.dart';
import '../bloc/danger_zone_bloc_logic.dart';
import '../bloc/danger_zone_event_state.dart';

// Background notification tap function is now in the Bloc logic file
// @pragma('vm:entry-point')
// void notificationTapBackground(NotificationResponse notificationResponse) { ... }

class DangerZoneAlertSystem extends StatelessWidget {
  final List<List<LatLng>> dangerousPolygons;

  const DangerZoneAlertSystem({Key? key, required this.dangerousPolygons})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DangerZoneBloc()
        ..add(InitializeDangerZoneSystem(dangerousPolygons)),
      child: BlocListener<DangerZoneBloc, DangerZoneState>(
        listener: (context, state) {
          if (state is DangerZoneMonitoring) {
            if (state.isInDangerZone && state.hasAlertedForCurrentZone) {
              // Optionally, show an in-app visual cue if needed, 
              // though primary alerts (sound, vibration, notification) are by Bloc.
              // For example, could update a UI element via a parent widget if this widget
              // were to expose its state or a callback.
            }
          } else if (state is DangerZoneError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Danger Zone system error: ${state.message}")),
            );
          }
        },
        // This widget itself doesn't need to build anything visible based on Bloc state,
        // as alerts are handled by notifications/sound/vibration triggered by the Bloc.
        // It acts as a controller to host and initialize the Bloc.
        // If a visual representation of the danger status was needed here,
        // a BlocBuilder could be used.
        child: const SizedBox.shrink(), 
      ),
    );
  }
}

// The _DangerZoneAlertSystemState is no longer needed as all its logic
// (init, dispose, location updates, permission handling, alert triggering, polygon checking)
// has been moved into the DangerZoneBloc.
