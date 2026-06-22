import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/vehicle.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/selected_vehicle_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_spacing.dart';
import '../../theme/theme_x.dart';

/// Active vehicle chip + picker used below the shell app bar.
class ActiveVehicleBar extends ConsumerWidget {
  const ActiveVehicleBar({
    super.key,
    required this.vehicles,
    this.subtitle,
    this.embedded = false,
  });

  final List<Vehicle> vehicles;
  final String? subtitle;
  /// When true, skip horizontal outer padding (parent already gutters).
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = context.cs;
    final tt = context.tt;
    final settings = ref.watch(settingsProvider).valueOrNull;
    final selectedId = settings?.selectedVehicleId;
    Vehicle? active;
    for (final v in vehicles) {
      if (v.id == selectedId) {
        active = v;
        break;
      }
    }
    active ??= vehicles.isNotEmpty ? vehicles.first : null;

    if (active == null) return const SizedBox.shrink();

    return Padding(
      padding: embedded
          ? const EdgeInsets.only(bottom: AppSpacing.stackMd)
          : const EdgeInsets.fromLTRB(
              AppSpacing.marginMobile,
              AppSpacing.stackSm,
              AppSpacing.marginMobile,
              AppSpacing.stackMd,
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (subtitle != null) ...[
            Text(
              subtitle!,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.stackSm),
          ],
          Material(
            color: cs.surfaceContainer,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              onTap: vehicles.length > 1
                  ? () => _showPicker(context, ref, vehicles, active!)
                  : null,
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.directions_car, size: 18, color: cs.primary),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            active.displayName,
                            style: tt.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _vehicleMeta(active),
                            style: tt.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (vehicles.length > 1) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.expand_more, size: 18, color: cs.onSurfaceVariant),
                    ],
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Active',
                        style: tt.labelSmall?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _vehicleMeta(Vehicle v) {
    final plate = v.licensePlate?.trim();
    if (plate != null && plate.isNotEmpty) {
      return '${v.fuelType.label} • $plate';
    }
    return v.fuelType.label;
  }

  void _showPicker(
    BuildContext context,
    WidgetRef ref,
    List<Vehicle> vehicles,
    Vehicle current,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.gutter),
                child: Text('Active vehicle', style: context.tt.titleMedium),
              ),
              ...vehicles.map(
                (v) => ListTile(
                  leading: Icon(
                    v.id == current.id
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: context.cs.primary,
                  ),
                  title: Text(v.displayName),
                  subtitle: Text(_vehicleMeta(v)),
                  onTap: () async {
                    Navigator.pop(context);
                    await setActiveVehicle(ref, v);
                    ref
                      ..invalidate(dashboardProvider)
                      ..invalidate(analyticsProvider);
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.stackMd),
            ],
          ),
        );
      },
    );
  }
}
