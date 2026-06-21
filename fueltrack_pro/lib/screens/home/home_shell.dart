import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/settings_provider.dart';
import '../../providers/vehicles_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('FuelTrack Pro'),
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (settings) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.marginMobile),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard coming soon',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.stackMd),
                Text(
                  'Onboarding complete. Next up: vehicle management, dashboard charts, and refuel entry.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.stackLg),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.gutter),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your settings', style: theme.textTheme.titleMedium),
                        const SizedBox(height: AppSpacing.stackMd),
                        _InfoRow(
                          label: 'Currency',
                          value:
                              '${settings.currencySymbol} (${settings.currencyCode})',
                        ),
                        _InfoRow(
                          label: 'Distance',
                          value: settings.distanceUnit.abbreviation,
                        ),
                        _InfoRow(
                          label: 'Fuel unit',
                          value: settings.fuelUnit.abbreviation,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.gutter),
                vehiclesAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Vehicles error: $e'),
                  data: (vehicles) {
                    if (vehicles.isEmpty) {
                      return const Text('No vehicles added yet.');
                    }
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.gutter),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Vehicles', style: theme.textTheme.titleMedium),
                            ...vehicles.map(
                              (v) => ListTile(
                                leading: const Icon(Icons.directions_car,
                                    color: AppColors.primary),
                                title: Text(v.displayName),
                                subtitle: Text(v.fuelType.label),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
