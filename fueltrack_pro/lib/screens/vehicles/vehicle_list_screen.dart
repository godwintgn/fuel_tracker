import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/vehicle.dart';
import '../../providers/selected_vehicle_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/vehicles_provider.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/vehicles/vehicle_card.dart';
import '../refuel/add_refuel_screen.dart';
import 'add_edit_vehicle_screen.dart';

class VehicleListScreen extends ConsumerWidget {
  const VehicleListScreen({super.key});

  static Future<void> openAddVehicle(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AddEditVehicleScreen(),
      ),
    );
  }

  Future<void> _openEditVehicle(BuildContext context, Vehicle vehicle) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AddEditVehicleScreen(vehicle: vehicle),
      ),
    );
  }

  Future<void> _selectVehicle(WidgetRef ref, Vehicle vehicle) async {
    await setActiveVehicle(ref, vehicle);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    return vehiclesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (vehicles) {
        final selectedId = settingsAsync.valueOrNull?.selectedVehicleId;

        if (vehicles.isEmpty) {
          return EmptyState(
            icon: Icons.garage_outlined,
            title: 'No vehicles yet',
            message:
                'Add your first vehicle to start tracking fuel efficiency and expenses.',
            actionLabel: 'Add Vehicle',
            onAction: () => openAddVehicle(context),
          );
        }

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.marginMobile,
                AppSpacing.stackSm,
                AppSpacing.marginMobile,
                AppSpacing.stackMd,
              ),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vehicles',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage your fleet and track fuel efficiency.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.marginMobile,
              ),
              sliver: SliverList.separated(
                itemCount: vehicles.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppSpacing.gutter),
                itemBuilder: (context, index) {
                  final vehicle = vehicles[index];
                  final isSelected = vehicle.id == selectedId;

                  return VehicleCard(
                    vehicle: vehicle,
                    selected: isSelected,
                    onSetActive: isSelected
                        ? null
                        : () => _selectVehicle(ref, vehicle),
                    onDetails: () => _openEditVehicle(context, vehicle),
                    onFuelLog: () async {
                      await _selectVehicle(ref, vehicle);
                      if (context.mounted) {
                        await AddRefuelScreen.open(
                          context,
                          vehicleId: vehicle.id,
                        );
                      }
                    },
                  );
                },
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.marginMobile),
              sliver: SliverToBoxAdapter(
                child: AddAnotherPlaceholder(
                  onTap: () => openAddVehicle(context),
                ),
              ),
            ),
            if (vehicles.length >= 2)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.marginMobile,
                  0,
                  AppSpacing.marginMobile,
                  AppSpacing.stackLg,
                ),
                sliver: SliverToBoxAdapter(
                  child: _EfficiencyOverviewCard(count: vehicles.length),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        );
      },
    );
  }
}

class _EfficiencyOverviewCard extends StatelessWidget {
  const _EfficiencyOverviewCard({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Efficiency Overview',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Text(
            'Log refuels to unlock fleet-wide efficiency insights. $count vehicles registered.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}
