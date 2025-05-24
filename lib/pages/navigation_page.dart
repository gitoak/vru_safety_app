import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import '../widgets/danger_zone_alert_system.dart';
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
  final StreamController<List<dynamic>> _instructionStreamController =
      StreamController.broadcast();
  Timer? _instructionUpdateTimer;

  @override
  void initState() {
    super.initState();
    _startInstructionUpdates();
  }

  void _startInstructionUpdates() {
    _instructionUpdateTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      final updatedInstructions = context
          .read<NavigationBloc>()
          .state
          .instructions;
      _instructionStreamController.add(updatedInstructions);
    });
  }

  @override
  void dispose() {
    _instructionUpdateTimer?.cancel();
    _instructionStreamController.close();
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
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.error!)));
          }
          if (state.isMapReady && state.userPosition != null) {
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
                InstructionBar(
                  initialInstructions: state.instructions,
                  instructionStream: _instructionStreamController.stream,
                ),
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
                    AddressInputRow(addressController: _addressController),
                    SuggestionsList(addressController: _addressController),
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
                        maxZoom: 18,
                        interactiveFlags: fm.InteractiveFlag.all,
                        onMapReady: () {
                          Builder(
                            builder: (context) {
                              context.read<NavigationBloc>().add(MapReady());
                              return const SizedBox.shrink();
                            },
                          );
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
                                builder: (ctx) => Transform.rotate(
                                  angle: state.compassHeading != null
                                      ? state.compassHeading! *
                                            (3.14159265359 / 180)
                                      : 0,
                                  child: const Icon(
                                    Icons.navigation,
                                    color: Colors.blue,
                                    size: 30.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        if (state.destinationPosition != null)
                          fm.MarkerLayer(
                            markers: [
                              fm.Marker(
                                width: 80.0,
                                height: 80.0,
                                point: state.destinationPosition!,
                                builder: (ctx) => const Icon(
                                  Icons.location_on,
                                  color: Colors.red,
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
            heroTag: "reset_map_view",
            onPressed: () {
              if (state.userPosition != null) {
                _mapController.move(state.userPosition!, _currentZoom);
              }
            },
            tooltip: 'Reset map view to current location',
            backgroundColor: Colors.blue,
            child: const Icon(Icons.my_location),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}
