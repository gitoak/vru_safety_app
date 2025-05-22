import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ListView(
        children: [
          Text('Home Page'),
          Text('Welcome to the Home Page!'),
          Text('This is a simple example of a ListView.'),
          Text('You can add more items here.'),
          Text('Enjoy your stay!'),
        ],
      ),
    );
  }
}
