import 'package:flutter/material.dart';
import 'package:vru_safety_app/pages/sandbox_graphhopper_page.dart';
import 'graph_hopper_poc_page.dart';
import 'osm_poc_page.dart';
import '../navigation_config.dart';
import '../bloc/nav_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SandboxPage extends StatelessWidget {
  const SandboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sandbox Page')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Sandbox Page'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final idx = navScreens.indexWhere((s) => s.route == '/osm-poc');
                if (idx != -1) {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => navScreens[idx].builder()),
                  );
                }
              },
              child: const Text('Go to OSM POC Page'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final idx = navScreens.indexWhere((s) => s.route == '/sandbox-graphhopper');
                if (idx != -1) {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => navScreens[idx].builder()),
                  );
                }
              },
              child: const Text('Go to GraphHopper Sandbox'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final idx = navScreens.indexWhere((s) => s.route == '/graphhopper-poc');
                if (idx != -1) {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => navScreens[idx].builder()),
                  );
                }
              },
              child: const Text('Go to Graph Hopper POC Page'),
            ),
          ],
        ),
      ),
    );
  }
}
