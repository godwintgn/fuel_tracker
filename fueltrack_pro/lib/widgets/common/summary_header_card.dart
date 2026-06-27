import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../theme/theme_x.dart';
import 'app_card.dart';

/// Hero header card used at the top of Dashboard and Analytics screens.
///
/// Displays a 40 px icon well, a [title] in titleMedium w700, a large
/// [headlineValue] in headlineSmall w800, and an optional row of
/// [SummaryStat]-style stat chips supplied as [stats].
///
/// Modelled after the Wealth Journal SummaryHeaderCard pattern.
class SummaryHeaderCard extends StatelessWidget {
  const SummaryHeaderCard({
    super.key,
    required this.icon,
    required this.title,
    required this.headlineValue,
    this.headlineUnit,
    this.headlineColor,
    this.stats = const [],
    this.trailing,
    this.subtitle,
  });

  final IconData icon;
  final String title;

  /// The large number / main metric shown prominently.
  final String headlineValue;

  /// Small unit label shown right of the headline (e.g. "km").
  final String? headlineUnit;
  final Color? headlineColor;

  /// Compact stat chips shown below the headline.
  final List<Widget> stats;

  /// Optional widget anchored to the top-right of the card (e.g. a chip).
  final Widget? trailing;

  /// Muted text shown between title and headline.
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final tt = context.tt;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: cs.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              // ignore: use_null_aware_elements
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: AppSpacing.stackMd),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                headlineValue,
                style: tt.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: headlineColor ?? cs.onSurface,
                ),
              ),
              if (headlineUnit != null) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    headlineUnit!,
                    style: tt.labelMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (stats.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.stackMd),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: stats,
            ),
          ],
        ],
      ),
    );
  }
}
