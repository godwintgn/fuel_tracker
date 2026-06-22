import 'dart:ui';

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
    this.photoPath,
    this.photoCropRect,
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
  final String? photoPath;
  /// Normalized crop rect (0–1) relative to the original image.
  final Rect? photoCropRect;
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
    String? photoPath,
    Rect? photoCropRect,
    bool clearPhoto = false,
    bool clearCrop = false,
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
      photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
      photoCropRect: clearCrop ? null : (photoCropRect ?? this.photoCropRect),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    final crop = photoCropRect;
    return {
      'id': id,
      'name': name,
      'make': make,
      'model': model,
      'year': year,
      'fuel_type': fuelType.name,
      'license_plate': licensePlate,
      'notes': notes,
      'photo_path': photoPath,
      'photo_crop_left': crop?.left,
      'photo_crop_top': crop?.top,
      'photo_crop_width': crop?.width,
      'photo_crop_height': crop?.height,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory Vehicle.fromMap(Map<String, dynamic> map) {
    Rect? crop;
    final cl = map['photo_crop_left'];
    final ct = map['photo_crop_top'];
    final cw = map['photo_crop_width'];
    final ch = map['photo_crop_height'];
    if (cl != null && ct != null && cw != null && ch != null) {
      crop = Rect.fromLTWH(
        (cl as num).toDouble(),
        (ct as num).toDouble(),
        (cw as num).toDouble(),
        (ch as num).toDouble(),
      );
    }

    return Vehicle(
      id: map['id'] as int?,
      name: map['name'] as String,
      make: map['make'] as String?,
      model: map['model'] as String?,
      year: map['year'] as int?,
      fuelType: FuelType.fromString(map['fuel_type'] as String),
      licensePlate: map['license_plate'] as String?,
      notes: map['notes'] as String?,
      photoPath: map['photo_path'] as String?,
      photoCropRect: crop,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }
}
