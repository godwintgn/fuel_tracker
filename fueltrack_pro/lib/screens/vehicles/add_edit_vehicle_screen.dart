import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/enums.dart';
import '../../models/vehicle.dart';
import '../../providers/database_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/vehicles_provider.dart';
import '../../services/vehicle_image_service.dart';
import '../../theme/app_spacing.dart';
import '../../theme/theme_x.dart';
import '../../widgets/onboarding/onboarding_widgets.dart';
import '../../widgets/vehicles/vehicle_photo_crop_screen.dart';
import '../../widgets/vehicles/vehicle_photo_view.dart';

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
  Uint8List? _pendingPhotoBytes;
  String? _photoPath;

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
    _photoPath = v?.photoPath;
  }

  Future<void> _pickAndCropPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      imageQuality: 92,
    );
    if (picked == null || !mounted) return;

    final bytes = await picked.readAsBytes();
    if (!mounted) return;

    final cropped = await VehiclePhotoCropScreen.open(
      context,
      imageBytes: bytes,
    );
    if (cropped != null && mounted) {
      setState(() {
        _pendingPhotoBytes = cropped;
      });
    }
  }

  Vehicle _draftVehicle({int? id, required DateTime now, String? photoPath}) {
    final year = int.tryParse(_yearController.text.trim());
    return Vehicle(
      id: id ?? widget.vehicle?.id,
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
      photoPath: photoPath ?? _photoPath ?? widget.vehicle?.photoPath,
      createdAt: widget.vehicle?.createdAt ?? now,
      updatedAt: now,
    );
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
      var vehicle = _draftVehicle(now: now);

      if (widget.isEditing) {
        if (_pendingPhotoBytes != null && vehicle.id != null) {
          final path = await VehicleImageService.saveVehiclePhoto(
            vehicleId: vehicle.id!,
            bytes: _pendingPhotoBytes!,
          );
          vehicle = vehicle.copyWith(photoPath: path);
        }
        await ref.read(vehiclesProvider.notifier).updateVehicle(vehicle);
      } else {
        final id = await ref.read(vehiclesProvider.notifier).addVehicle(vehicle);
        if (_pendingPhotoBytes != null) {
          final path = await VehicleImageService.saveVehiclePhoto(
            vehicleId: id,
            bytes: _pendingPhotoBytes!,
          );
          vehicle = vehicle.copyWith(id: id, photoPath: path);
          await ref.read(vehiclesProvider.notifier).updateVehicle(vehicle);
        }
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
            style: FilledButton.styleFrom(
              backgroundColor: context.cs.error,
              foregroundColor: context.cs.onError,
            ),
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
              color: theme.colorScheme.error,
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
            _VehiclePhotoSection(
              previewVehicle: _draftVehicle(now: DateTime.now()),
              pendingBytes: _pendingPhotoBytes,
              onPickPhoto: _pickAndCropPhoto,
            ),
            const SizedBox(height: AppSpacing.stackLg),
            Text('Vehicle Details', style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.stackSm),
            Text(
              'Provide accurate information to track fuel efficiency precisely.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _makeController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Manufacturer *',
                      hintText: 'e.g. Mitsubishi',
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                            ? 'Required'
                            : null,
                  ),
                ),
                const SizedBox(width: AppSpacing.gutter),
                Expanded(
                  child: TextFormField(
                    controller: _modelController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Model *',
                      hintText: 'e.g. Montero Sport',
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                            ? 'Required'
                            : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.stackMd),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Vehicle Number *',
                      hintText: 'ABC-1234',
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                            ? 'Required'
                            : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.stackLg),
            Text(
              'Fuel Type',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
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
                  color: theme.colorScheme.onSurfaceVariant,
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

class _VehiclePhotoSection extends StatelessWidget {
  const _VehiclePhotoSection({
    required this.previewVehicle,
    required this.pendingBytes,
    required this.onPickPhoto,
  });

  final Vehicle previewVehicle;
  final Uint8List? pendingBytes;
  final VoidCallback onPickPhoto;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          child: pendingBytes != null
              ? Image.memory(
                  pendingBytes!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                )
              : VehiclePhotoView(vehicle: previewVehicle, height: 160),
        ),
        const SizedBox(height: AppSpacing.stackSm),
        OutlinedButton.icon(
          onPressed: onPickPhoto,
          icon: const Icon(Icons.photo_camera_outlined),
          label: Text(
            pendingBytes != null || previewVehicle.photoPath != null
                ? 'Adjust vehicle photo'
                : 'Add vehicle photo',
          ),
        ),
        Text(
          'Position your vehicle inside the frame so it shows clearly in the garage.',
          style: context.tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}
