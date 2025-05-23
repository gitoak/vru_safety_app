import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import '../widgets/danger_zone_alert_system.dart';
import '../widgets/instruction_bar.dart';
import '../widgets/map_widget.dart';
import '../widgets/destination_search_bar.dart';
import '../bloc/navigation_event_state.dart';
import '../bloc/navigation_bloc_logic.dart';
import '../services/nominatim_api_service.dart';
import '../services/graphhopper_api_service.dart';

class NavigationPage extends StatelessWidget {
  const NavigationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NavigationBloc(
        nominatimApiService: NominatimApiService(),
        graphHopperApiService: GraphHopperApiService(),
      )..add(InitializeNavigationRequested()),
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
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigation'),
      ),
      body: BlocConsumer<NavigationBloc, NavigationState>(
        listener: (context, state) {
          if (state is NavigationLoadFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
          if (state is NavigationLoadSuccess) {
            if (state.currentAddressText != null && _addressController.text != state.currentAddressText) {
              _addressController.text = state.currentAddressText!;
            }
            _mapController.move(state.userPosition, _currentZoom);
          }
        },
        builder: (context, state) {
          if (state is NavigationInitial || state is NavigationLoadInProgress) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is NavigationLoadSuccess) {
            return Column(
              children: [
                if (state.instructions.isNotEmpty)
                  InstructionBar(instructions: state.instructions),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 4.0,
                  ),
                  child: DangerZoneAlertSystem(
                    dangerousPolygons: state.dangerZonePolygons.map((poly) => poly.points).toList(),
                  ),
                ),
                DestinationSearchBar(
                  addressController: _addressController,
                  suggestions: state.suggestions,
                  showSuggestions: state.showSuggestions,
                  onSearchAndRoute: () {
                    context.read<NavigationBloc>().add(SearchRouteRequested(_addressController.text));
                  },
                  onUpdateSuggestions: (input) {
                    context.read<NavigationBloc>().add(AddressSuggestionsRequested(input));
                  },
                  onSelectSuggestion: (suggestion) {
                    context.read<NavigationBloc>().add(AddressSuggestionSelected(suggestion));
                  },
                  routeLoading: state is NavigationRouteSearchInProgress,
                ),
                Expanded(
                  child: MapWidget(
                    mapController: _mapController,
                    userPosition: state.userPosition,
                    userHeading: state.userHeading,
                    destinationPosition: state.destinationPosition,
                    routePoints: state.routePoints,
                    dangerZonePolygons: state.dangerZonePolygons,
                    currentZoom: _currentZoom,
                    onMapReady: () {
                      _mapController.move(state.userPosition, _currentZoom);
                    },
                    onPositionChanged: (camera, hasGesture) {
                      _currentZoom = camera.zoom;
                    },
                  ),
                ),
                if (state is NavigationRouteSearchInProgress)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            );
          }
          if (state is NavigationLoadFailure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${state.message}'),
                  ElevatedButton(
                    onPressed: () {
                      context.read<NavigationBloc>().add(InitializeNavigationRequested());
                    },
                    child: const Text('Retry'),
                  )
                ],
              ),
            );
          }
          return const Center(child: Text('Unknown state'));
        },
      ),
    );
  }
}
