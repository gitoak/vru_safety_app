import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import './danger_zone_alert_system.dart';

class GraphHopperPocPage extends StatefulWidget {
  const GraphHopperPocPage({super.key});

  @override
  State<GraphHopperPocPage> createState() => _GraphHopperPocPageState();
}

class _GraphHopperPocPageState extends State<GraphHopperPocPage> {
  List<LatLng>? _routePoints;
  bool _loading = false;
  String? _error;
  LatLng? _userPosition;
  LatLng? _destinationPosition;
  final TextEditingController _addressController = TextEditingController();
  List<String> _suggestions = [];
  bool _showSuggestions = false;
  List<dynamic> _instructions = [];

  @override
  void initState() {
    super.initState();
    _fetchUserAndRoute();
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserAndRoute() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Get user location
      final position = await Geolocator.getCurrentPosition();
      final userLatLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _userPosition = userLatLng;
      });
      // Fetch route from user to fixed end
      final response = await http.get(
        Uri.parse(
          'https://graphhopper.jannik.dev/route?point=${userLatLng.latitude},${userLatLng.longitude}&point=49.019,12.102&profile=foot&locale=en&instructions=true',
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final path = data['paths'][0];
        final points = path['points'];
        final decoded = _decodePolyline(points);
        setState(() {
          _routePoints = decoded;
          _instructions = path['instructions'] ?? [];
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to fetch route:  ${response.statusCode}';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _loading = false;
      });
    }
  }

  // Polyline decoding for GraphHopper encoded polyline
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;
    int shift = 0, result = 0;
    int b;
    int factor = 100000;
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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Geocode address to LatLng
      final address = _addressController.text.trim();
      if (address.isEmpty) {
        setState(() {
          _error = 'Please enter a destination address.';
          _loading = false;
        });
        return;
      }
      final geoResp = await http.get(Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(address)}&format=json&limit=1',
      ));
      if (geoResp.statusCode == 200) {
        final geoData = json.decode(geoResp.body);
        if (geoData.isEmpty) {
          setState(() {
            _error = 'Address not found.';
            _loading = false;
          });
          return;
        }
        final lat = double.parse(geoData[0]['lat']);
        final lon = double.parse(geoData[0]['lon']);
        _destinationPosition = LatLng(lat, lon);
      } else {
        setState(() {
          _error = 'Geocoding failed.';
          _loading = false;
        });
        return;
      }
      // Get user location
      final position = await Geolocator.getCurrentPosition();
      final userLatLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _userPosition = userLatLng;
      });
      // Fetch route from user to destination
      final response = await http.get(
        Uri.parse(
          'https://graphhopper.jannik.dev/route?point=${userLatLng.latitude},${userLatLng.longitude}&point=${_destinationPosition!.latitude},${_destinationPosition!.longitude}&profile=foot&locale=en&instructions=true',
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final path = data['paths'][0];
        final points = path['points'];
        final decoded = _decodePolyline(points);
        setState(() {
          _routePoints = decoded;
          _instructions = path['instructions'] ?? [];
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to fetch route:  ${response.statusCode}';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _loading = false;
      });
    }
  }

  Future<void> _updateSuggestions(String input) async {
    if (input.isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }
    final resp = await http.get(Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(input)}&format=json&addressdetails=1&limit=5',
    ));
    if (resp.statusCode == 200) {
      final data = json.decode(resp.body);
      setState(() {
        _suggestions = [
          for (final item in data) item['display_name'] as String
        ];
        _showSuggestions = _suggestions.isNotEmpty;
      });
    }
  }

  void _selectSuggestion(String suggestion) {
    _addressController.text = suggestion;
    setState(() {
      _showSuggestions = false;
    });
    _searchAndRoute();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Graph Hopper POC')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_instructions.isNotEmpty)
                  StatefulBuilder(
                    builder: (context, setBarState) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _InstructionBar(
                            instructions: _instructions,
                          ),
                        ],
                      );
                    },
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                  child: DangerZoneAlertSystem(
                    dangerousPolygons: [
                      [
                        LatLng(49.010, 12.098),
                        LatLng(49.019, 12.098),
                        LatLng(49.019, 12.102),
                        LatLng(49.010, 12.102),
                        LatLng(49.010, 12.098),
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
                            onPressed: _searchAndRoute,
                            child: const Text('Route'),
                          ),
                        ],
                      ),
                      if (_showSuggestions)
                        Container(
                          constraints: const BoxConstraints(maxHeight: 180),
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            border: Border.all(color: Colors.white24),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListView(
                            shrinkWrap: true,
                            children: [
                              for (final s in _suggestions)
                                ListTile(
                                  title: Text(
                                    s,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 15),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  tileColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  onTap: () => _selectSuggestion(s),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(_error!, style: const TextStyle(color: Colors.red)),
                  ),
                if (_routePoints == null || _userPosition == null)
                  const Expanded(child: Center(child: Text('No route loaded')))
                else
                  Expanded(
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: _userPosition!,
                        initialZoom: 15.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                          subdomains: const ['a', 'b', 'c'],
                        ),
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _routePoints!,
                              color: Colors.blue,
                              strokeWidth: 5.0,
                            ),
                          ],
                        ),
                        PolygonLayer(
                          polygons: [
                            Polygon(
                              points: [
                                LatLng(49.010, 12.098), // southwest
                                LatLng(49.019, 12.098), // northwest
                                LatLng(49.019, 12.102), // northeast
                                LatLng(49.010, 12.102), // southeast
                                LatLng(49.010, 12.098), // back to southwest
                              ],
                              color: Colors.red.withOpacity(0.3),
                              borderColor: Colors.red,
                              borderStrokeWidth: 3,
                            ),
                          ],
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              width: 60.0,
                              height: 60.0,
                              point: _userPosition!,
                              child: const Icon(
                                Icons.location_history_rounded,
                                color: Colors.blue,
                                size: 30,
                              ),
                            ),
                            if (_destinationPosition != null)
                              Marker(
                                width: 60.0,
                                height: 60.0,
                                point: _destinationPosition!,
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.red,
                                  size: 30,
                                ),
                              ),
                            if (_routePoints != null && _routePoints!.isNotEmpty && _destinationPosition == null)
                              Marker(
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
              ],
            ),
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
    final visibleCount = expanded ? (widget.instructions.length < 4 ? widget.instructions.length : 4) : 1;
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceVariant,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        children: [
          for (int i = 0; i < visibleCount; i++) ...[
            Icon(_iconForInstruction('${widget.instructions[i]['sign']}'), color: Colors.white, size: 22),
            const SizedBox(width: 4),
            Text(
              '${widget.instructions[i]['text']} (${(widget.instructions[i]['distance'] as num).toStringAsFixed(0)} m)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
            ),
            if (i < visibleCount - 1)
              const SizedBox(width: 16),
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
