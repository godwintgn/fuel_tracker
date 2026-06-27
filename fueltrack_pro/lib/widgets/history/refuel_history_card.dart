import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/refuel_entry.dart';
import '../../models/vehicle.dart';
import '../../services/fuel_type_metrics.dart';
import '../../theme/app_spacing.dart';
import '../../theme/theme_x.dart';
import '../../utils/vehicle_color.dart';

class RefuelHistoryCard extends StatelessWidget {
  const RefuelHistoryCard({
    super.key,
    required this.entry,
    required this.vehicle,
    required this.currency,
    required this.distanceUnit,
    this.onTap,
  });

  final RefuelEntry entry;
  final Vehicle? vehicle;
  final String currency;
  final String distanceUnit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final tt = context.tt;
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    final title = entry.stationName?.trim().isNotEmpty == true
        ? entry.stationName!
        : vehicle?.displayName ?? 'Refuel';
    final subtitle = dateFormat.format(entry.refuelDate);
    // Stable color per vehicle — never changes regardless of list position
    final accent = vehicle?.id != null
        ? vehicleAccentColor(vehicle!.id!, cs)
        : cs.primary;
    final iconBg = accent.withValues(alpha: 0.15);
    final iconFg = accent;
    final qtyUnit = FuelTypeMetrics.quantityUnit(
      vehicle?.fuelType ?? entry.fuelType,
    );

    return Material(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.gutter),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.local_gas_station_outlined,
                      size: 20,
                      color: iconFg,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.stackMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: tt.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: tt.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (vehicle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            vehicle!.displayName,
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${entry.totalPrice.toStringAsFixed(2)} $currency',
                        style: tt.titleSmall?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${entry.quantity.toStringAsFixed(1)} $qtyUnit • ${entry.fuelType.label}',
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.stackMd),
              Divider(
                height: 1,
                color: cs.outlineVariant.withValues(alpha: 0.6),
              ),
              const SizedBox(height: AppSpacing.stackMd),
              Row(
                children: [
                  Icon(
                    Icons.speed_outlined,
                    size: 18,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${NumberFormat('#,###').format(entry.odometer.round())} $distanceUnit',
                    style: tt.labelMedium,
                  ),
                  const Spacer(),
                  if (entry.pricePerLiter != null) ...[
                    Icon(
                      Icons.sell_outlined,
                      size: 18,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${entry.pricePerLiter!.toStringAsFixed(3)} $currency/L',
                      style: tt.labelMedium,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
