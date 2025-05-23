import 'package:flutter/material.dart';

final ThemeData appTheme = ThemeData(
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color.fromARGB(255, 72, 56, 99),
    brightness: Brightness.dark,
  ),
  scaffoldBackgroundColor: const Color(0xFF181828),
  useMaterial3: true,
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.white),
    bodyMedium: TextStyle(color: Colors.white70),
    titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF23233A),
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  cardColor: const Color(0xFF23233A),
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFF23233A),
    border: OutlineInputBorder(),
    hintStyle: TextStyle(color: Colors.white54),
  ),
);
