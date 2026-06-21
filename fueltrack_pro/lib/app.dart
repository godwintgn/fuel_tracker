import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/settings_provider.dart';
import 'screens/home/home_shell.dart';
import 'screens/onboarding/onboarding_flow.dart';
import 'theme/app_theme.dart';

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
          home: settings.onboardingCompleted
              ? const HomeShell()
              : const OnboardingFlow(),
        );
      },
    );
  }
}
