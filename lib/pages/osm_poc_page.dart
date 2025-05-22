import 'package:flutter/material.dart';

class OsmPocPage extends StatelessWidget {
  const OsmPocPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OSM POC Page')),
      body: const Center(
        child: Text(
          'OSM POC Page',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
