import 'package:flutter/material.dart';

import '../../models/enums.dart';
import '../../models/vehicle.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

class VehicleCard extends StatelessWidget {
  const VehicleCard({
    super.key,
    required this.vehicle,
    required this.onDetails,
    required this.onFuelLog,
    this.selected = false,
  });

  final Vehicle vehicle;
  final VoidCallback onDetails;
  final VoidCallback onFuelLog;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = vehicle.model?.isNotEmpty == true
        ? vehicle.model!
        : vehicle.name;
    final subtitle = vehicle.make ?? vehicle.name;

    return Card(
      color: AppColors.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        side: selected
            ? const BorderSide(color: AppColors.primary, width: 2)
            : BorderSide.none,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeroBanner(
            fuelType: vehicle.fuelType,
            selected: selected,
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: theme.textTheme.titleLarge),
                          Text(
                            subtitle,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHighest,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusLg),
                      ),
                      child: Icon(
                        _iconForFuelType(vehicle.fuelType),
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.gutter),
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.stackMd),
                Wrap(
                  spacing: AppSpacing.gutter,
                  runSpacing: AppSpacing.stackSm,
                  children: [
                    if (vehicle.year != null)
                      _MetaChip(
                        icon: Icons.calendar_today_outlined,
                        label: '${vehicle.year}',
                      ),
                    _MetaChip(
                      icon: Icons.local_gas_station_outlined,
                      label: vehicle.fuelType.label,
                    ),
                    if (vehicle.licensePlate?.isNotEmpty == true)
                      _MetaChip(
                        icon: Icons.badge_outlined,
                        label: vehicle.licensePlate!,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.gutter),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onDetails,
                        child: const Text('Details'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.stackMd),
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: onFuelLog,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.secondaryContainer,
                          foregroundColor: AppColors.onSecondaryContainer,
                        ),
                        child: const Text('Fuel Log'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static IconData _iconForFuelType(FuelType type) {
    return switch (type) {
      FuelType.electric => Icons.electric_car_outlined,
      FuelType.hybrid => Icons.electric_car_outlined,
      _ => Icons.directions_car_filled_outlined,
    };
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.fuelType, required this.selected});

  final FuelType fuelType;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 140,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withValues(alpha: 0.2),
                AppColors.secondary.withValues(alpha: 0.12),
                AppColors.surfaceContainer,
              ],
            ),
          ),
          child: Center(
            child: Icon(
              VehicleCard._iconForFuelType(fuelType),
              size: 64,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : AppColors.secondary,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              selected ? 'Active' : fuelType.label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: selected
                        ? AppColors.onPrimary
                        : AppColors.onSecondary,
                  ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelLarge),
      ],
    );
  }
}
