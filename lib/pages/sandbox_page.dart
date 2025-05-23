import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/nav_bloc.dart';

class SandboxPage extends StatelessWidget {
  const SandboxPage({super.key});

  void _navigateTo(BuildContext context, String route) {
    // Use NavBloc to push a sub-page
    context.read<NavBloc>().add(NavPushSubPage(route));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sandbox Page')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Sandbox Page Content'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _navigateTo(context, '/osm-poc');
              },
              child: const Text('Go to OSM POC Page'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _navigateTo(context, '/sandbox-graphhopper');
              },
              child: const Text('Go to GraphHopper Sandbox'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _navigateTo(context, '/graphhopper-poc');
              },
              child: const Text('Go to Graph Hopper POC Page'),
            ),
          ],
        ),
      ),
    );
  }
}
