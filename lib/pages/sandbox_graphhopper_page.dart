import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../services/graphhopper_api_manager.dart';

class SandboxGraphhopperPage extends StatefulWidget {
  const SandboxGraphhopperPage({Key? key}) : super(key: key);

  @override
  State<SandboxGraphhopperPage> createState() => _SandboxGraphhopperPageState();
}

class _SandboxGraphhopperPageState extends State<SandboxGraphhopperPage> {
  LatLng? _currentPosition;
  final LatLng ziel = LatLng(
    48.9985932110444,
    12.121423264124944,
  ); // Bajuwarenstraße 4, Regensburg
  List<LatLng> routePoints = [];
  bool loading = true;
  bool safeRoute = true;

  // Gefährliche Bereiche als Polygone (Vielecke)
final List<List<LatLng>> dangerousPolygons = [
  //one with 6 corners
  [
    LatLng(49.0018, 12.1106), // oben links
    LatLng(49.0018, 12.1119), // oben rechts
    LatLng(49.0016, 12.1119), // unten rechts
    LatLng(49.0016, 12.1106), // unten links
    LatLng(49.0017, 12.1107), // Punkt in der Mitte
    LatLng(49.0018, 12.1106), // zurück zum Startpunkt
  ],
];

  // Hilfsfunktion: Alle Polygonpunkte als Liste für block_area
  List<LatLng> getAllPolygonPoints(List<List<LatLng>> polygons) =>
      polygons.expand((poly) => poly).toList();

  @override
  void initState() {
    super.initState();
    _initRoute();
  }

  Future<void> _initRoute() async {
    setState(() {
      loading = true;
      routePoints = [];
    });
    final position = await _determinePosition();
    if (position == null) {
      setState(() => loading = false);
      return;
    }
    setState(() => _currentPosition = position);

    try {
      // Route mit oder ohne avoidPoints (Polygone) berechnen
      List<LatLng> points = await GraphHopperApiManager().getRoute(
        _currentPosition!,
        ziel,
        avoidPoints: safeRoute ? getAllPolygonPoints(dangerousPolygons) : null,
      );
      setState(() {
        routePoints = points;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Laden der Route: $e')),
      );
    }
  }

  Future<LatLng?> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    final pos = await Geolocator.getCurrentPosition();
    return LatLng(pos.latitude, pos.longitude);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fußgänger-Route zu Bajuwarenstraße 4'),
        actions: [
          Row(
            children: [
              const Text('Safe Route', style: TextStyle(fontSize: 16)),
              Switch(
                value: safeRoute,
                onChanged: (val) {
                  setState(() => safeRoute = val);
                  _initRoute();
                },
              ),
            ],
          ),
        ],
      ),
      body: loading || _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              options: MapOptions(
                initialCenter: _currentPosition!,
                initialZoom: 14,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                ),
                // Gefahren-Polygone als Flächen
                PolygonLayer(
                  polygons: [
                    ...dangerousPolygons.map(
                      (poly) => Polygon(
                        points: poly,
                        color: Colors.red.withOpacity(
                          0.5,
                        ), // weniger transparent
                        borderStrokeWidth: 4, // dickere Linie
                        borderColor: Colors.red,
                      ),
                    ),
                  ],
                ),
                PolylineLayer(
                  polylines: [
                    if (routePoints.isNotEmpty)
                      Polyline(
                        points: routePoints,
                        color: Colors.blue,
                        strokeWidth: 4.0,
                      ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    // User-Standort
                    Marker(
                      width: 50,
                      height: 50,
                      point: _currentPosition!,
                      child: const Icon(
                        Icons.person_pin_circle,
                        color: Colors.blue,
                        size: 40,
                      ),
                    ),
                    // Zielmarker
                    Marker(
                      width: 50,
                      height: 50,
                      point: ziel,
                      child: const Icon(
                        Icons.flag,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
