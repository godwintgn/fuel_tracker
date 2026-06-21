import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/regions.dart';
import '../models/enums.dart';
import '../models/vehicle.dart';
import 'settings_provider.dart';
import 'vehicles_provider.dart';

final onboardingDraftProvider =
    NotifierProvider<OnboardingDraftNotifier, OnboardingDraft>(
  OnboardingDraftNotifier.new,
);

class OnboardingDraftNotifier extends Notifier<OnboardingDraft> {
  @override
  OnboardingDraft build() => const OnboardingDraft();

  void update(OnboardingDraft draft) => state = draft;

  void patch({
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
    state = state.copyWith(
      vehicleType: vehicleType,
      make: make,
      model: model,
      year: year,
      licensePlate: licensePlate,
      fuelType: fuelType,
      regionCode: regionCode,
      useKm: useKm,
      useLiters: useLiters,
    );
  }
}

final onboardingServiceProvider = Provider<OnboardingService>((ref) {
  return OnboardingService(ref);
});

class OnboardingService {
  OnboardingService(this._ref);

  final Ref _ref;

  Future<void> completeOnboarding({required bool saveVehicle}) async {
    final draft = _ref.read(onboardingDraftProvider);
    final region = draft.region;
    final now = DateTime.now();

    int? vehicleId;
    if (saveVehicle && draft.vehicleDisplayName.trim().isNotEmpty) {
      final vehicle = Vehicle(
        name: draft.vehicleDisplayName.trim(),
        make: draft.make.trim().isEmpty ? null : draft.make.trim(),
        model: draft.model.trim().isEmpty ? null : draft.model.trim(),
        year: int.tryParse(draft.year.trim()),
        fuelType: draft.fuelType,
        licensePlate:
            draft.licensePlate.trim().isEmpty ? null : draft.licensePlate.trim(),
        createdAt: now,
        updatedAt: now,
      );
      vehicleId = await _ref.read(vehiclesProvider.notifier).addVehicle(vehicle);
    }

    final currentSettings = await _ref.read(settingsProvider.future);
    await _ref.read(settingsProvider.notifier).updateSettings(
          currentSettings.copyWith(
            currencyCode: region.currencyCode,
            currencySymbol: region.currencySymbol,
            distanceUnit: draft.useKm ? DistanceUnit.km : DistanceUnit.miles,
            fuelUnit: draft.useLiters ? FuelUnit.liters : FuelUnit.gallons,
            onboardingCompleted: true,
            selectedVehicleId: vehicleId,
          ),
        );
  }
}
