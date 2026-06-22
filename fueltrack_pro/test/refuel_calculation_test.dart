import 'package:flutter_test/flutter_test.dart';
import 'package:fueltrack_pro/services/refuel_calculation.dart';

void main() {
  group('RefuelCalculation.trackManualEdit', () {
    test('keeps last two edited fields', () {
      var order = <RefuelPriceField>[];
      order = RefuelCalculation.trackManualEdit(
        order,
        RefuelPriceField.quantity,
      );
      order = RefuelCalculation.trackManualEdit(
        order,
        RefuelPriceField.pricePerLiter,
      );
      expect(order, [
        RefuelPriceField.quantity,
        RefuelPriceField.pricePerLiter,
      ]);

      order = RefuelCalculation.trackManualEdit(
        order,
        RefuelPriceField.totalPrice,
      );
      expect(order, [
        RefuelPriceField.pricePerLiter,
        RefuelPriceField.totalPrice,
      ]);
    });
  });

  group('RefuelCalculation.calculate', () {
    test('derives total from quantity and price per liter', () {
      final result = RefuelCalculation.calculate(
        RefuelCalculationInput(
          quantity: 50,
          pricePerLiter: 0.22,
          manualFields: {
            RefuelPriceField.quantity,
            RefuelPriceField.pricePerLiter,
          },
        ),
      );

      expect(result.derivedField, RefuelPriceField.totalPrice);
      expect(result.totalPrice, closeTo(11, 0.001));
    });

    test('derives price per liter from quantity and total', () {
      final result = RefuelCalculation.calculate(
        RefuelCalculationInput(
          quantity: 50,
          totalPrice: 11,
          manualFields: {
            RefuelPriceField.quantity,
            RefuelPriceField.totalPrice,
          },
        ),
      );

      expect(result.derivedField, RefuelPriceField.pricePerLiter);
      expect(result.pricePerLiter, closeTo(0.22, 0.001));
    });

    test('derives quantity from price per liter and total', () {
      final result = RefuelCalculation.calculate(
        RefuelCalculationInput(
          pricePerLiter: 0.22,
          totalPrice: 11,
          manualFields: {
            RefuelPriceField.pricePerLiter,
            RefuelPriceField.totalPrice,
          },
        ),
      );

      expect(result.derivedField, RefuelPriceField.quantity);
      expect(result.quantity, closeTo(50, 0.001));
    });

    test('does not derive with fewer than two manual fields', () {
      final result = RefuelCalculation.calculate(
        RefuelCalculationInput(
          quantity: 50,
          manualFields: {RefuelPriceField.quantity},
        ),
      );

      expect(result.derivedField, isNull);
      expect(result.totalPrice, isNull);
    });

    test('skips division by zero', () {
      final result = RefuelCalculation.calculate(
        RefuelCalculationInput(
          quantity: 0,
          totalPrice: 11,
          manualFields: {
            RefuelPriceField.quantity,
            RefuelPriceField.totalPrice,
          },
        ),
      );

      expect(result.derivedField, RefuelPriceField.pricePerLiter);
      expect(result.pricePerLiter, isNull);
    });
  });
}
