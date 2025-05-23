import 'package:flutter/material.dart';
import 'pages/navigation_page.dart'; // Updated import
import 'pages/placeholder_page.dart'; // Added import
import 'pages/settings_page.dart';

class NavScreenConfig {
  final String route;
  final String label;
  final IconData icon;
  final Widget Function() builder;
  final bool inNavBar;

  const NavScreenConfig({
    required this.route,
    required this.label,
    required this.icon,
    required this.builder,
    this.inNavBar = false,
  });
}

final List<NavScreenConfig> navScreens = [
  NavScreenConfig(
    route: '/placeholder', // Updated route
    label: 'Placeholder', // Updated label
    icon: Icons.help_outline, // Placeholder icon
    builder: () => const PlaceholderPage(), // Updated builder
    inNavBar: true,
  ),
  NavScreenConfig(
    route: '/navigation', // Updated route
    label: 'Navigation', // Updated label
    icon: Icons.navigation, // Updated icon
    builder: () => const NavigationPage(), // Updated builder
    inNavBar: true,
  ),
  NavScreenConfig(
    route: '/settings', // Updated route
    label: 'Settings', // Updated label
    icon: Icons.settings, // Updated icon
    builder: () => const SettingsPage(),
    inNavBar: true,
  ),
];
