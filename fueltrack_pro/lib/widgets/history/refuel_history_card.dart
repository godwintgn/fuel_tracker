import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/refuel_entry.dart';
import '../../models/vehicle.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

class RefuelHistoryCard extends StatelessWidget {
  const RefuelHistoryCard({
    super.key,
    required this.entry,
    required this.vehicle,
    required this.currency,
    required this.fuelUnit,
    required this.distanceUnit,
    this.alternateAccent = false,
    this.onTap,
  });

  final RefuelEntry entry;
  final Vehicle? vehicle;
  final String currency;
  final String fuelUnit;
  final String distanceUnit;
  final bool alternateAccent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    final title = entry.stationName?.trim().isNotEmpty == true
        ? entry.stationName!
        : vehicle?.displayName ?? 'Refuel';
    final subtitle = dateFormat.format(entry.refuelDate);
    final iconBg = alternateAccent
        ? AppColors.secondaryContainer
        : AppColors.primaryContainer;
    final iconFg = alternateAccent
        ? AppColors.onSecondaryContainer
        : AppColors.onPrimaryContainer;

    return Material(
      color: AppColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: Padding(
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
                        Text(title, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (vehicle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            vehicle!.displayName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.onSurfaceVariant,
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
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${entry.quantity.toStringAsFixed(2)}$fuelUnit • ${entry.fuelType.label}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.stackMd),
              Divider(
                height: 1,
                color: AppColors.outlineVariant.withValues(alpha: 0.6),
              ),
              const SizedBox(height: AppSpacing.stackMd),
              Row(
                children: [
                  Icon(
                    Icons.speed_outlined,
                    size: 18,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${NumberFormat('#,###').format(entry.odometer.round())} $distanceUnit',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const Spacer(),
                  if (entry.pricePerLiter != null) ...[
                    Icon(
                      Icons.sell_outlined,
                      size: 18,
                      color: AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${entry.pricePerLiter!.toStringAsFixed(3)} $currency/L',
                      style: theme.textTheme.bodyMedium,
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
