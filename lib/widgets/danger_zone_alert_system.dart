import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import '../bloc/danger_zone_bloc.dart';
import '../bloc/danger_zone_event_state.dart';

/// Widget that manages danger zone alert system integration.
/// Provides a clean interface for initializing and monitoring danger zone alerts
/// while keeping all business logic in the BLoC layer.
class DangerZoneAlertSystem extends StatelessWidget {
  final List<List<LatLng>> dangerousPolygons;
  final Widget? child;
  final bool showDebugInfo;

  const DangerZoneAlertSystem({
    super.key,
    required this.dangerousPolygons,
    this.child,
    this.showDebugInfo = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DangerZoneBloc()
        ..add(InitializeDangerZoneSystem(dangerousPolygons)),
      child: BlocListener<DangerZoneBloc, DangerZoneState>(
        listener: (context, state) {
          _handleStateChanges(context, state);
        },
        child: showDebugInfo 
            ? _buildDebugView()
            : (child ?? const SizedBox.shrink()),
      ),
    );
  }

  /// Handles state changes and shows appropriate user feedback.
  void _handleStateChanges(BuildContext context, DangerZoneState state) {
    switch (state) {
      case DangerZoneError error:
        _showErrorFeedback(context, error.message);
        break;
      case DangerZoneMonitoring monitoring:
        _handleMonitoringState(context, monitoring);
        break;
      case DangerZoneLoading():
        // Could show loading indicator if needed
        break;
      case DangerZoneInitial():
        // Initial state, no action needed
        break;
    }
  }

  /// Shows error feedback to the user.
  void _showErrorFeedback(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Danger Zone Error: $message'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  /// Handles monitoring state changes and provides user feedback.
  void _handleMonitoringState(BuildContext context, DangerZoneMonitoring state) {
    if (state.isInDangerZone && !state.hasAlertedForCurrentZone) {
      // Show visual feedback when entering danger zone
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Gefahrenzone erkannt!'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } else if (!state.isInDangerZone && state.hasAlertedForCurrentZone) {
      // Show feedback when exiting danger zone
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Gefahrenzone verlassen'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Builds a debug view showing current danger zone status.
  Widget _buildDebugView() {
    return BlocBuilder<DangerZoneBloc, DangerZoneState>(
      builder: (context, state) {
        return Card(
          margin: const EdgeInsets.all(8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Danger Zone Debug',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _buildStatusIndicator(state),
                const SizedBox(height: 8),
                _buildTestButton(context),
                if (child != null) ...[
                  const SizedBox(height: 8),
                  child!,
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds a status indicator for the debug view.
  Widget _buildStatusIndicator(DangerZoneState state) {
    switch (state) {
      case DangerZoneInitial():
        return const _StatusChip('Initialized', Colors.grey);
      case DangerZoneLoading():
        return const _StatusChip('Loading...', Colors.blue);
      case DangerZoneMonitoring monitoring:
        return monitoring.isInDangerZone
            ? const _StatusChip('IN DANGER ZONE', Colors.red)
            : const _StatusChip('Safe', Colors.green);
      case DangerZoneError error:
        return _StatusChip('Error: ${error.message}', Colors.red);
    }
    // Fallback in case a new state is added in the future
    return const _StatusChip('Unknown State', Colors.black);
  }

  /// Builds a test button for triggering alerts in debug mode.
  Widget _buildTestButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _triggerTestAlert(context),
      icon: const Icon(Icons.warning),
      label: const Text('Test Alert'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
    );
  }

  /// Triggers a test alert for debugging purposes.
  void _triggerTestAlert(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🚨 Test alert triggered - check notifications, audio, and vibration'),
        duration: Duration(seconds: 3),
      ),
    );
    // Note: In a real implementation, you might want to add a test event to the BLoC
  }
}

/// Simple status chip widget for debug display.
class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
