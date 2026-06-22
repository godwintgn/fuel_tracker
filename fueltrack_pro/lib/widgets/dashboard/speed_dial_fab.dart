import 'package:flutter/material.dart';

import '../../theme/theme_x.dart';

/// Speed-dial FAB — mount on [Scaffold.floatingActionButton] so Flutter
/// positions it correctly above the bottom navigation bar.
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

class _SpeedDialFabState extends State<SpeedDialFab> {
  var _expanded = false;
  OverlayEntry? _scrim;

  @override
  void dispose() {
    _removeScrim();
    super.dispose();
  }

  void _removeScrim() {
    _scrim?.remove();
    _scrim = null;
  }

  void _close() {
    _removeScrim();
    if (_expanded) setState(() => _expanded = false);
  }

  void _toggle() {
    if (_expanded) {
      _close();
    } else {
      _insertScrim();
      setState(() => _expanded = true);
    }
  }

  void _insertScrim() {
    final overlay = Overlay.of(context);
    _scrim = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _close,
          child: ColoredBox(
            color: Colors.black.withValues(alpha: 0.38),
          ),
        ),
      ),
    );
    overlay.insert(_scrim!);
  }

  void _action(VoidCallback callback) {
    _close();
    callback();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_expanded) ...[
          _DialAction(
            label: 'New Refuel',
            icon: Icons.local_gas_station_outlined,
            backgroundColor: cs.secondaryContainer,
            foregroundColor: cs.onSecondaryContainer,
            onTap: () => _action(widget.onNewRefuel),
          ),
          const SizedBox(height: 12),
          _DialAction(
            label: 'New Vehicle',
            icon: Icons.directions_car_outlined,
            backgroundColor: cs.tertiaryContainer,
            foregroundColor: cs.onTertiaryContainer,
            onTap: () => _action(widget.onNewVehicle),
          ),
          const SizedBox(height: 12),
        ],
        FloatingActionButton(
          onPressed: _toggle,
          elevation: _expanded ? 4 : 6,
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: AnimatedRotation(
            turns: _expanded ? 0.125 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.add, size: 28),
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
    final cs = context.cs;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(10),
          color: cs.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(label, style: context.tt.labelLarge),
          ),
        ),
        const SizedBox(width: 12),
        Material(
          elevation: 3,
          borderRadius: BorderRadius.circular(14),
          color: backgroundColor,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
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
