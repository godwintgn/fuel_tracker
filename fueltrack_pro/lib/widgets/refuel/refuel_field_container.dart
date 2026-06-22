import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../theme/theme_x.dart';

class RefuelFieldContainer extends StatelessWidget {
  const RefuelFieldContainer({
    super.key,
    required this.label,
    required this.child,
    this.icon,
    this.readOnly = false,
    this.autoCalculated = false,
    this.highlighted = false,
  });

  final String label;
  final Widget child;
  final IconData? icon;
  final bool readOnly;
  final bool autoCalculated;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final tt = context.tt;
    final background = highlighted
        ? cs.primary.withValues(alpha: 0.10)
        : readOnly
            ? cs.surfaceContainerLow
            : cs.surfaceContainerHigh;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.componentPaddingX,
        vertical: AppSpacing.componentPaddingY,
      ),
      decoration: BoxDecoration(
        color: autoCalculated
            ? cs.primary.withValues(alpha: 0.12)
            : background,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
        border: Border(
          bottom: BorderSide(
            color: autoCalculated || highlighted ? cs.primary : cs.outline,
            width: autoCalculated || highlighted ? 2 : 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                icon,
                color: autoCalculated ? cs.primary : cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: AppSpacing.stackMd),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: tt.labelSmall?.copyWith(
                    color: readOnly && !autoCalculated
                        ? cs.onSurfaceVariant
                        : cs.primary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
