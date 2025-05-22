import 'package:flutter/material.dart';
import 'package:vru_safety_app/pages/sandbox_graphhopper_page.dart';
import 'osm_poc_page.dart';

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
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const OsmPocPage()));
              },
              child: const Text('Go to OSM POC Page'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SandboxGraphhopperPage(),
                  ),
                );
              },
              child: const Text('Go to GraphHopper Sandbox'),
            ),
          ],
        ),
      ),
    );
  }
}
