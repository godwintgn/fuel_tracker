import 'enums.dart';

class AppSettings {
  const AppSettings({
    this.id = 1,
    this.currencyCode = 'OMR',
    this.currencySymbol = 'OMR',
    this.countryCode = 'OM',
    this.distanceUnit = DistanceUnit.km,
    this.fuelUnit = FuelUnit.liters,
    this.themeMode = ThemeModePreference.system,
    this.onboardingCompleted = false,
    this.selectedVehicleId,
    required this.updatedAt,
  });

  final int id;
  final String currencyCode;
  final String currencySymbol;
  final String countryCode;
  final DistanceUnit distanceUnit;
  final FuelUnit fuelUnit;
  final ThemeModePreference themeMode;
  final bool onboardingCompleted;
  final int? selectedVehicleId;
  final DateTime updatedAt;

  AppSettings copyWith({
    int? id,
    String? currencyCode,
    String? currencySymbol,
    String? countryCode,
    DistanceUnit? distanceUnit,
    FuelUnit? fuelUnit,
    ThemeModePreference? themeMode,
    bool? onboardingCompleted,
    int? selectedVehicleId,
    DateTime? updatedAt,
    bool clearSelectedVehicle = false,
  }) {
    return AppSettings(
      id: id ?? this.id,
      currencyCode: currencyCode ?? this.currencyCode,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      countryCode: countryCode ?? this.countryCode,
      distanceUnit: distanceUnit ?? this.distanceUnit,
      fuelUnit: fuelUnit ?? this.fuelUnit,
      themeMode: themeMode ?? this.themeMode,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      selectedVehicleId:
          clearSelectedVehicle ? null : (selectedVehicleId ?? this.selectedVehicleId),
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'currency_code': currencyCode,
      'currency_symbol': currencySymbol,
      'country_code': countryCode,
      'distance_unit': distanceUnit.name,
      'fuel_unit': fuelUnit.name,
      'theme_mode': themeMode.name,
      'onboarding_completed': onboardingCompleted ? 1 : 0,
      'selected_vehicle_id': selectedVehicleId,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      id: map['id'] as int? ?? 1,
      currencyCode: map['currency_code'] as String? ?? 'OMR',
      currencySymbol: map['currency_symbol'] as String? ?? 'OMR',
      countryCode: map['country_code'] as String? ?? 'OM',
      distanceUnit: DistanceUnit.fromString(map['distance_unit'] as String? ?? 'km'),
      fuelUnit: FuelUnit.fromString(map['fuel_unit'] as String? ?? 'liters'),
      themeMode: ThemeModePreference.fromString(map['theme_mode'] as String? ?? 'system'),
      onboardingCompleted: (map['onboarding_completed'] as int? ?? 0) == 1,
      selectedVehicleId: map['selected_vehicle_id'] as int?,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        map['updated_at'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  static AppSettings defaults() {
    return AppSettings(updatedAt: DateTime.now());
  }
}
