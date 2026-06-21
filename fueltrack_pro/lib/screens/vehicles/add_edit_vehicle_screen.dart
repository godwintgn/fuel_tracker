import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/enums.dart';
import '../../models/vehicle.dart';
import '../../providers/database_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/vehicles_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/onboarding/onboarding_widgets.dart';

class AddEditVehicleScreen extends ConsumerStatefulWidget {
  const AddEditVehicleScreen({super.key, this.vehicle});

  final Vehicle? vehicle;

  bool get isEditing => vehicle != null;

  @override
  ConsumerState<AddEditVehicleScreen> createState() =>
      _AddEditVehicleScreenState();
}

class _AddEditVehicleScreenState extends ConsumerState<AddEditVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _makeController;
  late final TextEditingController _modelController;
  late final TextEditingController _yearController;
  late final TextEditingController _plateController;

  late FuelType _fuelType;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    _nameController = TextEditingController(text: v?.name ?? '');
    _makeController = TextEditingController(text: v?.make ?? '');
    _modelController = TextEditingController(text: v?.model ?? '');
    _yearController = TextEditingController(
      text: v?.year?.toString() ?? '',
    );
    _plateController = TextEditingController(text: v?.licensePlate ?? '');
    _fuelType = v?.fuelType ?? FuelType.petrol;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  String _resolveName() {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) return name;
    final make = _makeController.text.trim();
    final model = _modelController.text.trim();
    if (make.isNotEmpty && model.isNotEmpty) return '$make $model';
    if (model.isNotEmpty) return model;
    if (make.isNotEmpty) return make;
    return 'My Vehicle';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final year = int.tryParse(_yearController.text.trim());
      final vehicle = Vehicle(
        id: widget.vehicle?.id,
        name: _resolveName(),
        make: _makeController.text.trim().isEmpty
            ? null
            : _makeController.text.trim(),
        model: _modelController.text.trim().isEmpty
            ? null
            : _modelController.text.trim(),
        year: year,
        fuelType: _fuelType,
        licensePlate: _plateController.text.trim().isEmpty
            ? null
            : _plateController.text.trim(),
        createdAt: widget.vehicle?.createdAt ?? now,
        updatedAt: now,
      );

      if (widget.isEditing) {
        await ref.read(vehiclesProvider.notifier).updateVehicle(vehicle);
      } else {
        final id = await ref.read(vehiclesProvider.notifier).addVehicle(vehicle);
        final settings = await ref.read(settingsProvider.future);
        if (settings.selectedVehicleId == null) {
          await ref.read(settingsProvider.notifier).updateSettings(
                settings.copyWith(selectedVehicleId: id),
              );
        }
      }

      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final vehicle = widget.vehicle;
    if (vehicle?.id == null) return;

    final db = ref.read(databaseServiceProvider);
    final refuels = await db.getRefuelEntries(vehicleId: vehicle!.id);
    if (!mounted) return;

    if (refuels.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cannot delete a vehicle with refuel history. Remove refuels first.',
          ),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete vehicle?'),
        content: Text('Remove ${vehicle.displayName} from your garage?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await ref.read(vehiclesProvider.notifier).deleteVehicle(vehicle.id!);

    final settings = await ref.read(settingsProvider.future);
    if (settings.selectedVehicleId == vehicle.id) {
      final remaining = await ref.read(vehiclesProvider.future);
      await ref.read(settingsProvider.notifier).updateSettings(
            settings.copyWith(
              selectedVehicleId: remaining.isEmpty ? null : remaining.first.id,
              clearSelectedVehicle: remaining.isEmpty,
            ),
          );
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Vehicle' : 'Add Vehicle'),
        actions: [
          if (widget.isEditing)
            IconButton(
              onPressed: _saving ? null : _delete,
              icon: const Icon(Icons.delete_outline),
              color: AppColors.error,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.marginMobile,
            AppSpacing.stackLg,
            AppSpacing.marginMobile,
            120,
          ),
          children: [
            _HeroBanner(isEditing: widget.isEditing),
            const SizedBox(height: AppSpacing.stackLg),
            Text('Vehicle Details', style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.stackSm),
            Text(
              'Provide accurate information to track fuel efficiency precisely.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.stackLg),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Vehicle Name',
                hintText: 'e.g. My Daily Driver',
              ),
            ),
            const SizedBox(height: AppSpacing.stackMd),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _makeController,
                    decoration: const InputDecoration(
                      labelText: 'Manufacturer',
                      hintText: 'e.g. Mitsubishi',
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.gutter),
                Expanded(
                  child: TextFormField(
                    controller: _modelController,
                    decoration: const InputDecoration(
                      labelText: 'Model',
                      hintText: 'e.g. Montero Sport',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.stackMd),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _yearController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Year',
                      hintText: '2024',
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.gutter),
                Expanded(
                  child: TextFormField(
                    controller: _plateController,
                    decoration: const InputDecoration(
                      labelText: 'Registration',
                      hintText: 'ABC-1234',
                    ),
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: FuelType.values.map((type) {
                return SelectionChip(
                  label: type.label,
                  compact: true,
                  selected: _fuelType == type,
                  onTap: () => setState(() => _fuelType = type),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.marginMobile),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'You can change these details later in vehicle settings.',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.stackMd),
              OnboardingPrimaryButton(
                label: widget.isEditing ? 'Save Changes' : 'Save Vehicle',
                icon: Icons.save_outlined,
                loading: _saving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.isEditing});

  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            AppColors.surfaceContainerLow,
          ],
        ),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Stack(
        children: [
          const Center(
            child: Icon(
              Icons.directions_car_filled_outlined,
              size: 72,
              color: AppColors.primary,
            ),
          ),
          Positioned(
            left: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                isEditing ? 'Edit Profile' : 'Vehicle Profile',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.onPrimaryContainer,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
