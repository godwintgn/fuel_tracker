import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

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
    final theme = Theme.of(context);
    final background = highlighted
        ? AppColors.primaryContainer.withValues(alpha: 0.15)
        : readOnly
            ? AppColors.surfaceContainerLow
            : AppColors.surfaceContainer;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.componentPaddingX,
        vertical: AppSpacing.componentPaddingY,
      ),
      decoration: BoxDecoration(
        color: autoCalculated
            ? AppColors.primaryFixed.withValues(alpha: 0.2)
            : background,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
        border: Border(
          bottom: BorderSide(
            color: autoCalculated || highlighted
                ? AppColors.primary
                : AppColors.outline,
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
                color: autoCalculated ? AppColors.primary : AppColors.outline,
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
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: autoCalculated
                        ? AppColors.primary
                        : readOnly
                            ? AppColors.onSurfaceVariant
                            : AppColors.primary,
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
