import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm; // Aliased import
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import './danger_zone_alert_system.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:rxdart/rxdart.dart'; // Add this import for throttling

class NavigationPage extends StatefulWidget {
  const NavigationPage({super.key});

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  List<LatLng>? _routePoints;
  bool _pageLoading = true;
  bool _routeLoading = false;
  String? _error;
  LatLng? _userPosition;
  LatLng? _destinationPosition;
  final TextEditingController _addressController = TextEditingController();
  List<String> _suggestions = [];
  bool _showSuggestions = false;
  List<dynamic> _instructions = [];

  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<CompassEvent>? _compassSubscription;
  final fm.MapController _mapController = fm.MapController(); // Use fm. alias
  double _currentZoom = 15.0;
  bool _mapReady = false;
  bool _compassMode = false; // Toggle for compass/navigation mode

  List<fm.Polygon> _dangerZonePolygons = []; // Corrected type

  List<fm.Marker> _dangerZoneMarkers = []; // Markers for danger zones

  void _updateDangerZoneMarkers() {
    setState(() {
      _dangerZoneMarkers = _dangerZonePolygons.map((polygon) {
        // Calculate the center of the polygon
        final center = polygon.points.reduce(
          (a, b) => LatLng(
            (a.latitude + b.latitude) / 2,
            (a.longitude + b.longitude) / 2,
          ),
        );

        return fm.Marker(
          point: center,
          builder: (ctx) =>
              const Icon(Icons.warning, color: Colors.red, size: 30),
        );
      }).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    _initializePage().then(
      (_) => _updateDangerZoneMarkers(),
    ); // Update markers after polygons are loaded
  }

  Future<void> _initializePage() async {
    setState(() {
      _pageLoading = true;
      _error = null;
    });
    await _initializeLocationAndCompass();
    await _loadDangerZones(); // Added call to load danger zones
    // Fetch initial route only after we have the first location and map is ready
    if (_userPosition != null) {
      // Deferring initial route fetch until map is ready might be better if it depends on map state
      // For now, fetching if user position is known.
      await _fetchInitialRoute();
    }
    if (mounted) {
      setState(() {
        _pageLoading = false;
      });
    }
  }

  Future<void> _initializeLocationAndCompass() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location services are disabled. Please enable them.',
            ),
          ),
        );
        setState(() => _error = 'Location services disabled');
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied.')),
          );
          setState(() => _error = 'Location permissions denied');
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permissions are permanently denied.'),
          ),
        );
        setState(() => _error = 'Location permissions permanently denied');
      }
      return;
    }

    try {
      Position initialPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _userPosition = LatLng(
            initialPosition.latitude,
            initialPosition.longitude,
          );
        });
        // Initial map movement will be handled by onMapReady or subsequent updates
      }
    } catch (e) {
      debugPrint("Error getting initial position: $e");
      if (mounted) {
        setState(() => _error = 'Error getting initial location: $e');
      }
    }

    _positionStreamSubscription =
        Geolocator.getPositionStream(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high,
                distanceFilter: 5,
              ),
            )
            .transform(
              ThrottleStreamTransformer(
                (_) => Stream<void>.periodic(const Duration(seconds: 1)),
              ),
            ) // Throttle updates to 1 second
            .listen(
              (Position position) {
                if (mounted) {
                  final newPosition = LatLng(
                    position.latitude,
                    position.longitude,
                  );
                  setState(() {
                    _userPosition = newPosition;
                  });
                  if (_mapReady) {
                    _mapController.move(newPosition, _mapController.zoom);
                  }
                  debugPrint("Live location update: $newPosition");
                }
              },
              onError: (error) {
                debugPrint("Error in location stream: $error");
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error in location stream: $error')),
                  );
                }
              },
            );

    _compassSubscription = FlutterCompass.events?.listen((CompassEvent event) {
      if (mounted) {
        final heading = event.heading ?? 0.0;
        setState(() {
          // Always store the heading
        });

        // Removed auto-rotation logic to allow free user control
        debugPrint('Compass heading updated: $heading degrees');
      }
    });
  }

  Future<void> _fetchInitialRoute() async {
    if (_userPosition == null) {
      if (mounted) {
        setState(() {
          _error = "User location not available to fetch initial route.";
        });
      }
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
          'https://graphhopper.jannik.dev/route?point=${_userPosition!.latitude},${_userPosition!.longitude}&point=49.019,12.102&profile=foot&locale=en&instructions=true',
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final path = data['paths'][0];
        final points = path['points'];
        final decoded = _decodePolyline(points);
        if (mounted) {
          setState(() {
            _routePoints = decoded;
            _instructions = path['instructions'] ?? [];
            // Set a default destination for the initial route if not searching
            if (_addressController.text.isEmpty) {
              _destinationPosition = const LatLng(49.019, 12.102);
            }
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Failed to fetch initial route: ${response.statusCode}';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error fetching initial route: $e';
        });
      }
    }
  }

  Future<void> _loadDangerZones() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'Unfallatlas/regensburg_tiles.json',
      );
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      setState(() {
        _dangerZonePolygons = jsonData['features'].map<fm.Polygon>((feature) {
          
          final coordinates = feature['geometry']['coordinates'][0];
          final points = coordinates
              .map<LatLng>((coord) => LatLng(coord[1], coord[0]))
              .toList();

          final dangerScore = feature['properties']['danger_score'] ?? 0;
          //if danger score is 2 or less, show empty polygon
          if (dangerScore <= 3) {
            return fm.Polygon(
              points: [],
              color: Colors.transparent,
              borderColor: Colors.transparent,
            );
          }

          return fm.Polygon(
            points: points,
            color: Colors.red,
            borderColor: Colors.red,
            borderStrokeWidth: 2.0,
          );
        }).toList();
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load danger zones: $e';
      });
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;
    int shift = 0, result = 0;
    int b;
    const int factor = 100000;
    while (index < len) {
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;
      poly.add(LatLng(lat / factor, lng / factor));
    }
    return poly;
  }

  Future<void> _searchAndRoute() async {
    if (_userPosition == null) {
      if (mounted) {
        setState(() {
          _error = "Current location not available. Cannot search for a route.";
          _routeLoading = false;
        });
      }
      return;
    }
    setState(() {
      _routeLoading = true;
      _error = null;
      _routePoints = null;
      _instructions = [];
    });
    try {
      final address = _addressController.text.trim();
      if (address.isEmpty) {
        if (mounted) {
          setState(() {
            _error = 'Please enter a destination address.';
            _routeLoading = false;
          });
        }
        return;
      }
      final geoResp = await http.get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(address)}&format=json&limit=1',
        ),
      );
      if (geoResp.statusCode == 200) {
        final geoData = json.decode(geoResp.body);
        if (geoData.isEmpty) {
          if (mounted) {
            setState(() {
              _error = 'Address not found.';
              _routeLoading = false;
            });
          }
          return;
        }
        final lat = double.parse(geoData[0]['lat']);
        final lon = double.parse(geoData[0]['lon']);
        if (mounted) {
          setState(() {
            _destinationPosition = LatLng(lat, lon);
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Geocoding failed.';
            _routeLoading = false;
          });
        }
        return;
      }

      final response = await http.get(
        Uri.parse(
          'https://graphhopper.jannik.dev/route?point=${_userPosition!.latitude},${_userPosition!.longitude}&point=${_destinationPosition!.latitude},${_destinationPosition!.longitude}&profile=foot&locale=en&instructions=true',
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final path = data['paths'][0];
        final points = path['points'];
        final decoded = _decodePolyline(points);
        if (mounted) {
          setState(() {
            _routePoints = decoded;
            _instructions = path['instructions'] ?? [];
            _routeLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Failed to fetch route: ${response.statusCode}';
            _routeLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error: $e';
          _routeLoading = false;
        });
      }
    }
  }

  Future<void> _updateSuggestions(String input) async {
    if (input.isEmpty) {
      if (mounted) {
        setState(() {
          _suggestions = [];
          _showSuggestions = false;
        });
      }
      return;
    }
    final resp = await http.get(
      Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(input)}&format=json&addressdetails=1&limit=5',
      ),
    );
    if (resp.statusCode == 200) {
      final data = json.decode(resp.body);
      if (mounted) {
        setState(() {
          _suggestions = [
            for (final item in data) item['display_name'] as String,
          ];
          _showSuggestions = _suggestions.isNotEmpty;
        });
      }
    }
  }

  void _selectSuggestion(String suggestion) {
    _addressController.text = suggestion;
    if (mounted) {
      setState(() {
        _showSuggestions = false;
      });
    }
    _searchAndRoute();
  }

  void _toggleCompassMode() {
    setState(() {
      _compassMode = !_compassMode;
    });

    if (_mapReady) {
      if (_compassMode) {
        // When entering compass mode, no auto-rotation is applied
        debugPrint('Compass mode enabled, user can rotate freely.');
      } else {
        // When exiting compass mode, no auto-rotation is applied
        debugPrint('Compass mode disabled, user can rotate freely.');
      }
    }
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _compassSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Navigation')),
      body: _pageLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_instructions.isNotEmpty)
                  _InstructionBar(instructions: _instructions),
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
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _addressController,
                              decoration: const InputDecoration(
                                labelText: 'Destination address',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: _updateSuggestions,
                              onSubmitted: (_) => _searchAndRoute(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _routeLoading ? null : _searchAndRoute,
                            child: _routeLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Route'),
                          ),
                        ],
                      ),
                      if (_showSuggestions)
                        Container(
                          constraints: const BoxConstraints(maxHeight: 180),
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _suggestions.length,
                            itemBuilder: (context, index) {
                              final s = _suggestions[index];
                              return ListTile(
                                title: Text(
                                  s,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontSize: 15),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () => _selectSuggestion(s),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                if (_userPosition == null && !_pageLoading)
                  const Expanded(
                    child: Center(child: Text('Waiting for user location...')),
                  )
                else if (_routePoints == null &&
                    !_pageLoading &&
                    !_routeLoading &&
                    _addressController.text.isNotEmpty)
                  Expanded(
                    child: Center(
                      child: Text(
                        'No route to "${_addressController.text}" found or error occurred.',
                      ),
                    ),
                  )
                else if (_routePoints == null &&
                    !_pageLoading &&
                    !_routeLoading)
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
                          center: _userPosition ?? const LatLng(0, 0),
                          zoom: _currentZoom,
                          onPositionChanged: (position, hasGesture) {
                            if (hasGesture && position.zoom != _currentZoom) {
                              setState(() {
                                _currentZoom = position.zoom ?? 0.0;
                              });
                            }
                          },
                        ),
                        children: [
                          fm.TileLayer(
                            urlTemplate:
                                'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                            subdomains: const ['a', 'b', 'c'],
                          ),
                          if (_dangerZonePolygons.isNotEmpty)
                            fm.PolygonLayer(polygons: _dangerZonePolygons),
                          fm.MarkerLayer(markers: _dangerZoneMarkers),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
      floatingActionButton: _userPosition != null
          ? FloatingActionButton(
              heroTag: "compass_toggle",
              onPressed: _toggleCompassMode,
              tooltip: _compassMode
                  ? 'Exit compass mode'
                  : 'Enter compass mode',
              backgroundColor: _compassMode ? Colors.orange : null,
              child: Icon(_compassMode ? Icons.explore : Icons.explore_off),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}

// Moved _InstructionBar to the top level
class _InstructionBar extends StatelessWidget {
  final List<dynamic> instructions;
  const _InstructionBar({required this.instructions});

  IconData _iconForInstruction(String sign) {
    switch (sign) {
      case '0':
        return Icons.arrow_upward; // continue
      case '1':
        return Icons.turn_slight_right;
      case '2':
        return Icons.turn_right;
      case '3':
        return Icons.turn_sharp_right;
      case '4':
        return Icons.rotate_right; // uturn right (fallback)
      case '-1':
        return Icons.turn_slight_left;
      case '-2':
        return Icons.turn_left;
      case '-3':
        return Icons.turn_sharp_left;
      case '-4':
        return Icons.rotate_left; // uturn left (fallback)
      case '5':
        return Icons.flag; // arrival
      default:
        return Icons.directions_walk;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (instructions.isEmpty) {
      return const SizedBox.shrink();
    }
    final visibleCount = 1;
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceVariant,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        children: [
          for (int i = 0; i < visibleCount && i < instructions.length; i++) ...[
            Icon(
              _iconForInstruction('${instructions[i]['sign']}'),
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                '${instructions[i]['text']} (${(instructions[i]['distance'] as num).toStringAsFixed(0)} m)',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (i < visibleCount - 1) const SizedBox(width: 16),
          ],
          const Spacer(),
          if (instructions.length > 1)
            TextButton(
              onPressed: () {},
              child: Text('Mehr'),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
        ],
      ),
    );
  }
}
