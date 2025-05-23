import 'package:flutter/material.dart';

class GraphHopperPocPage extends StatelessWidget {
  const GraphHopperPocPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Graph Hopper POC')),
      body: const Center(
        child: Text(
          'Graph Hopper POC Page',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
