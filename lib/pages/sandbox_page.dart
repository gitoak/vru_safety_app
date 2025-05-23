import 'package:flutter/material.dart';
import 'osm_poc_page.dart';
import 'graph_hopper_poc_page.dart';

class SandboxPage extends StatelessWidget {
  const SandboxPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Sandbox Page'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Navigate to OSM POC page
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const OsmPocPage()),
                );
              },
              child: const Text('Go to OSM POC Page'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Navigate to Graph Hopper POC page
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const GraphHopperPocPage()),
                );
              },
              child: const Text('Go to Graph Hopper POC Page'),
            ),
          ],
        ),
      ),
    );
  }
}