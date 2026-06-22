import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/refuel_entry.dart';
import '../../models/vehicle.dart';
import '../../services/fuel_type_metrics.dart';
import '../../theme/app_spacing.dart';
import '../../theme/theme_x.dart';

class RefuelHistoryCard extends StatelessWidget {
  const RefuelHistoryCard({
    super.key,
    required this.entry,
    required this.vehicle,
    required this.currency,
    required this.distanceUnit,
    this.alternateAccent = false,
    this.onTap,
  });

  final RefuelEntry entry;
  final Vehicle? vehicle;
  final String currency;
  final String distanceUnit;
  final bool alternateAccent;
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
    final iconBg =
        alternateAccent ? cs.secondaryContainer : cs.primaryContainer;
    final iconFg =
        alternateAccent ? cs.onSecondaryContainer : cs.onPrimaryContainer;
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
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: iconBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.local_gas_station_outlined,
                      color: iconFg,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.stackMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: tt.titleMedium),
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
                        '${entry.totalPrice.toStringAsFixed(3)} $currency',
                        style: tt.titleLarge?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${entry.quantity.toStringAsFixed(2)} $qtyUnit • ${entry.fuelType.label}',
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
                    style: tt.bodyMedium,
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
                      style: tt.bodyMedium,
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
