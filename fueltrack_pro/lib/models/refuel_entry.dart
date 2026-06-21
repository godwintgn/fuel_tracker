import 'enums.dart';

class RefuelEntry {
  const RefuelEntry({
    this.id,
    required this.vehicleId,
    required this.refuelDate,
    required this.odometer,
    required this.quantity,
    this.pricePerLiter,
    required this.totalPrice,
    required this.fuelType,
    this.stationName,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final int vehicleId;
  final DateTime refuelDate;
  final double odometer;
  final double quantity;
  final double? pricePerLiter;
  final double totalPrice;
  final FuelType fuelType;
  final String? stationName;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  RefuelEntry copyWith({
    int? id,
    int? vehicleId,
    DateTime? refuelDate,
    double? odometer,
    double? quantity,
    double? pricePerLiter,
    double? totalPrice,
    FuelType? fuelType,
    String? stationName,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RefuelEntry(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      refuelDate: refuelDate ?? this.refuelDate,
      odometer: odometer ?? this.odometer,
      quantity: quantity ?? this.quantity,
      pricePerLiter: pricePerLiter ?? this.pricePerLiter,
      totalPrice: totalPrice ?? this.totalPrice,
      fuelType: fuelType ?? this.fuelType,
      stationName: stationName ?? this.stationName,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicle_id': vehicleId,
      'refuel_date': refuelDate.millisecondsSinceEpoch,
      'odometer': odometer,
      'quantity': quantity,
      'price_per_liter': pricePerLiter,
      'total_price': totalPrice,
      'fuel_type': fuelType.name,
      'station_name': stationName,
      'notes': notes,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory RefuelEntry.fromMap(Map<String, dynamic> map) {
    return RefuelEntry(
      id: map['id'] as int?,
      vehicleId: map['vehicle_id'] as int,
      refuelDate: DateTime.fromMillisecondsSinceEpoch(map['refuel_date'] as int),
      odometer: (map['odometer'] as num).toDouble(),
      quantity: (map['quantity'] as num).toDouble(),
      pricePerLiter: map['price_per_liter'] != null
          ? (map['price_per_liter'] as num).toDouble()
          : null,
      totalPrice: (map['total_price'] as num).toDouble(),
      fuelType: FuelType.fromString(map['fuel_type'] as String),
      stationName: map['station_name'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }
}
