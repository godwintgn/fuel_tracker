import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

class SpeedDialFab extends StatefulWidget {
  const SpeedDialFab({
    super.key,
    required this.onNewRefuel,
    required this.onNewVehicle,
  });

  final VoidCallback onNewRefuel;
  final VoidCallback onNewVehicle;

  @override
  State<SpeedDialFab> createState() => _SpeedDialFabState();
}

class _SpeedDialFabState extends State<SpeedDialFab>
    with SingleTickerProviderStateMixin {
  var _expanded = false;

  void _toggle() => setState(() => _expanded = !_expanded);

  void _close() {
    if (_expanded) setState(() => _expanded = false);
  }

  void _action(VoidCallback callback) {
    _close();
    callback();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      clipBehavior: Clip.none,
      children: [
        if (_expanded)
          Positioned.fill(
            child: GestureDetector(
              onTap: _close,
              child: Container(color: Colors.black.withValues(alpha: 0.4)),
            ),
          ),
        if (_expanded) ...[
          Positioned(
            right: AppSpacing.marginMobile,
            bottom: 176,
            child: _DialAction(
              label: 'New Vehicle',
              icon: Icons.directions_car_outlined,
              backgroundColor: AppColors.surfaceContainerHigh,
              foregroundColor: AppColors.primary,
              onTap: () => _action(widget.onNewVehicle),
            ),
          ),
          Positioned(
            right: AppSpacing.marginMobile,
            bottom: 240,
            child: _DialAction(
              label: 'New Refuel',
              icon: Icons.local_gas_station_outlined,
              backgroundColor: AppColors.secondaryContainer,
              foregroundColor: AppColors.onSecondaryContainer,
              onTap: () => _action(widget.onNewRefuel),
            ),
          ),
        ],
        Padding(
          padding: const EdgeInsets.only(
            right: AppSpacing.marginMobile,
            bottom: 88,
          ),
          child: FloatingActionButton(
            onPressed: _toggle,
            backgroundColor: AppColors.primaryContainer,
            foregroundColor: AppColors.onPrimaryContainer,
            child: AnimatedRotation(
              turns: _expanded ? 0.125 : 0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(Icons.add, size: 32),
            ),
          ),
        ),
      ],
    );
  }
}

class _DialAction extends StatelessWidget {
  const _DialAction({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(8),
          color: AppColors.surfaceContainerLowest,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
        ),
        const SizedBox(width: 12),
        Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          color: backgroundColor,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Icon(icon, color: foregroundColor),
            ),
          ),
        ),
      ],
    );
  }
}
