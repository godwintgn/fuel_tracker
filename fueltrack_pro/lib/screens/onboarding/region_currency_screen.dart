import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/regions.dart';
import '../../providers/onboarding_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/onboarding/onboarding_widgets.dart';

class OnboardingRegionCurrencyScreen extends ConsumerWidget {
  const OnboardingRegionCurrencyScreen({
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
    final region = draft.region;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.marginMobile,
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_gas_station, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'FuelTrack Pro',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton(onPressed: onSkip, child: const Text('Skip')),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.marginMobile,
                  AppSpacing.stackLg,
                  AppSpacing.marginMobile,
                  120,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const OnboardingProgressBar(
                      currentStep: 2,
                      totalSteps: 4,
                      segmented: true,
                    ),
                    const SizedBox(height: AppSpacing.stackLg),
                    Text(
                      'Region & Currency',
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.stackSm),
                    Text(
                      'Configure your local settings so we can provide accurate cost analysis and efficiency data.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.stackLg),
                    _SettingsCard(
                      children: [
                        Text(
                          'Country / Region',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: draft.regionCode,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.surfaceContainerHighest,
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusLg),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          items: Regions.all
                              .map(
                                (r) => DropdownMenuItem(
                                  value: r.code,
                                  child: Text(r.name),
                                ),
                              )
                              .toList(),
                          onChanged: (code) {
                            if (code != null) {
                              ref
                                  .read(onboardingDraftProvider.notifier)
                                  .patch(regionCode: code);
                            }
                          },
                        ),
                        const SizedBox(height: AppSpacing.stackLg),
                        Text(
                          'Currency',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.gutter),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHighest,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusLg),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppColors.secondaryContainer,
                                child: Text(
                                  region.currencyCode,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppColors.onSecondaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.stackMd),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      region.currencyName,
                                      style: theme.textTheme.titleMedium,
                                    ),
                                    Text(
                                      'Default for your region',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.lock_outline,
                                  color: AppColors.outline),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.gutter),
                    _SettingsCard(
                      children: [
                        Text(
                          'Measurement Units',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.stackLg),
                        _UnitToggleRow(
                          icon: Icons.straighten_outlined,
                          title: 'Distance',
                          subtitle: draft.useKm ? 'Kilometers (km)' : 'Miles (mi)',
                          value: draft.useKm,
                          onChanged: (v) => ref
                              .read(onboardingDraftProvider.notifier)
                              .patch(useKm: v),
                        ),
                        const SizedBox(height: AppSpacing.stackLg),
                        _UnitToggleRow(
                          icon: Icons.ev_station_outlined,
                          title: 'Fuel Volume',
                          subtitle: draft.useLiters ? 'Liters (L)' : 'Gallons (gal)',
                          value: draft.useLiters,
                          onChanged: (v) => ref
                              .read(onboardingDraftProvider.notifier)
                              .patch(useLiters: v),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.gutter),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.gutter),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusXl),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor:
                                AppColors.onPrimaryContainer.withValues(alpha: 0.2),
                            child: const Icon(
                              Icons.info_outline,
                              color: AppColors.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.stackMd),
                          Expanded(
                            child: Text(
                              'You can change these units anytime in the Settings menu.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.marginMobile),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              OnboardingPrimaryButton(
                label: 'Next Step',
                icon: Icons.arrow_forward,
                onPressed: onNext,
              ),
              const SizedBox(height: AppSpacing.stackSm),
              Text(
                'By continuing, you agree to our local data handling policies.',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.gutter),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _UnitToggleRow extends StatelessWidget {
  const _UnitToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: AppSpacing.gutter),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.onPrimary,
          activeTrackColor: AppColors.primary,
        ),
      ],
    );
  }
}
