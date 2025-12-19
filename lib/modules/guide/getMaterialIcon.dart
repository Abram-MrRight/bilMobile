import 'package:flutter/material.dart';

IconData getMaterialIcon(String? iconName) {
  switch (iconName) {
    case 'phone':
      return Icons.phone;
    case 'email':
      return Icons.email;
    case 'location_on':
      return Icons.location_on;
    case 'info_outline':
      return Icons.info_outline;
    default:
      return Icons.info_outline;
  }
}

Color getHexColor(String? hexColor) {
  if (hexColor == null || hexColor.isEmpty) return Colors.grey;
  return Color(int.parse(hexColor.replaceFirst('#', '0xff')));
}
