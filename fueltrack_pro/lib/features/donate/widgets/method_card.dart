import 'package:flutter/material.dart';

import '../../../theme/theme_x.dart';

class MethodCard extends StatelessWidget {
  const MethodCard({
    super.key,
    required this.title,
    required this.expanded,
    required this.onHeaderTap,
    this.badge,
    required this.child,
  });

  final String title;
  final bool expanded;
  final VoidCallback onHeaderTap;
  final String? badge;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pal = context.palette;
    final amber = pal.brandAmber;
    final inactiveBorder = pal.cardBorder;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: expanded ? amber : inactiveBorder,
          width: expanded ? 1.5 : 1,
        ),
        color: theme.colorScheme.surfaceContainer.withValues(alpha: 0.85),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onHeaderTap,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Padding(
              padding: EdgeInsets.fromLTRB(14, 14, 14, expanded ? 8 : 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: amber,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: child,
            ),
        ],
      ),
    );
  }
}
