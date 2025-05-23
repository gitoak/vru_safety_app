import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class GraphHopperPocPage extends StatefulWidget {
  const GraphHopperPocPage({super.key});

  @override
  State<GraphHopperPocPage> createState() => _GraphHopperPocPageState();
}

class _GraphHopperPocPageState extends State<GraphHopperPocPage> {
  List<LatLng>? _routePoints;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchRoute();
  }

  Future<void> _fetchRoute() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await http.get(
        Uri.parse(
          'https://graphhopper.jannik.dev/route?point=49.010,12.098&point=49.019,12.102&profile=foot&locale=en&instructions=true',
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final path = data['paths'][0];
        final points = path['points'];
        final decoded = _decodePolyline(points);
        setState(() {
          _routePoints = decoded;
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to fetch route: {response.statusCode}';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Graph Hopper POC')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _routePoints == null
          ? const Center(child: Text('No route loaded'))
          : FlutterMap(
              options: MapOptions(
                initialCenter: _routePoints!.isNotEmpty
                    ? _routePoints!.first
                    : LatLng(52.517, 13.388),
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
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 60.0,
                      height: 60.0,
                      point: _routePoints!.first,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.green,
                        size: 30,
                      ),
                    ),
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
    );
  }
}
