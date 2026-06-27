import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/enums.dart';
import '../../models/fuel_card.dart';
import '../../theme/app_spacing.dart';
import '../../theme/theme_x.dart';

class FuelCardWidget extends StatelessWidget {
  const FuelCardWidget({
    super.key,
    required this.card,
    required this.currencySymbol,
    this.vehicleName,
    this.onEdit,
    this.onDelete,
    this.onToggle,
  });

  final FuelCard card;
  final String currencySymbol;
  final String? vehicleName;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final ValueChanged<bool>? onToggle;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final tt = context.tt;
    final isExpired = card.isExpired;
    final accentColor = isExpired
        ? cs.error
        : card.isActive
            ? cs.primary
            : cs.onSurfaceVariant;

    return Opacity(
      opacity: card.isActive ? 1.0 : 0.6,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(
            color: isExpired
                ? cs.error.withValues(alpha: 0.4)
                : cs.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.gutter),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.credit_card_outlined,
                      size: 20,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.name,
                          style: tt.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          card.provider +
                              (card.companyName != null
                                  ? ' · ${card.companyName}'
                                  : ''),
                          style: tt.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    iconSize: 18,
                    onSelected: (v) {
                      if (v == 'edit') onEdit?.call();
                      if (v == 'delete') onDelete?.call();
                      if (v == 'toggle') onToggle?.call(!card.isActive);
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(value: 'edit', child: const Text('Edit')),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Text(card.isActive ? 'Deactivate' : 'Activate'),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Delete',
                          style: TextStyle(color: cs.error),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                0,
                AppSpacing.gutter,
                AppSpacing.gutter,
              ),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _Chip(
                    label: card.scope == FuelCardScope.fleet
                        ? 'Fleet'
                        : (vehicleName ?? 'Vehicle'),
                    icon: card.scope == FuelCardScope.fleet
                        ? Icons.directions_car_outlined
                        : Icons.car_repair,
                    cs: cs,
                    tt: tt,
                  ),
                  if (card.limitType != FuelCardLimitType.none &&
                      card.limitValue != null)
                    _Chip(
                      label: card.limitType == FuelCardLimitType.price
                          ? '$currencySymbol ${card.limitValue!.toStringAsFixed(2)}'
                          : '${card.limitValue!.toStringAsFixed(0)} L',
                      icon: Icons.speed_outlined,
                      cs: cs,
                      tt: tt,
                    ),
                  if (card.resetPeriod != FuelCardResetPeriod.none)
                    _Chip(
                      label: card.resetPeriod.label,
                      icon: Icons.refresh,
                      cs: cs,
                      tt: tt,
                    ),
                  if (card.expiryDate != null)
                    _Chip(
                      label: DateFormat.yMMMd().format(card.expiryDate!),
                      icon: Icons.event_outlined,
                      cs: cs,
                      tt: tt,
                      color: isExpired ? cs.error : null,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.icon,
    required this.cs,
    required this.tt,
    this.color,
  });

  final String label;
  final IconData icon;
  final ColorScheme cs;
  final TextTheme tt;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? cs.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: c),
          const SizedBox(width: 4),
          Text(
            label,
            style: tt.labelSmall?.copyWith(color: c, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
