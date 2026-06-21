import 'package:flutter/material.dart' show IconData, Icons;

import '../models/enums.dart';

class RegionOption {
  const RegionOption({
    required this.code,
    required this.name,
    required this.currencyCode,
    required this.currencySymbol,
    required this.currencyName,
  });

  final String code;
  final String name;
  final String currencyCode;
  final String currencySymbol;
  final String currencyName;
}

abstract final class Regions {
  static const List<RegionOption> all = [
    RegionOption(
      code: 'OM',
      name: 'Oman',
      currencyCode: 'OMR',
      currencySymbol: 'OMR',
      currencyName: 'Omani Rial',
    ),
    RegionOption(
      code: 'AE',
      name: 'United Arab Emirates',
      currencyCode: 'AED',
      currencySymbol: 'AED',
      currencyName: 'UAE Dirham',
    ),
    RegionOption(
      code: 'SA',
      name: 'Saudi Arabia',
      currencyCode: 'SAR',
      currencySymbol: 'SAR',
      currencyName: 'Saudi Riyal',
    ),
    RegionOption(
      code: 'QA',
      name: 'Qatar',
      currencyCode: 'QAR',
      currencySymbol: 'QAR',
      currencyName: 'Qatari Riyal',
    ),
    RegionOption(
      code: 'US',
      name: 'United States',
      currencyCode: 'USD',
      currencySymbol: r'$',
      currencyName: 'US Dollar',
    ),
    RegionOption(
      code: 'GB',
      name: 'United Kingdom',
      currencyCode: 'GBP',
      currencySymbol: '£',
      currencyName: 'British Pound',
    ),
  ];

  static RegionOption byCode(String code) {
    return all.firstWhere(
      (r) => r.code == code,
      orElse: () => all.first,
    );
  }
}

class VehiclePreset {
  const VehiclePreset({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

abstract final class VehiclePresets {
  static const List<VehiclePreset> types = [
    VehiclePreset(label: 'Sedan', icon: Icons.directions_car_outlined),
    VehiclePreset(label: 'SUV', icon: Icons.directions_car_filled_outlined),
    VehiclePreset(label: 'Van', icon: Icons.airport_shuttle_outlined),
    VehiclePreset(label: 'EV', icon: Icons.electric_car_outlined),
    VehiclePreset(label: 'Bike', icon: Icons.two_wheeler_outlined),
  ];
}

class OnboardingDraft {
  const OnboardingDraft({
    this.vehicleType = 'SUV',
    this.make = '',
    this.model = '',
    this.year = '',
    this.licensePlate = '',
    this.fuelType = FuelType.diesel,
    this.regionCode = 'OM',
    this.useKm = true,
    this.useLiters = true,
  });

  final String vehicleType;
  final String make;
  final String model;
  final String year;
  final String licensePlate;
  final FuelType fuelType;
  final String regionCode;
  final bool useKm;
  final bool useLiters;

  RegionOption get region => Regions.byCode(regionCode);

  String get vehicleDisplayName {
    final trimmedMake = make.trim();
    final trimmedModel = model.trim();
    if (trimmedMake.isNotEmpty && trimmedModel.isNotEmpty) {
      return '$trimmedMake $trimmedModel';
    }
    if (trimmedModel.isNotEmpty) return trimmedModel;
    if (trimmedMake.isNotEmpty) return trimmedMake;
    return vehicleType;
  }

  OnboardingDraft copyWith({
    String? vehicleType,
    String? make,
    String? model,
    String? year,
    String? licensePlate,
    FuelType? fuelType,
    String? regionCode,
    bool? useKm,
    bool? useLiters,
  }) {
    return OnboardingDraft(
      vehicleType: vehicleType ?? this.vehicleType,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      licensePlate: licensePlate ?? this.licensePlate,
      fuelType: fuelType ?? this.fuelType,
      regionCode: regionCode ?? this.regionCode,
      useKm: useKm ?? this.useKm,
      useLiters: useLiters ?? this.useLiters,
    );
  }
}
