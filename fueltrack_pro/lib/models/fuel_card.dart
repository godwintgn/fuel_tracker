import 'enums.dart';

class FuelCard {
  const FuelCard({
    this.id,
    required this.name,
    required this.provider,
    this.companyName,
    this.cardNumber,
    required this.scope,
    this.vehicleId,
    required this.limitType,
    this.limitValue,
    required this.resetPeriod,
    this.resetDay,
    this.expiryDate,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String name;
  final String provider;
  final String? companyName;
  final String? cardNumber;
  final FuelCardScope scope;
  final int? vehicleId;
  final FuelCardLimitType limitType;
  final double? limitValue;
  final FuelCardResetPeriod resetPeriod;
  final int? resetDay;
  final DateTime? expiryDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isExpired =>
      expiryDate != null && expiryDate!.isBefore(DateTime.now());

  bool get isFleet => scope == FuelCardScope.fleet;

  String get limitSummary {
    if (limitType == FuelCardLimitType.none || limitValue == null) return 'No limit';
    final unit = limitType == FuelCardLimitType.price ? 'currency' : 'L';
    return '${limitValue!.toStringAsFixed(limitType == FuelCardLimitType.price ? 2 : 0)} $unit / ${resetPeriod.label.toLowerCase()}';
  }

  FuelCard copyWith({
    int? id,
    String? name,
    String? provider,
    String? companyName,
    String? cardNumber,
    FuelCardScope? scope,
    int? vehicleId,
    bool clearVehicle = false,
    FuelCardLimitType? limitType,
    double? limitValue,
    FuelCardResetPeriod? resetPeriod,
    int? resetDay,
    DateTime? expiryDate,
    bool clearExpiry = false,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FuelCard(
      id: id ?? this.id,
      name: name ?? this.name,
      provider: provider ?? this.provider,
      companyName: companyName ?? this.companyName,
      cardNumber: cardNumber ?? this.cardNumber,
      scope: scope ?? this.scope,
      vehicleId: clearVehicle ? null : (vehicleId ?? this.vehicleId),
      limitType: limitType ?? this.limitType,
      limitValue: limitValue ?? this.limitValue,
      resetPeriod: resetPeriod ?? this.resetPeriod,
      resetDay: resetDay ?? this.resetDay,
      expiryDate: clearExpiry ? null : (expiryDate ?? this.expiryDate),
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'provider': provider,
        'company_name': companyName,
        'card_number': cardNumber,
        'scope': scope.name,
        'vehicle_id': vehicleId,
        'limit_type': limitType.name,
        'limit_value': limitValue,
        'reset_period': resetPeriod.name,
        'reset_day': resetDay,
        'expiry_date': expiryDate?.millisecondsSinceEpoch,
        'is_active': isActive ? 1 : 0,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  factory FuelCard.fromMap(Map<String, dynamic> map) => FuelCard(
        id: map['id'] as int?,
        name: map['name'] as String,
        provider: map['provider'] as String,
        companyName: map['company_name'] as String?,
        cardNumber: map['card_number'] as String?,
        scope: FuelCardScope.fromString(map['scope'] as String),
        vehicleId: map['vehicle_id'] as int?,
        limitType: FuelCardLimitType.fromString(map['limit_type'] as String),
        limitValue: map['limit_value'] != null
            ? (map['limit_value'] as num).toDouble()
            : null,
        resetPeriod: FuelCardResetPeriod.fromString(map['reset_period'] as String),
        resetDay: map['reset_day'] as int?,
        expiryDate: map['expiry_date'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['expiry_date'] as int)
            : null,
        isActive: (map['is_active'] as int? ?? 1) == 1,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      );
}
