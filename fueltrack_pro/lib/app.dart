import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

class FuelTrackApp extends ConsumerWidget {
  const FuelTrackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return settingsAsync.when(
      loading: () => MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, _) => MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Failed to initialize: $error')),
        ),
      ),
      data: (settings) {
        return MaterialApp(
          title: 'FuelTrack Pro',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: settings.themeMode.toFlutterThemeMode(),
          home: const _BootstrapScreen(),
        );
      },
    );
  }
}

/// Temporary screen for step 1 — replaced by onboarding in step 2.
class _BootstrapScreen extends StatelessWidget {
  const _BootstrapScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.marginMobile),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.stackLg),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: Icon(
                  Icons.local_gas_station_rounded,
                  size: 36,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: AppSpacing.stackLg),
              Text(
                'FuelTrack Pro',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.stackSm),
              Text(
                'Project scaffold ready. Onboarding flow coming next.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.gutter),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Foundation',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.stackMd),
                      _StatusRow(
                        icon: Icons.palette_outlined,
                        label: 'M3 theme (green/blue palette)',
                        color: AppColors.primary,
                      ),
                      _StatusRow(
                        icon: Icons.storage_outlined,
                        label: 'SQLite schema (vehicles, refuels, settings)',
                        color: AppColors.secondary,
                      ),
                      _StatusRow(
                        icon: Icons.water_drop_outlined,
                        label: 'Riverpod state layer',
                        color: AppColors.tertiaryContainer,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.stackLg),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.stackMd),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: AppSpacing.stackMd),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Icon(
            Icons.check_circle,
            size: 20,
            color: AppColors.primaryContainer,
          ),
        ],
      ),
    );
  }
}
