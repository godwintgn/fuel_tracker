import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/regions.dart';
import '../../providers/onboarding_provider.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/onboarding/onboarding_widgets.dart';

class OnboardingWelcomeScreen extends ConsumerWidget {
  const OnboardingWelcomeScreen({
    super.key,
    required this.onNext,
    required this.onSkip,
  });

  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final draft = ref.watch(onboardingDraftProvider);

    return OnboardingGradientBackground(
      child: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: onSkip, child: const Text('Skip')),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.marginMobile,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.stackLg),
                    const AppLogoMark(),
                    const SizedBox(height: AppSpacing.base),
                    Text(
                      'FuelTrack Pro',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.stackLg),
                    Text(
                      'Master your miles with precision. Track every drop, optimize every trip.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.stackMd),
                    Text(
                      'The ultimate companion for your vehicle maintenance and fuel efficiency insights.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.stackLg),
                    _SampleVehicleCard(draft: draft),
                    const SizedBox(height: AppSpacing.stackLg),
                    OnboardingPrimaryButton(
                      label: 'Get Started',
                      icon: Icons.arrow_forward,
                      onPressed: onNext,
                    ),
                    const SizedBox(height: AppSpacing.stackMd),
                    Text(
                      'Step 1 of 4: Personalized Setup',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.stackLg),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SampleVehicleCard extends StatelessWidget {
  const _SampleVehicleCard({required this.draft});

  final OnboardingDraft draft;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final cs = theme.colorScheme;

    return Card(
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: Icon(
                Icons.directions_car_filled_outlined,
                size: 36,
                color: cs.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.gutter),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    draft.vehicleDisplayName == 'SUV'
                        ? 'Montero Sport'
                        : draft.vehicleDisplayName,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          draft.fuelType.label,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '12.5 km/L',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.verified, color: cs.primary),
          ],
        ),
      ),
    );
  }
}
