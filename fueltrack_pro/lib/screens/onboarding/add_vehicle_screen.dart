import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/regions.dart';
import '../../models/enums.dart';
import '../../providers/onboarding_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/onboarding/onboarding_widgets.dart';

class OnboardingAddVehicleScreen extends ConsumerStatefulWidget {
  const OnboardingAddVehicleScreen({
    super.key,
    required this.onNext,
    required this.onBack,
    required this.onSkip,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onSkip;

  @override
  ConsumerState<OnboardingAddVehicleScreen> createState() =>
      _OnboardingAddVehicleScreenState();
}

class _OnboardingAddVehicleScreenState
    extends ConsumerState<OnboardingAddVehicleScreen> {
  late final TextEditingController _makeController;
  late final TextEditingController _modelController;
  late final TextEditingController _yearController;
  late final TextEditingController _plateController;

  @override
  void initState() {
    super.initState();
    _makeController = TextEditingController();
    _modelController = TextEditingController();
    _yearController = TextEditingController();
    _plateController = TextEditingController();
  }

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  void _syncDraft() {
    ref.read(onboardingDraftProvider.notifier).patch(
          make: _makeController.text,
          model: _modelController.text,
          year: _yearController.text,
          licensePlate: _plateController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final draft = ref.watch(onboardingDraftProvider);

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
                  IconButton(
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Expanded(
                    child: OnboardingProgressBar(
                      currentStep: 1,
                      totalSteps: 4,
                    ),
                  ),
                  TextButton(onPressed: widget.onSkip, child: const Text('Skip')),
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
                    Text(
                      'Add your vehicle',
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.stackSm),
                    Text(
                      "Tell us what you're driving to get more accurate fuel efficiency insights and maintenance alerts.",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.stackLg),
                    _HeroBanner(),
                    const SizedBox(height: AppSpacing.stackLg),
                    Text('Vehicle Type', style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.stackMd),
                    Wrap(
                      spacing: AppSpacing.stackMd,
                      runSpacing: AppSpacing.stackMd,
                      children: VehiclePresets.types.map((preset) {
                        return SelectionChip(
                          label: preset.label,
                          icon: preset.icon,
                          selected: draft.vehicleType == preset.label,
                          onTap: () {
                            ref
                                .read(onboardingDraftProvider.notifier)
                                .patch(vehicleType: preset.label);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.stackLg),
                    Text('Vehicle Details', style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.stackMd),
                    _DetailField(
                      controller: _makeController,
                      label: 'Manufacturer',
                      onChanged: (_) => _syncDraft(),
                    ),
                    const SizedBox(height: AppSpacing.stackMd),
                    _DetailField(
                      controller: _modelController,
                      label: 'Model',
                      onChanged: (_) => _syncDraft(),
                    ),
                    const SizedBox(height: AppSpacing.stackMd),
                    Row(
                      children: [
                        Expanded(
                          child: _DetailField(
                            controller: _yearController,
                            label: 'Year',
                            keyboardType: TextInputType.number,
                            onChanged: (_) => _syncDraft(),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.stackMd),
                        Expanded(
                          child: _DetailField(
                            controller: _plateController,
                            label: 'Registration Plate',
                            onChanged: (_) => _syncDraft(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.stackLg),
                    Text(
                      'Fuel Type',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.stackSm),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: FuelType.values.map((type) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: SelectionChip(
                              label: type.label,
                              compact: true,
                              selected: draft.fuelType == type,
                              onTap: () {
                                ref
                                    .read(onboardingDraftProvider.notifier)
                                    .patch(fuelType: type);
                              },
                            ),
                          );
                        }).toList(),
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
          child: OnboardingPrimaryButton(
            label: 'Next',
            icon: Icons.chevron_right,
            onPressed: () {
              _syncDraft();
              widget.onNext();
            },
          ),
        ),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            AppColors.surfaceContainerLow,
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.directions_car_filled_outlined,
          size: 72,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _DetailField extends StatelessWidget {
  const _DetailField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.surfaceContainerLow,
      ),
    );
  }
}
