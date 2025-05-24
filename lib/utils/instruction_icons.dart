import 'package:flutter/material.dart';

IconData iconForInstruction(String sign) {
  switch (sign) {
    case '0':
      return Icons.arrow_upward; // continue
    case '1':
      return Icons.turn_slight_right;
    case '2':
      return Icons.turn_right;
    case '3':
      return Icons.turn_sharp_right;
    case '4':
      return Icons.rotate_right; // uturn right (fallback)
    case '-1':
      return Icons.turn_slight_left;
    case '-2':
      return Icons.turn_left;
    case '-3':
      return Icons.turn_sharp_left;
    case '-4':
      return Icons.rotate_left; // uturn left (fallback)
    case '5':
      return Icons.flag; // arrival
    default:
      return Icons.directions_walk;
  }
}
