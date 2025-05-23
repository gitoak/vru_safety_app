import 'package:flutter/material.dart';
import 'package:vru_safety_app/pages/sandbox_graphhopper_page.dart';
import 'osm_poc_page.dart';
import '../navigation_config.dart';
import '../bloc/nav_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SandboxPage extends StatelessWidget {
  const SandboxPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sandbox Page'),
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () {
            // Use Bloc navigation to go to Home (or any other route from navigation_config.dart)
            final homeIndex = navScreens.indexWhere((s) => s.route == '/');
            if (homeIndex != -1) {
              context.read<NavBloc>().add(NavTo(AppPage.values[homeIndex]));
            }
          },
        ),
      ),
      body: Center(
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
