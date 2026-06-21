import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/onboarding_provider.dart';
import '../../providers/settings_provider.dart';
import '../../screens/home/home_shell.dart';
import 'add_vehicle_screen.dart';
import 'done_screen.dart';
import 'region_currency_screen.dart';
import 'welcome_screen.dart';

class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  final _pageController = PageController();
  var _finishing = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _skip({required bool saveVehicle}) async {
    if (_finishing) return;
    setState(() => _finishing = true);
    try {
      await ref
          .read(onboardingServiceProvider)
          .completeOnboarding(saveVehicle: saveVehicle);
      if (!mounted) return;
      await _openHome();
    } finally {
      if (mounted) setState(() => _finishing = false);
    }
  }

  Future<void> _finish() async {
    await _skip(saveVehicle: true);
  }

  Future<void> _openHome() async {
    await ref.read(settingsProvider.future);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        OnboardingWelcomeScreen(
          onNext: () => _goToPage(1),
          onSkip: () => _skip(saveVehicle: false),
        ),
        OnboardingAddVehicleScreen(
          onBack: () => _goToPage(0),
          onNext: () => _goToPage(2),
          onSkip: () => _skip(saveVehicle: false),
        ),
        OnboardingRegionCurrencyScreen(
          onNext: () => _goToPage(3),
          onSkip: () => _skip(saveVehicle: false),
        ),
        OnboardingDoneScreen(
          loading: _finishing,
          onGoToDashboard: _finish,
        ),
      ],
    );
  }
}
