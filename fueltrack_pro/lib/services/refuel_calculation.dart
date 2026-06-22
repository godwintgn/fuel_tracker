enum RefuelPriceField { quantity, pricePerLiter, totalPrice }

class RefuelCalculationInput {
  const RefuelCalculationInput({
    this.quantity,
    this.pricePerLiter,
    this.totalPrice,
    required this.manualFields,
  });

  final double? quantity;
  final double? pricePerLiter;
  final double? totalPrice;
  final Set<RefuelPriceField> manualFields;
}

class RefuelCalculationResult {
  const RefuelCalculationResult({
    this.quantity,
    this.pricePerLiter,
    this.totalPrice,
    this.derivedField,
  });

  final double? quantity;
  final double? pricePerLiter;
  final double? totalPrice;
  final RefuelPriceField? derivedField;
}

abstract final class RefuelCalculation {
  static double? parseValue(String? text) {
    if (text == null) return null;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed);
  }

  static List<RefuelPriceField> trackManualEdit(
    List<RefuelPriceField> order,
    RefuelPriceField edited,
  ) {
    final next = [...order]..remove(edited)..add(edited);
    if (next.length > 2) {
      next.removeAt(0);
    }
    return next;
  }

  static RefuelPriceField? derivedField(Set<RefuelPriceField> manualFields) {
    if (manualFields.length != 2) return null;
    for (final field in RefuelPriceField.values) {
      if (!manualFields.contains(field)) return field;
    }
    return null;
  }

  static RefuelCalculationResult calculate(RefuelCalculationInput input) {
    final derived = derivedField(input.manualFields);
    if (derived == null) {
      return RefuelCalculationResult(
        quantity: input.quantity,
        pricePerLiter: input.pricePerLiter,
        totalPrice: input.totalPrice,
      );
    }

    var quantity = input.quantity;
    var pricePerLiter = input.pricePerLiter;
    var totalPrice = input.totalPrice;

    switch (derived) {
      case RefuelPriceField.quantity:
        if (pricePerLiter != null &&
            pricePerLiter > 0 &&
            totalPrice != null &&
            totalPrice > 0) {
          quantity = totalPrice / pricePerLiter;
        }
      case RefuelPriceField.pricePerLiter:
        if (quantity != null &&
            quantity > 0 &&
            totalPrice != null &&
            totalPrice > 0) {
          pricePerLiter = totalPrice / quantity;
        }
      case RefuelPriceField.totalPrice:
        if (quantity != null &&
            quantity > 0 &&
            pricePerLiter != null &&
            pricePerLiter > 0) {
          totalPrice = quantity * pricePerLiter;
        }
    }

    return RefuelCalculationResult(
      quantity: quantity,
      pricePerLiter: pricePerLiter,
      totalPrice: totalPrice,
      derivedField: derived,
    );
  }

  static String formatQuantity(double value) => value.toStringAsFixed(2);

  static String formatMoney(double value) => value.toStringAsFixed(3);
}
