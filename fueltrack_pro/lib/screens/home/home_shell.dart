import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/vehicles_provider.dart';
import '../../theme/theme_x.dart';
import '../../widgets/dashboard/speed_dial_fab.dart';
import '../analytics/analytics_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../history/history_screen.dart';
import '../refuel/add_refuel_screen.dart';
import '../vehicles/add_edit_vehicle_screen.dart';
import '../settings/settings_screen.dart';
import '../vehicles/vehicle_list_screen.dart';
import '../../providers/settings_provider.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  var _index = 0;

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
    final vehicleId = settings?.selectedVehicleId ?? vehicles.first.id;
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'FuelTrack Pro',
          style: TextStyle(
            color: context.cs.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => SettingsScreen.open(context),
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
          ),
        ],
      ),
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: const [
          DashboardScreen(),
          VehicleListScreen(),
          HistoryScreen(),
          AnalyticsScreen(),
        ],
      ),
      floatingActionButton: SpeedDialFab(
        onNewRefuel: _onNewRefuel,
        onNewVehicle: _onNewVehicle,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
