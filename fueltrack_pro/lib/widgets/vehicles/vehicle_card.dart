import 'package:flutter/material.dart';

import '../../models/enums.dart';
import '../../models/vehicle.dart';
import '../../theme/app_spacing.dart';
import '../../theme/theme_x.dart';

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
    final cs = context.cs;
    final tt = context.tt;
    final title = vehicle.model?.isNotEmpty == true
        ? vehicle.model!
        : vehicle.name;
    final subtitle = vehicle.make ?? vehicle.name;

    return Card(
      color: cs.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        side: selected
            ? BorderSide(color: cs.primary, width: 2)
            : BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
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
                          Text(title, style: tt.titleLarge),
                          Text(
                            subtitle,
                            style: tt.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusLg),
                      ),
                      child: Icon(
                        _iconForFuelType(vehicle.fuelType),
                        color: cs.primary,
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
                          backgroundColor: cs.secondaryContainer,
                          foregroundColor: cs.onSecondaryContainer,
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
    final cs = context.cs;

    return Stack(
      children: [
        Container(
          height: 140,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cs.primary.withValues(alpha: 0.2),
                cs.secondary.withValues(alpha: 0.12),
                cs.surfaceContainer,
              ],
            ),
          ),
          child: Center(
            child: Icon(
              VehicleCard._iconForFuelType(fuelType),
              size: 64,
              color: cs.primary.withValues(alpha: 0.5),
            ),
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: selected ? cs.primary : cs.secondary,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              selected ? 'Active' : fuelType.label,
              style: context.tt.labelSmall?.copyWith(
                color: selected ? cs.onPrimary : cs.onSecondary,
                fontWeight: FontWeight.w600,
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
        Icon(icon, size: 16, color: context.cs.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(label, style: context.tt.labelLarge),
      ],
    );
  }
}
