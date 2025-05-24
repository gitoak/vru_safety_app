import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm; // Aliased import
import 'package:latlong2/latlong.dart';
import './danger_zone_alert_system.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vru_safety_app/bloc/navigation_bloc.dart';
import 'package:vru_safety_app/bloc/navigation_event.dart';
import 'package:vru_safety_app/bloc/navigation_state.dart';
import 'package:vru_safety_app/services/location_service.dart';
import 'package:vru_safety_app/services/routing_service.dart';
import 'package:vru_safety_app/services/danger_zone_service.dart';
import 'package:vru_safety_app/widgets/address_input_row.dart';
import 'package:vru_safety_app/widgets/suggestions_list.dart';
import 'package:vru_safety_app/widgets/instruction_bar.dart';

class NavigationPage extends StatelessWidget {
  const NavigationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NavigationBloc(
        locationService: LocationService(),
        routingService: RoutingService(),
        dangerZoneService: DangerZoneService(),
      )..add(InitializeNavigation()),
      child: const _NavigationPageView(),
    );
  }
}

class _NavigationPageView extends StatefulWidget {
  const _NavigationPageView();

  @override
  State<_NavigationPageView> createState() => _NavigationPageViewState();
}

class _NavigationPageViewState extends State<_NavigationPageView> {
  final TextEditingController _addressController = TextEditingController();
  final fm.MapController _mapController = fm.MapController();
  double _currentZoom = 15.0;

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Navigation')),
      body: BlocConsumer<NavigationBloc, NavigationState>(
        listener: (context, state) {
          if (state.error != null && state.error!.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error!)),
            );
            // Optionally clear the error in the BLoC after showing it
            // context.read<NavigationBloc>().add(ErrorOccurred(null)); 
          }
          if (state.isMapReady && state.userPosition != null) { // Added isMapReady check
            _mapController.move(state.userPosition!, _mapController.zoom);
          }
        },
        builder: (context, state) {
          if (state.pageLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              if (state.instructions.isNotEmpty)
                InstructionBar(instructions: state.instructions), // Use extracted widget
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 4.0,
                ),
                child: DangerZoneAlertSystem(
                  dangerousPolygons: [
                    [
                      const LatLng(49.010, 12.098),
                      const LatLng(49.019, 12.098),
                      const LatLng(49.019, 12.102),
                      const LatLng(49.010, 12.102),
                      const LatLng(49.010, 12.098),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    AddressInputRow(addressController: _addressController), // Use extracted widget
                    SuggestionsList(addressController: _addressController), // Use extracted widget
                  ],
                ),
              ),
              if (state.userPosition == null && !state.pageLoading)
                const Expanded(
                  child: Center(child: Text('Waiting for user location...')),
                )
              else if (state.routePoints == null &&
                  !state.pageLoading &&
                  !state.routeLoading &&
                  _addressController.text.isNotEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      'No route to "${_addressController.text}" found or error occurred.',
                    ),
                  ),
                )
              else if (state.routePoints == null &&
                  !state.pageLoading &&
                  !state.routeLoading)
                const Expanded(
                  child: Center(child: Text('No route loaded yet.')),
                )
              else
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 80.0),
                    child: fm.FlutterMap(
                      mapController: _mapController,
                      options: fm.MapOptions(
                        center: state.userPosition ?? const LatLng(0, 0),
                        zoom: _currentZoom,
                        onMapReady: () { // Dispatch MapReady event
                          context.read<NavigationBloc>().add(MapReady());
                        },
                        onPositionChanged: (position, hasGesture) {
                          if (hasGesture && position.zoom != _currentZoom) {
                            _currentZoom = position.zoom ?? _currentZoom;
                          }
                        },
                      ),
                      children: [
                        fm.TileLayer(
                          urlTemplate:
                              'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                          subdomains: const ['a', 'b', 'c'],
                        ),
                        if (state.routePoints != null &&
                            state.routePoints!.isNotEmpty)
                          fm.PolylineLayer(
                            polylines: [
                              fm.Polyline(
                                points: state.routePoints!,
                                strokeWidth: 4.0,
                                color: Colors.blue,
                              ),
                            ],
                          ),
                        if (state.userPosition != null)
                          fm.MarkerLayer(
                            markers: [
                              fm.Marker(
                                width: 80.0,
                                height: 80.0,
                                point: state.userPosition!,
                                builder: (ctx) => const Icon(
                                  Icons.my_location,
                                  color: Colors.blue,
                                  size: 30.0,
                                ),
                              ),
                            ],
                          ),
                        if (state.dangerZonePolygons.isNotEmpty)
                          fm.PolygonLayer(polygons: state.dangerZonePolygons),
                        if (state.dangerZoneMarkers.isNotEmpty)
                          fm.MarkerLayer(markers: state.dangerZoneMarkers),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: BlocBuilder<NavigationBloc, NavigationState>(
        builder: (context, state) {
          if (state.userPosition == null) return const SizedBox.shrink();
          return FloatingActionButton(
            heroTag: "compass_toggle",
            onPressed: () =>
                context.read<NavigationBloc>().add(ToggleCompassMode()),
            tooltip: state.compassMode
                ? 'Exit compass mode'
                : 'Enter compass mode',
            backgroundColor: state.compassMode ? Colors.orange : null,
            child: Icon(state.compassMode ? Icons.explore : Icons.explore_off),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}
