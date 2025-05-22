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
  final LatLng ziel = LatLng(48.9985932110444, 12.121423264124944); // Bajuwarenstraße 4, Regensburg (Beispiel-Koordinaten)
  List<LatLng> routePoints = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _initRoute();
  }

  Future<void> _initRoute() async {
    // Hole User-Standort
    final position = await _determinePosition();
    if (position == null) {
      setState(() => loading = false);
      return;
    }
    setState(() => _currentPosition = position);

    // Hole Route von GraphHopper
    try {
      final points = await GraphHopperApiManager().getRoute(_currentPosition!, ziel);
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
      appBar: AppBar(title: const Text('GraphHopper OSM Sandbox')),
      body: loading || _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              options: MapOptions(
                initialCenter: _currentPosition!,
                initialZoom: 14,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
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
                    // User-Standort mit eigenem Icon
                    Marker(
                      width: 50,
                      height: 50,
                      point: _currentPosition!,
                      child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 40),
                    ),
                    // Zielmarker
                    Marker(
                      width: 50,
                      height: 50,
                      point: ziel,
                      child: const Icon(Icons.flag, color: Colors.red, size: 40),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}