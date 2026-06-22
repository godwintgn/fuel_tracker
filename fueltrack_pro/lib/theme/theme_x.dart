import 'package:flutter/material.dart';

/// Convenience accessors for theme tokens so screens stay theme-aware
/// (correct in both light and dark mode) without verbose `Theme.of(context)`.
extension ThemeX on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get cs => Theme.of(this).colorScheme;
  TextTheme get tt => Theme.of(this).textTheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
