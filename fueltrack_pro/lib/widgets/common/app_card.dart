import 'package:flutter/material.dart';

import '../../theme/app_palette.dart';
import '../../theme/app_spacing.dart';

/// Standard surface card — matches Wealth Journal [AppCard] (border + shadow).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
    this.margin,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final pal = theme.extension<AppPalette>();

    final borderColor = pal != null
        ? Color.alphaBlend(
            cs.outline.withValues(alpha: 0.35),
            pal.cardBorder,
          )
        : (isDark
            ? Color.alphaBlend(
                cs.primary.withValues(alpha: 0.12),
                cs.outlineVariant.withValues(alpha: 0.4),
              )
            : cs.outlineVariant.withValues(alpha: 0.18));

    final card = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: borderColor),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.09),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.32),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: child,
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: card,
      ),
    );
  }
}
