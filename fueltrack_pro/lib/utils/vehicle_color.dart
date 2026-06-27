import 'package:flutter/material.dart';

/// Returns a stable accent color for a vehicle based on its [vehicleId].
/// Uses a fixed palette of 6 semantic Color values so that a vehicle
/// always renders the same color regardless of its position in a list.
Color vehicleAccentColor(int vehicleId, ColorScheme cs) {
  const paletteSize = 6;
  final index = vehicleId.abs() % paletteSize;
  return switch (index) {
    0 => cs.primary,
    1 => cs.secondary,
    2 => cs.tertiary,
    3 => const Color(0xFF6750A4), // Purple
    4 => const Color(0xFF0B6BE3), // Blue
    5 => const Color(0xFF267653), // Teal
    _ => cs.primary,
  };
}

/// Background tint for the vehicle color icon well (12 % opacity).
Color vehicleAccentBg(int vehicleId, ColorScheme cs) =>
    vehicleAccentColor(vehicleId, cs).withValues(alpha: 0.12);
