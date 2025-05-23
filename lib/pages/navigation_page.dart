import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm; // Aliased import
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import './danger_zone_alert_system.dart';

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
  double _userHeading = 0.0; // Heading from compass
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

  List<fm.Polygon<Object>>
  _dangerZonePolygons = // Explicitly type with <Object>
      []; // Added for storing loaded danger zones

  @override
  void initState() {
    super.initState();
    _initializePage();
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
        ).listen(
          (Position position) {
            if (mounted) {
              final newPosition = LatLng(position.latitude, position.longitude);
              setState(() {
                _userPosition = newPosition;
              });
              if (_mapReady) {
                _mapController.move(newPosition, _mapController.camera.zoom);
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
          _userHeading = heading; // Always store the heading
        });

        // In compass mode, rotate the map instead of the marker
        if (_compassMode && _mapReady && _userPosition != null) {
          _mapController.rotate(heading); // Add 180° to fix orientation
        }
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
      debugPrint('Starting to load danger zones...');

      // For now, use fallback polygons due to shapefile package compatibility issues
      // TODO: Fix shapefile loading when package is compatible
      _loadFallbackDangerZones();

      // Commented out shapefile loading code until package compatibility is resolved
      /*
      try {
        final ByteData shpData = await rootBundle.load('assets/roads/datei.shp');
        final ByteData dbfData = await rootBundle.load('assets/roads/datei.dbf');

        debugPrint('Successfully loaded shapefile assets');

        // Shapefile processing code would go here
        // when the package compatibility issues are resolved
        
      } catch (shapefileError) {
        debugPrint('Shapefile loading failed: $shapefileError');
        _loadFallbackDangerZones();
      }
      */
    } catch (e, s) {
      debugPrint('Error loading danger zones: $e');
      debugPrint('Stack trace for danger zone loading error: $s');
      _loadFallbackDangerZones();
    }
  }

  void _loadFallbackDangerZones() {
    debugPrint('Loading fallback danger zones...');
    List<fm.Polygon<Object>> fallbackPolygons = [
      fm.Polygon<Object>(
        points: [
          const LatLng(49.010, 12.098),
          const LatLng(49.019, 12.098),
          const LatLng(49.019, 12.102),
          const LatLng(49.010, 12.102),
        ],
        color: Colors.red.withOpacity(0.3),
        borderColor: Colors.red,
        borderStrokeWidth: 2.0,
      ),
      // Add another test polygon
      fm.Polygon<Object>(
        points: [
          const LatLng(49.015, 12.100),
          const LatLng(49.017, 12.100),
          const LatLng(49.017, 12.103),
          const LatLng(49.015, 12.103),
        ],
        color: Colors.orange.withOpacity(0.3),
        borderColor: Colors.orange,
        borderStrokeWidth: 2.0,
      ),
    ];

    if (mounted) {
      setState(() {
        _dangerZonePolygons = fallbackPolygons;
      });
      debugPrint(
        'Loaded ${_dangerZonePolygons.length} fallback danger zone polygons.',
      );
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

  void _centerMapOnCurrentPosition() {
    if (_userPosition != null && _mapReady) {
      // Center the map on user position with appropriate zoom
      _mapController.move(
        _userPosition!,
        18.0,
      );

      // Ensure the map rotation matches the user's heading
      if (_compassMode) {
        _mapController.rotate(-_userHeading);
      } else {
        _mapController.rotate(0.0); // Reset rotation if not in compass mode
      }
    }
  }

  void _toggleCompassMode() {
    setState(() {
      _compassMode = !_compassMode;
    });

    if (_mapReady) {
      if (_compassMode) {
        // When entering compass mode, rotate map to current heading
        _mapController.rotate(-_userHeading); // Correct rotation without 180° adjustment
      } else {
        // When exiting compass mode, reset map rotation
        _mapController.rotate(0.0);
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
      appBar: AppBar(
        title: const Text('Navigation'), // Changed title from old one to 'Navigation'
      ),
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
                            border: Border.all(
                              color: Colors.grey.shade300,
                            ), // Adjusted border color
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(
                                  0.1,
                                ), // Softer shadow
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListView.builder(
                            // Changed to ListView.builder for efficiency
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
                      padding: const EdgeInsets.only(
                        bottom: 80.0,
                      ), // Add padding to avoid overlap with FloatingActionButton
                      child: fm.FlutterMap(
                        // Use fm. alias
                        mapController: _mapController,
                        options: fm.MapOptions(
                          // Use fm. alias
                          initialCenter: _userPosition ?? const LatLng(0, 0),
                          initialZoom: _currentZoom,
                          onPositionChanged:
                              (fm.MapCamera camera, bool hasGesture) {
                                // Use fm. alias
                                if (hasGesture) {
                                  if (camera.zoom != _currentZoom) {
                                    if (mounted) {
                                      setState(() {
                                        _currentZoom = camera.zoom;
                                      });
                                    }
                                  }
                                }
                              },
                          onMapEvent: (fm.MapEvent event) {
                            // Use fm. alias
                            // Can listen to other map events if needed
                          },
                          onMapReady: () {
                            if (mounted) {
                              setState(() {
                                _mapReady = true;
                              });
                              debugPrint(
                                "Map is ready. User position: $_userPosition, Zoom: $_currentZoom",
                              );
                              if (_userPosition != null) {
                                _mapController.move(
                                  _userPosition!,
                                  _currentZoom,
                                );
                              }
                            }
                          },
                        ),
                        children: [
                          fm.TileLayer(
                            urlTemplate:
                                'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                            subdomains: const ['a', 'b', 'c'],
                          ),
                          if (_routePoints != null)
                            fm.PolylineLayer(
                              polylines: [
                                fm.Polyline(
                                  points: _routePoints!,
                                  color: Colors.blue,
                                  strokeWidth: 5.0,
                                ),
                              ],
                            ),
                          if (_dangerZonePolygons.isNotEmpty)
                            fm.PolygonLayer(
                              polygons: _dangerZonePolygons,
                              polygonCulling: true,
                            )
                          else
                            fm.PolygonLayer(
                              // Fallback
                              polygons: [
                                fm.Polygon<Object>(
                                  // Explicitly type with <Object>
                                  points: [
                                    const LatLng(49.010, 12.098),
                                    const LatLng(49.019, 12.098),
                                    const LatLng(49.019, 12.102),
                                    const LatLng(49.010, 12.102),
                                    const LatLng(49.010, 12.098),
                                  ],
                                  color: Colors.orange.withOpacity(
                                    0.3,
                                  ), // Fill color
                                  borderColor: Colors.orange,
                                  borderStrokeWidth:
                                      3.0, // Explicit double, no isFilled/filled
                                ),
                              ],
                            ),
                          fm.MarkerLayer(
                            // Use fm. alias
                            markers: [
                              if (_userPosition != null)
                                fm.Marker(
                                  // Use fm. alias
                                  width: 60.0,
                                  height: 60.0,
                                  point: _userPosition!,
                                  child: Transform.rotate(
                                    angle: _compassMode
                                        ? 0.0
                                        : (_userHeading) * (math.pi / 180),
                                    child: const Icon(
                                      Icons.navigation,
                                      color: Colors.blue,
                                      size: 30,
                                    ),
                                  ),
                                ),
                              if (_destinationPosition != null)
                                fm.Marker(
                                  // Use fm. alias
                                  width: 60.0,
                                  height: 60.0,
                                  point: _destinationPosition!,
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Colors.red,
                                    size: 30,
                                  ),
                                ),
                              if (_routePoints != null &&
                                  _routePoints!.isNotEmpty &&
                                  _destinationPosition == null)
                                fm.Marker(
                                  // Use fm. alias
                                  width: 60.0,
                                  height: 60.0,
                                  point: _routePoints!.last,
                                  child: const Icon(
                                    Icons.flag,
                                    color: Colors.red,
                                    size: 30,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
      floatingActionButton: _userPosition != null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: "compass_toggle",
                  onPressed: _toggleCompassMode,
                  tooltip: _compassMode
                      ? 'Exit compass mode'
                      : 'Enter compass mode',
                  backgroundColor: _compassMode ? Colors.orange : null,
                  child: Icon(_compassMode ? Icons.explore : Icons.explore_off),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: "center_location",
                  onPressed: _centerMapOnCurrentPosition,
                  tooltip: 'Center on my location',
                  child: const Icon(Icons.my_location),
                ),
              ],
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}

class _InstructionBar extends StatefulWidget {
  final List<dynamic> instructions;
  const _InstructionBar({required this.instructions});

  @override
  State<_InstructionBar> createState() => _InstructionBarState();
}

class _InstructionBarState extends State<_InstructionBar> {
  bool expanded = false;

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
    if (widget.instructions.isEmpty) {
      return const SizedBox.shrink();
    }
    final visibleCount = expanded
        ? (widget.instructions.length < 4 ? widget.instructions.length : 4)
        : 1;
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceVariant,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        children: [
          for (
            int i = 0;
            i < visibleCount && i < widget.instructions.length;
            i++
          ) ...[
            Icon(
              _iconForInstruction('${widget.instructions[i]['sign']}'),
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                '${widget.instructions[i]['text']} (${(widget.instructions[i]['distance'] as num).toStringAsFixed(0)} m)',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (i < visibleCount - 1) const SizedBox(width: 16),
          ],
          const Spacer(),
          if (widget.instructions.length > 1)
            TextButton(
              onPressed: () => setState(() => expanded = !expanded),
              child: Text(expanded ? 'Weniger' : 'Mehr'),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
        ],
      ),
    );
  }
}
