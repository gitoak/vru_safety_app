import 'package:flutter/material.dart';
import 'pages/graph_hopper_poc_page.dart';
import 'pages/home_page.dart';
import 'pages/sandbox_graphhopper_page.dart';
import 'pages/sandbox_page.dart';
import 'pages/settings_page.dart';
import 'pages/osm_poc_page.dart';

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
    route: '/',
    label: 'Home',
    icon: Icons.home,
    builder: () => const HomePage(),
    inNavBar: true,
  ),
  NavScreenConfig(
    route: '/settings',
    label: 'Settings',
    icon: Icons.settings,
    builder: () => const SettingsPage(),
    inNavBar: true,
  ),
  // Example for a non-navbar screen:
  // NavScreenConfig(
  //   route: '/details',
  //   label: 'Details',
  //   icon: Icons.info,
  //   builder: () => const DetailsPage(),
  //   inNavBar: false,
  // ),
  NavScreenConfig(
    route: "/sandbox",
    label: "Sandbox",
    icon: Icons.code,
    builder: () => const SandboxPage(),
    inNavBar: true,
  ),
  NavScreenConfig(
    route: '/osm-poc',
    label: 'OSM POC',
    icon: Icons.map,
    builder: () => const OsmPocPage(),
    inNavBar: false,
  ),
  // GraphHopperPocPage
  NavScreenConfig(
    route: '/graphhopper-poc',
    label: 'GraphHopper POC',
    icon: Icons.route_outlined,
    builder: () => const GraphHopperPocPage(),
    inNavBar: false,
  ),
  // SandboxGraphhopperPage
  NavScreenConfig(
    route: '/sandbox-graphhopper',
    label: 'GraphHopper Sandbox',
    icon: Icons.explore_outlined,
    builder: () => const SandboxGraphhopperPage(),
    inNavBar: false,
  ),
];
