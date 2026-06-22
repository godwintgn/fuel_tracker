import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../theme/theme_x.dart';

class OnboardingGradientBackground extends StatelessWidget {
  const OnboardingGradientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).scaffoldBackgroundColor,
                  cs.primary.withValues(alpha: 0.06),
                  cs.secondary.withValues(alpha: 0.08),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
        child,
        Positioned(
          bottom: -50,
          left: -50,
          child: _BlurOrb(color: cs.secondaryContainer, size: 200),
        ),
        Positioned(
          bottom: -20,
          right: -20,
          child: _BlurOrb(color: cs.primaryContainer, size: 150),
        ),
      ],
    );
  }
}

class _BlurOrb extends StatelessWidget {
  const _BlurOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.2),
        ),
      ),
    );
  }
}

class OnboardingProgressBar extends StatelessWidget {
  const OnboardingProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.segmented = false,
  });

  final int currentStep;
  final int totalSteps;
  final bool segmented;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;

    if (segmented) {
      return Row(
        children: List.generate(totalSteps, (index) {
          final active = index <= currentStep;
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < totalSteps - 1 ? 8 : 0),
              decoration: BoxDecoration(
                color: active ? cs.primary : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      );
    }

    final progress = (currentStep + 1) / totalSteps;
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: LinearProgressIndicator(
        value: progress,
        minHeight: 4,
        backgroundColor: cs.surfaceContainerHighest,
        color: cs.primary,
      ),
    );
  }
}

class SelectionChip extends StatelessWidget {
  const SelectionChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.compact = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final tt = context.tt;

    return Material(
      color: selected ? cs.primaryContainer : Colors.transparent,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? cs.primaryContainer : cs.outlineVariant,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 16 : 20,
            vertical: compact ? 8 : 10,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 20,
                  color: selected
                      ? cs.onPrimaryContainer
                      : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: tt.labelLarge?.copyWith(
                  color: selected
                      ? cs.onPrimaryContainer
                      : cs.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingPrimaryButton extends StatelessWidget {
  const OnboardingPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          shape: const StadiumBorder(),
        ),
        child: loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label),
                  if (icon != null) ...[
                    const SizedBox(width: 8),
                    Icon(icon, size: 20),
                  ],
                ],
              ),
      ),
    );
  }
}

class AppLogoMark extends StatelessWidget {
  const AppLogoMark({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(
        Icons.local_gas_station_rounded,
        size: size * 0.5,
        color: cs.onPrimary,
      ),
    );
  }
}
