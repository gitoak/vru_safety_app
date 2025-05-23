import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class OsmPocPage extends StatefulWidget {
  const OsmPocPage({super.key});

  @override
  State<OsmPocPage> createState() => _OsmPocPageState();
}

class _OsmPocPageState extends State<OsmPocPage> {
  LatLng? _currentPosition;
  StreamSubscription<Position>? _positionStreamSubscription;
  final MapController _mapController = MapController();
  bool _isLoading = true;
  double _initialZoom = 16.0;

  @override
  void initState() {
    super.initState();
    _initializeLocationStream();
  }

  Future<void> _initializeLocationStream() async {
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
        setState(() => _isLoading = false);
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
          setState(() => _isLoading = false);
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location permissions are permanently denied, we cannot request permissions.',
            ),
          ),
        );
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      Position initialPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(
            initialPosition.latitude,
            initialPosition.longitude,
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error getting initial position: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting initial location: $e')),
        );
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
                _currentPosition = newPosition;
              });
              _mapController.move(newPosition, _mapController.camera.zoom);
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
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OSM POC Page (Live Location)')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentPosition == null
          ? const Center(
              child: Text(
                'Unable to fetch location. Please check permissions and services.',
              ),
            )
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentPosition ?? const LatLng(0, 0),
                initialZoom: _initialZoom,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                ),
                if (_currentPosition != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        width: 80.0,
                        height: 80.0,
                        point: _currentPosition!,
                        child: const Icon(
                          Icons.my_location_sharp,
                          color: Colors.blue,
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
