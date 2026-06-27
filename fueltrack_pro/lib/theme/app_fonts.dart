import 'package:flutter/material.dart';

/// Bundled OFL fonts (Manrope + Inter) — no runtime network fetch (F-Droid friendly).
abstract final class AppFonts {
  static const manrope = 'Manrope';
  static const inter = 'Inter';

  static TextStyle manropeStyle({
    required FontWeight fontWeight,
    required Color color,
    double? fontSize,
  }) {
    return TextStyle(
      fontFamily: manrope,
      fontWeight: fontWeight,
      color: color,
      fontSize: fontSize,
    );
  }

  static TextStyle interStyle({
    required FontWeight fontWeight,
    required Color color,
    double? fontSize,
  }) {
    return TextStyle(
      fontFamily: inter,
      fontWeight: fontWeight,
      color: color,
      fontSize: fontSize,
    );
  }
}
