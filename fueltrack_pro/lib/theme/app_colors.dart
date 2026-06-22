import 'package:flutter/material.dart';

/// M3 color tokens extracted from the Stitch mockup DESIGN.md / HTML.
abstract final class AppColors {
  // Primary (green — efficiency)
  static const primary = Color(0xFF0D631B);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFF2E7D32);
  static const onPrimaryContainer = Color(0xFFCBFFC2);
  static const inversePrimary = Color(0xFF88D982);
  static const primaryFixed = Color(0xFFA3F69C);
  static const primaryFixedDim = Color(0xFF88D982);
  static const onPrimaryFixed = Color(0xFF002204);
  static const onPrimaryFixedVariant = Color(0xFF005312);
  static const surfaceTint = Color(0xFF1B6D24);

  // Secondary (blue — financial)
  static const secondary = Color(0xFF005FAF);
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFF54A0FE);
  static const onSecondaryContainer = Color(0xFF003567);
  static const secondaryFixed = Color(0xFFD4E3FF);
  static const secondaryFixedDim = Color(0xFFA5C8FF);
  static const onSecondaryFixed = Color(0xFF001C3A);
  static const onSecondaryFixedVariant = Color(0xFF004786);

  // Tertiary (orange — accents)
  static const tertiary = Color(0xFF884200);
  static const onTertiary = Color(0xFFFFFFFF);
  static const tertiaryContainer = Color(0xFFAD5600);
  static const onTertiaryContainer = Color(0xFFFFEEE6);
  static const tertiaryFixed = Color(0xFFFFDCC6);
  static const tertiaryFixedDim = Color(0xFFFFB786);

  // Surfaces (light)
  static const background = Color(0xFFFBF9F9);
  static const onBackground = Color(0xFF1B1C1C);
  static const surface = Color(0xFFFBF9F9);
  static const onSurface = Color(0xFF1B1C1C);
  static const onSurfaceVariant = Color(0xFF40493D);
  static const surfaceDim = Color(0xFFDBDAD9);
  static const surfaceBright = Color(0xFFFBF9F9);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF5F3F3);
  static const surfaceContainer = Color(0xFFEFEDED);
  static const surfaceContainerHigh = Color(0xFFE9E8E7);
  static const surfaceContainerHighest = Color(0xFFE3E2E2);
  static const surfaceVariant = Color(0xFFE3E2E2);
  static const inverseSurface = Color(0xFF303031);
  static const inverseOnSurface = Color(0xFFF2F0F0);

  // Outline & error
  static const outline = Color(0xFF707A6C);
  static const outlineVariant = Color(0xFFBFCABA);
  static const error = Color(0xFFBA1A1A);
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);

  // Dark mode surfaces (derived from M3 dark + mockup inverse tokens)
  static const darkBackground = Color(0xFF101413);
  static const darkSurface = Color(0xFF101413);
  static const darkSurfaceContainerLowest = Color(0xFF0B0F0E);
  static const darkSurfaceContainerLow = Color(0xFF181D1B);
  static const darkSurfaceContainer = Color(0xFF1C2220);
  static const darkSurfaceContainerHigh = Color(0xFF272D2B);
  static const darkSurfaceContainerHighest = Color(0xFF323836);
  static const darkOnSurface = Color(0xFFE2E3E0);
  static const darkOnSurfaceVariant = Color(0xFFBEC9BD);
  static const darkOutline = Color(0xFF889387);
  static const darkOutlineVariant = Color(0xFF3F4A40);
}
