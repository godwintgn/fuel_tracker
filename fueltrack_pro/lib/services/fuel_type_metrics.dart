import '../models/enums.dart';

/// Labels and units that depend on vehicle fuel type (not global settings).
abstract final class FuelTypeMetrics {
  static String quantityUnit(FuelType type) => switch (type) {
        FuelType.electric => 'kWh',
        FuelType.cng => 'kg',
        _ => 'L',
      };

  static String efficiencyUnit(FuelType type) => switch (type) {
        FuelType.electric => 'km/kWh',
        FuelType.cng => 'km/kg',
        _ => 'km/L',
      };

  static String consumptionPer100Unit(FuelType type) => switch (type) {
        FuelType.electric => 'kWh/100km',
        FuelType.cng => 'kg/100km',
        _ => 'L/100km',
      };

  static String quantityFieldLabel(FuelType type) => switch (type) {
        FuelType.electric => 'Energy (kWh)',
        FuelType.cng => 'Quantity (kg)',
        FuelType.lpg => 'Quantity (L)',
        FuelType.hybrid => 'Fuel (L)',
        FuelType.petrol => 'Quantity (L)',
        FuelType.diesel => 'Quantity (L)',
      };

  static String pricePerQuantityLabel(FuelType type) => switch (type) {
        FuelType.electric => 'Price per kWh',
        FuelType.cng => 'Price per kg',
        _ => 'Price per liter',
      };

  static String fillVerb(FuelType type) => switch (type) {
        FuelType.electric => 'Charge',
        _ => 'Refuel',
      };

  static double consumptionPer100(double distancePerQuantity) {
    if (distancePerQuantity <= 0) return 0;
    return 100 / distancePerQuantity;
  }

  static String formatEfficiency(double? value, FuelType type) {
    if (value == null) return '—';
    return '${value.toStringAsFixed(1)} ${efficiencyUnit(type)}';
  }

  static String formatConsumptionPer100(double? distancePerQuantity, FuelType type) {
    if (distancePerQuantity == null || distancePerQuantity <= 0) return '—';
    return '${consumptionPer100(distancePerQuantity).toStringAsFixed(1)} '
        '${consumptionPer100Unit(type)}';
  }
}
