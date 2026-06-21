import 'package:flutter/material.dart' show ThemeMode;

enum FuelType {
  petrol('Petrol'),
  diesel('Diesel'),
  electric('Electric'),
  hybrid('Hybrid'),
  lpg('LPG'),
  cng('CNG');

  const FuelType(this.label);
  final String label;

  static FuelType fromString(String value) {
    return FuelType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FuelType.petrol,
    );
  }
}

enum DistanceUnit {
  km('Kilometers', 'km'),
  miles('Miles', 'mi');

  const DistanceUnit(this.label, this.abbreviation);
  final String label;
  final String abbreviation;

  static DistanceUnit fromString(String value) {
    return DistanceUnit.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DistanceUnit.km,
    );
  }
}

enum FuelUnit {
  liters('Liters', 'L'),
  gallons('Gallons', 'gal');

  const FuelUnit(this.label, this.abbreviation);
  final String label;
  final String abbreviation;

  static FuelUnit fromString(String value) {
    return FuelUnit.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FuelUnit.liters,
    );
  }
}

enum ThemeModePreference {
  system('System'),
  light('Light'),
  dark('Dark');

  const ThemeModePreference(this.label);
  final String label;

  static ThemeModePreference fromString(String value) {
    return ThemeModePreference.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ThemeModePreference.system,
    );
  }

  ThemeMode toFlutterThemeMode() {
    return switch (this) {
      ThemeModePreference.system => ThemeMode.system,
      ThemeModePreference.light => ThemeMode.light,
      ThemeModePreference.dark => ThemeMode.dark,
    };
  }
}
