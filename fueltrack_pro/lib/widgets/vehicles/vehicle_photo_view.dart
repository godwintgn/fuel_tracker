import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/vehicle.dart';
import '../../theme/theme_x.dart';

/// Displays a vehicle photo or a placeholder icon.
class VehiclePhotoView extends StatelessWidget {
  const VehiclePhotoView({
    super.key,
    required this.vehicle,
    this.height = 140,
    this.fallbackIcon,
  });

  final Vehicle vehicle;
  final double height;
  final IconData? fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final path = vehicle.photoPath;

    if (path == null || path.isEmpty || !File(path).existsSync()) {
      return Container(
        height: height,
        width: double.infinity,
        color: cs.primary.withValues(alpha: 0.08),
        child: Center(
          child: Icon(
            fallbackIcon ?? Icons.directions_car_filled_outlined,
            size: 64,
            color: cs.primary.withValues(alpha: 0.45),
          ),
        ),
      );
    }

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Image.file(
        File(path),
        fit: BoxFit.cover,
        width: double.infinity,
        height: height,
      ),
    );
  }
}
