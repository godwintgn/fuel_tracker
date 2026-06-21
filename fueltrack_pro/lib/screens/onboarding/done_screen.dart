import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/onboarding/onboarding_widgets.dart';

class OnboardingDoneScreen extends StatelessWidget {
  const OnboardingDoneScreen({
    super.key,
    required this.onGoToDashboard,
    required this.loading,
  });

  final VoidCallback onGoToDashboard;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: CustomPaint(painter: _DotPatternPainter()),
            ),
          ),
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.05),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.marginMobile),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  _SuccessIllustration(),
                  const SizedBox(height: AppSpacing.stackLg),
                  Text(
                    "You're all set!",
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.stackSm),
                  Text(
                    'Your profile is ready. FuelTrack Pro is now calibrated to help you optimize every mile.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.stackLg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ...List.generate(
                        3,
                        (_) => Container(
                          width: 24,
                          height: 6,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      Container(
                        width: 48,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  OnboardingPrimaryButton(
                    label: 'Go to Dashboard',
                    icon: Icons.arrow_forward,
                    loading: loading,
                    onPressed: loading ? null : onGoToDashboard,
                  ),
                  const SizedBox(height: AppSpacing.stackMd),
                  TextButton(
                    onPressed: loading ? null : onGoToDashboard,
                    child: const Text('Take a Quick Tour'),
                  ),
                  const SizedBox(height: AppSpacing.stackLg),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.1), width: 4),
            ),
          ),
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceContainerHigh,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 24,
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 64,
                  color: AppColors.onPrimary,
                ),
              ),
            ),
          ),
          const Positioned(
            top: 8,
            right: 24,
            child: Icon(Icons.auto_awesome, color: AppColors.primary, size: 32),
          ),
          const Positioned(
            bottom: 24,
            left: 8,
            child: Icon(Icons.star_outline, color: AppColors.secondary, size: 28),
          ),
        ],
      ),
    );
  }
}

class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.outlineVariant;
    const spacing = 24.0;
    for (var x = 0.0; x < size.width; x += spacing) {
      for (var y = 0.0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
