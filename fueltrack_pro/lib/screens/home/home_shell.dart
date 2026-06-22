import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/vehicles_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/dashboard/speed_dial_fab.dart';
import '../dashboard/dashboard_screen.dart';
import '../refuel/add_refuel_screen.dart';
import '../vehicles/add_edit_vehicle_screen.dart';
import '../vehicles/vehicle_list_screen.dart';
import '../../providers/settings_provider.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  var _index = 0;

  bool get _showSpeedDial => _index == 0 || _index == 2;

  Future<void> _onNewRefuel() async {
    final vehicles = ref.read(vehiclesProvider).valueOrNull;
    if (vehicles == null || vehicles.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a vehicle before logging a refuel')),
      );
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const AddEditVehicleScreen(),
        ),
      );
      return;
    }

    final settings = ref.read(settingsProvider).valueOrNull;
    final vehicleId =
        settings?.selectedVehicleId ?? vehicles.first.id;
    if (!mounted) return;
    await AddRefuelScreen.open(context, vehicleId: vehicleId);
  }

  void _onNewVehicle() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AddEditVehicleScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final hasVehicles = vehiclesAsync.maybeWhen(
      data: (v) => v.isNotEmpty,
      orElse: () => false,
    );

    return Scaffold(
      appBar: _index == 0
          ? null
          : AppBar(
              title: const Text(
                'FuelTrack Pro',
                style: TextStyle(color: AppColors.primary),
              ),
              actions: [
                if (_index == 1)
                  IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Settings coming in Step 8'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.settings_outlined),
                  ),
              ],
            ),
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(
            index: _index,
            children: const [
              DashboardScreen(),
              VehicleListScreen(),
              _PlaceholderTab(
                icon: Icons.history,
                title: 'History',
                message: 'Refuel history coming in Step 6.',
              ),
              _PlaceholderTab(
                icon: Icons.insights_outlined,
                title: 'Analytics',
                message: 'Efficiency analytics coming in Step 7.',
              ),
            ],
          ),
          if (_showSpeedDial)
            Positioned.fill(
              child: SpeedDialFab(
                onNewRefuel: _onNewRefuel,
                onNewVehicle: _onNewVehicle,
              ),
            ),
        ],
      ),
      floatingActionButton: !_showSpeedDial && _index == 1 && hasVehicles
          ? FloatingActionButton(
              onPressed: () => VehicleListScreen.openAddVehicle(context),
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_car_outlined),
            selectedIcon: Icon(Icons.directions_car),
            label: 'Vehicles',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Analytics',
          ),
        ],
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.stackLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: AppColors.primary),
            const SizedBox(height: AppSpacing.stackLg),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.stackSm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
