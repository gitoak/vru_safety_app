import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/nav_bloc.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Define a minimum size for tap targets
    const minButtonSize = Size(48, 48);
    // Define a style for ElevatedButton to ensure minimum tap target size
    final ButtonStyle minSizeButtonStyle = ElevatedButton.styleFrom(
      minimumSize: minButtonSize,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Ensure padding contributes to size
    );

    return Center(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Home Page',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text('Welcome to the VRU Safety App!'),
          const SizedBox(height: 16),
          const Text('This app helps visually impaired users navigate safely.'),
          const SizedBox(height: 32),
          
          // Example of programmatic navigation using NavBloc
          const Text(
            'Programmatic Navigation Examples:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          ElevatedButton(
            style: minSizeButtonStyle,
            onPressed: () {
              // Navigate to Sandbox tab programmatically
              context.read<NavBloc>().navigateToMainPage(AppPage.sandbox);
            },
            child: const Text('Go to Sandbox (Main Tab)'),
          ),
          const SizedBox(height: 8),
          
          ElevatedButton(
            style: minSizeButtonStyle,
            onPressed: () {
              // Navigate to Settings tab and then push a sub-page
              context.read<NavBloc>().navigateToMainPage(AppPage.settings);
              // You could also push a sub-page if Settings had any:
              // context.read<NavBloc>().pushSubPage('/some-settings-subpage');
            },
            child: const Text('Go to Settings'),
          ),
          const SizedBox(height: 8),
          
          ElevatedButton(
            style: minSizeButtonStyle,
            onPressed: () {
              // Navigate to Sandbox and then immediately push a sub-page
              context.read<NavBloc>().navigateToMainPage(AppPage.sandbox);
              // Add a small delay to ensure the main page navigation completes
              Future.delayed(const Duration(milliseconds: 100), () {
                context.read<NavBloc>().pushSubPage('/osm-poc');
              });
            },
            child: const Text('Go to OSM POC (via Sandbox)'),
          ),
          const SizedBox(height: 16),
          
          const Text(
            'Navigation State:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          
          // Show current navigation state
          BlocBuilder<NavBloc, NavState>(
            builder: (context, state) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Current Main Page: ${state.mainPage.name}'),
                      Text('Sub-page Stack: ${state.subPageStack.isEmpty ? 'Empty' : state.subPageStack.join(' → ')}'),
                      Text('Has Sub-pages: ${state.hasSubPages}'),
                      if (state.currentSubPage != null)
                        Text('Current Sub-page: ${state.currentSubPage}'),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
