import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class GraphHopperApiManager {
  final String apiKey = 'a6d22ad1-af76-40af-a9ef-d331e7754cf6';

  Future<List<LatLng>> getRoute(
    LatLng start,
    LatLng end, {
    List<LatLng>? avoidPoints,
  }) async {
    String blockArea = '';
    if (avoidPoints != null && avoidPoints.isNotEmpty) {
      blockArea = '&block_area=' +
          avoidPoints.map((p) => '${p.latitude},${p.longitude}').join(',');
    }

    final url =
        'https://graphhopper.com/api/1/route?point=${start.latitude},${start.longitude}'
        '&point=${end.latitude},${end.longitude}'
        '&vehicle=foot&points_encoded=false'
        '$blockArea'
        '&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final points = data['paths'][0]['points']['coordinates'] as List;
      return points
          .map<LatLng>((p) => LatLng(p[1] as double, p[0] as double))
          .toList();
    } else {
      throw Exception('Failed to load route');
    }
  }
}