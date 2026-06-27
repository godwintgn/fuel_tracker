import 'package:flutter/material.dart';

import '../../theme/theme_x.dart';

/// Compact pill displaying an accent [label] and a bold [value].
/// Modelled after the Wealth Journal SummaryStat chip.
class SummaryStat extends StatelessWidget {
  const SummaryStat({
    super.key,
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final String value;

  /// Accent colour for both label and value. Defaults to primary.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final tt = context.tt;
    final accent = color ?? cs.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: tt.labelSmall?.copyWith(
              color: accent,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: tt.titleSmall?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
