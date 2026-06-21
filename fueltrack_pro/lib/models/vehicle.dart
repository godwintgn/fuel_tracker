import 'enums.dart';

class Vehicle {
  const Vehicle({
    this.id,
    required this.name,
    this.make,
    this.model,
    this.year,
    required this.fuelType,
    this.licensePlate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String name;
  final String? make;
  final String? model;
  final int? year;
  final FuelType fuelType;
  final String? licensePlate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get displayName {
    if (make != null && model != null) {
      return '$make $model';
    }
    return name;
  }

  Vehicle copyWith({
    int? id,
    String? name,
    String? make,
    String? model,
    int? year,
    FuelType? fuelType,
    String? licensePlate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Vehicle(
      id: id ?? this.id,
      name: name ?? this.name,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      fuelType: fuelType ?? this.fuelType,
      licensePlate: licensePlate ?? this.licensePlate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'make': make,
      'model': model,
      'year': year,
      'fuel_type': fuelType.name,
      'license_plate': licensePlate,
      'notes': notes,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory Vehicle.fromMap(Map<String, dynamic> map) {
    return Vehicle(
      id: map['id'] as int?,
      name: map['name'] as String,
      make: map['make'] as String?,
      model: map['model'] as String?,
      year: map['year'] as int?,
      fuelType: FuelType.fromString(map['fuel_type'] as String),
      licensePlate: map['license_plate'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }
}
