import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/enums.dart';
import '../../models/refuel_entry.dart';
import '../../models/vehicle.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/refuels_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/vehicles_provider.dart';
import '../../services/refuel_calculation.dart';
import '../../services/fuel_type_metrics.dart';
import '../../services/refuel_timeline_validation.dart';
import '../../theme/app_spacing.dart';
import '../../theme/theme_x.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/onboarding/onboarding_widgets.dart';
import '../../widgets/refuel/refuel_field_container.dart';
import '../vehicles/add_edit_vehicle_screen.dart';

class AddRefuelScreen extends ConsumerStatefulWidget {
  const AddRefuelScreen({
    super.key,
    this.initialVehicleId,
    this.entry,
  });

  final int? initialVehicleId;
  final RefuelEntry? entry;

  bool get isEditing => entry != null;

  /// Vehicle and fuel type are fixed when logging for a vehicle or editing.
  bool get locksVehicleFields => initialVehicleId != null || isEditing;

  static Future<void> open(
    BuildContext context, {
    int? vehicleId,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AddRefuelScreen(initialVehicleId: vehicleId),
      ),
    );
  }

  static Future<void> openForEdit(
    BuildContext context, {
    required RefuelEntry entry,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AddRefuelScreen(entry: entry),
      ),
    );
  }

  @override
  ConsumerState<AddRefuelScreen> createState() => _AddRefuelScreenState();
}

class _AddRefuelScreenState extends ConsumerState<AddRefuelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _odometerController = TextEditingController();
  final _quantityController = TextEditingController();
  final _pricePerLiterController = TextEditingController();
  final _totalPriceController = TextEditingController();
  final _stationController = TextEditingController();
  final _notesController = TextEditingController();

  late DateTime _refuelDate;
  Vehicle? _vehicle;
  var _manualOrder = <RefuelPriceField>[];
  RefuelPriceField? _derivedField;
  var _saving = false;
  var _suppressCalc = false;
  List<RefuelEntry> _vehicleRefuels = [];
  RefuelNeighborBounds? _neighborBounds;

  bool get _locksVehicleFields => widget.locksVehicleFields;

  @override
  void initState() {
    super.initState();
    final existing = widget.entry;
    _refuelDate = existing?.refuelDate ?? DateTime.now();
    if (existing != null) {
      _odometerController.text = existing.odometer.toStringAsFixed(0);
      _quantityController.text =
          RefuelCalculation.formatQuantity(existing.quantity);
      if (existing.pricePerLiter != null) {
        _pricePerLiterController.text =
            RefuelCalculation.formatMoney(existing.pricePerLiter!);
      }
      _totalPriceController.text =
          RefuelCalculation.formatMoney(existing.totalPrice);
      _stationController.text = existing.stationName ?? '';
      _notesController.text = existing.notes ?? '';
      _manualOrder = const [
        RefuelPriceField.quantity,
        RefuelPriceField.pricePerLiter,
      ];
    }
    _quantityController.addListener(_onQuantityChanged);
    _pricePerLiterController.addListener(_onPriceChanged);
    _totalPriceController.addListener(_onTotalChanged);
    _odometerController.addListener(_onOdometerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  @override
  void dispose() {
    _quantityController
      ..removeListener(_onQuantityChanged)
      ..dispose();
    _pricePerLiterController
      ..removeListener(_onPriceChanged)
      ..dispose();
    _totalPriceController
      ..removeListener(_onTotalChanged)
      ..dispose();
    _odometerController
      ..removeListener(_onOdometerChanged)
      ..dispose();
    _stationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    final vehicles = await ref.read(vehiclesProvider.future);
    if (!mounted || vehicles.isEmpty) return;

    final settings = await ref.read(settingsProvider.future);
    final targetId = widget.entry?.vehicleId ??
        widget.initialVehicleId ??
        settings.selectedVehicleId ??
        vehicles.first.id;

    Vehicle? vehicle;
    for (final v in vehicles) {
      if (v.id == targetId) {
        vehicle = v;
        break;
      }
    }
    vehicle ??= vehicles.first;

    setState(() => _vehicle = vehicle);

    if (vehicle.id != null) {
      await _loadVehicleHints(vehicle.id!);
    }
  }

  Future<void> _loadVehicleHints(int vehicleId) async {
    final refuels = await ref.read(vehicleRefuelsProvider(vehicleId).future);
    if (!mounted) return;

    final others = widget.entry?.id == null
        ? refuels
        : refuels.where((e) => e.id != widget.entry!.id).toList();

    setState(() => _vehicleRefuels = refuels);

    if (others.isNotEmpty &&
        widget.entry == null &&
        others.first.pricePerLiter != null &&
        _pricePerLiterController.text.isEmpty) {
      setState(() {
        _pricePerLiterController.text =
            RefuelCalculation.formatMoney(others.first.pricePerLiter!);
        _manualOrder = RefuelCalculation.trackManualEdit(
          _manualOrder,
          RefuelPriceField.pricePerLiter,
        );
      });
      _recalculate();
    }

    _refreshTimelineBounds();
  }

  void _onOdometerChanged() => _refreshTimelineBounds();

  void _refreshTimelineBounds() {
    if (!mounted) return;

    final odometer = RefuelCalculation.parseValue(_odometerController.text);
    final bounds = odometer != null && odometer > 0
        ? RefuelTimelineValidation.neighbors(
            entries: _vehicleRefuels,
            excludeId: widget.entry?.id,
            date: _refuelDate,
            odometer: odometer,
          )
        : RefuelTimelineValidation.neighborsByDate(
            entries: _vehicleRefuels,
            excludeId: widget.entry?.id,
            date: _refuelDate,
          );

    setState(() => _neighborBounds = bounds);
  }

  String? _odometerHint(String distanceUnit) {
    final prev = _neighborBounds?.previous;
    final next = _neighborBounds?.next;
    if (prev != null && next != null) {
      return 'Between ${prev.odometer.toStringAsFixed(0)} and '
          '${next.odometer.toStringAsFixed(0)} $distanceUnit';
    }
    if (prev != null) {
      return 'Above ${prev.odometer.toStringAsFixed(0)} $distanceUnit';
    }
    if (next != null) {
      return 'Below ${next.odometer.toStringAsFixed(0)} $distanceUnit';
    }
    return null;
  }

  String? _timelineError(double odometer, String distanceUnit) {
    return RefuelTimelineValidation.validate(
      vehicleEntries: _vehicleRefuels,
      excludeId: widget.entry?.id,
      refuelDate: _refuelDate,
      odometer: odometer,
      distanceUnit: distanceUnit,
    );
  }

  void _onQuantityChanged() => _onPriceFieldEdited(RefuelPriceField.quantity);

  void _onPriceChanged() =>
      _onPriceFieldEdited(RefuelPriceField.pricePerLiter);

  void _onTotalChanged() => _onPriceFieldEdited(RefuelPriceField.totalPrice);

  void _onPriceFieldEdited(RefuelPriceField field) {
    if (_suppressCalc) return;
    setState(() {
      _manualOrder =
          RefuelCalculation.trackManualEdit(_manualOrder, field);
    });
    _recalculate();
  }

  void _recalculate() {
    final manual = _manualOrder.toSet();
    final result = RefuelCalculation.calculate(
      RefuelCalculationInput(
        quantity: RefuelCalculation.parseValue(_quantityController.text),
        pricePerLiter:
            RefuelCalculation.parseValue(_pricePerLiterController.text),
        totalPrice: RefuelCalculation.parseValue(_totalPriceController.text),
        manualFields: manual,
      ),
    );

    _derivedField = result.derivedField;
    _suppressCalc = true;
    try {
      if (result.derivedField == RefuelPriceField.quantity &&
          result.quantity != null) {
        _quantityController.text =
            RefuelCalculation.formatQuantity(result.quantity!);
      } else if (result.derivedField == RefuelPriceField.pricePerLiter &&
          result.pricePerLiter != null) {
        _pricePerLiterController.text =
            RefuelCalculation.formatMoney(result.pricePerLiter!);
      } else if (result.derivedField == RefuelPriceField.totalPrice &&
          result.totalPrice != null) {
        _totalPriceController.text =
            RefuelCalculation.formatMoney(result.totalPrice!);
      }
    } finally {
      _suppressCalc = false;
    }
    if (mounted) setState(() {});
  }

  bool _isDerived(RefuelPriceField field) => _derivedField == field;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _refuelDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _refuelDate = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _refuelDate.hour,
        _refuelDate.minute,
      );
    });
    _refreshTimelineBounds();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_refuelDate),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _refuelDate = DateTime(
        _refuelDate.year,
        _refuelDate.month,
        _refuelDate.day,
        picked.hour,
        picked.minute,
      );
    });
    _refreshTimelineBounds();
  }

  Future<void> _selectVehicle(Vehicle vehicle) async {
    if (_locksVehicleFields) return;
    setState(() => _vehicle = vehicle);
    final settings = await ref.read(settingsProvider.future);
    await ref.read(settingsProvider.notifier).updateSettings(
          settings.copyWith(selectedVehicleId: vehicle.id),
        );
    if (vehicle.id != null) {
      await _loadVehicleHints(vehicle.id!);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final vehicle = _vehicle;
    if (vehicle?.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a vehicle first')),
      );
      return;
    }

    _recalculate();

    final quantity = RefuelCalculation.parseValue(_quantityController.text);
    final pricePerLiter =
        RefuelCalculation.parseValue(_pricePerLiterController.text);
    final totalPrice =
        RefuelCalculation.parseValue(_totalPriceController.text);
    final odometer = RefuelCalculation.parseValue(_odometerController.text);

    if (quantity == null ||
        quantity <= 0 ||
        totalPrice == null ||
        totalPrice <= 0 ||
        pricePerLiter == null ||
        pricePerLiter <= 0 ||
        odometer == null ||
        odometer <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter quantity, price, and total (or two to auto-calc)'),
        ),
      );
      return;
    }

    final distanceUnit = ref.read(settingsProvider).valueOrNull?.distanceUnit.abbreviation ?? 'km';
    final timelineError = _timelineError(odometer, distanceUnit);
    if (timelineError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(timelineError)),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final entry = RefuelEntry(
        id: widget.entry?.id,
        vehicleId: vehicle!.id!,
        refuelDate: _refuelDate,
        odometer: odometer,
        quantity: quantity,
        pricePerLiter: pricePerLiter,
        totalPrice: totalPrice,
        fuelType: vehicle.fuelType,
        stationName: _stationController.text.trim().isEmpty
            ? null
            : _stationController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: widget.entry?.createdAt ?? now,
        updatedAt: now,
      );

      if (widget.isEditing) {
        await ref.read(refuelsProvider.notifier).updateEntry(entry);
      } else {
        await ref.read(refuelsProvider.notifier).addEntry(entry);
      }
      ref.invalidate(dashboardProvider);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditing
                  ? 'Refuel updated for ${vehicle.displayName}'
                  : 'Refuel saved for ${vehicle.displayName}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _promptAddVehicle() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AddEditVehicleScreen(),
      ),
    );
    if (!mounted) return;
    await _initialize();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider).valueOrNull;
    final vehicles = ref.watch(vehiclesProvider).valueOrNull ?? [];
    final currency = settings?.currencyCode ?? 'OMR';
    final distanceUnit = settings?.distanceUnit.abbreviation ?? 'km';
    final dateFormat = DateFormat.yMMMd();
    final timeFormat = DateFormat.Hm();
    final vehicle = _vehicle;
    final fuelType = vehicle?.fuelType ?? FuelType.petrol;
    final priceLabel = FuelTypeMetrics.pricePerQuantityLabel(fuelType);

    if (vehicles.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.isEditing ? 'Edit Refuel' : 'Add Refuel')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.stackLg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.directions_car_outlined,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: AppSpacing.stackLg),
                Text(
                  'Add a vehicle first',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.stackSm),
                Text(
                  'You need at least one vehicle before logging a refuel.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.stackLg),
                OnboardingPrimaryButton(
                  label: 'Add Vehicle',
                  icon: Icons.add,
                  onPressed: _promptAddVehicle,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Edit Refuel' : 'Add Refuel',
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
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
            if (vehicle != null) _VehicleHeroCard(vehicle: vehicle),
            const SizedBox(height: AppSpacing.stackLg),
            Row(
              children: [
                Expanded(
                  child: RefuelFieldContainer(
                    label: 'Date',
                    child: InkWell(
                      onTap: _pickDate,
                      child: Text(
                        dateFormat.format(_refuelDate),
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.gutter),
                Expanded(
                  child: RefuelFieldContainer(
                    label: 'Time',
                    child: InkWell(
                      onTap: _pickTime,
                      child: Text(
                        timeFormat.format(_refuelDate),
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.stackMd),
            Row(
              children: [
                Expanded(
                  child: !_locksVehicleFields && vehicles.length > 1
                      ? RefuelFieldContainer(
                          label: 'Vehicle',
                          readOnly: true,
                          icon: Icons.directions_car_outlined,
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<Vehicle>(
                              value: vehicle,
                              isExpanded: true,
                              items: vehicles
                                  .map(
                                    (v) => DropdownMenuItem(
                                      value: v,
                                      child: Text(v.displayName),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) _selectVehicle(v);
                              },
                            ),
                          ),
                        )
                      : RefuelFieldContainer(
                          label: 'Vehicle',
                          readOnly: true,
                          icon: Icons.directions_car_outlined,
                          child: Text(
                            vehicle?.displayName ?? '—',
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                ),
                const SizedBox(width: AppSpacing.gutter),
                Expanded(
                  child: RefuelFieldContainer(
                    label: 'Fuel Type',
                    readOnly: true,
                    icon: Icons.local_gas_station_outlined,
                    child: Text(
                      vehicle?.fuelType.label ?? '—',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.stackMd),
            RefuelFieldContainer(
              label: 'Odometer ($distanceUnit)',
              icon: Icons.speed_outlined,
              child: TextFormField(
                controller: _odometerController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                ],
                decoration: InputDecoration(
                  hintText: _odometerHint(distanceUnit) ?? 'Enter reading',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                style: theme.textTheme.titleLarge,
                validator: (value) {
                  final parsed = RefuelCalculation.parseValue(value);
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a valid odometer reading';
                  }
                  return _timelineError(parsed, distanceUnit);
                },
              ),
            ),
            const SizedBox(height: AppSpacing.stackMd),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: RefuelFieldContainer(
                    label: FuelTypeMetrics.quantityFieldLabel(fuelType),
                    icon: Icons.local_gas_station_outlined,
                    autoCalculated: _isDerived(RefuelPriceField.quantity),
                    child: TextFormField(
                      controller: _quantityController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                      ],
                      decoration: const InputDecoration(
                        hintText: '0.00',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.gutter),
                Expanded(
                  child: RefuelFieldContainer(
                    label: '$priceLabel ($currency)',
                    icon: Icons.payments_outlined,
                    autoCalculated: _isDerived(RefuelPriceField.pricePerLiter),
                    child: TextFormField(
                      controller: _pricePerLiterController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                      ],
                      decoration: const InputDecoration(
                        hintText: '0.000',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.stackMd),
            RefuelFieldContainer(
              label: 'Total Price ($currency)',
              icon: Icons.account_balance_wallet_outlined,
              highlighted: true,
              autoCalculated: _isDerived(RefuelPriceField.totalPrice),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _totalPriceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                      ],
                      decoration: const InputDecoration(
                        hintText: '0.000',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_isDerived(RefuelPriceField.totalPrice))
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bolt,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'AUTO',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.stackMd),
            RefuelFieldContainer(
              label: 'Station Name',
              icon: Icons.location_on_outlined,
              child: TextFormField(
                controller: _stationController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Shell Al Khuwair',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                style: theme.textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: AppSpacing.stackMd),
            RefuelFieldContainer(
              label: 'Notes',
              icon: Icons.notes_outlined,
              child: TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Add additional details...',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                style: theme.textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.marginMobile),
          child: OnboardingPrimaryButton(
            label: widget.isEditing ? 'Save Changes' : 'Save Entry',
            icon: Icons.save_outlined,
            loading: _saving,
            onPressed: _save,
          ),
        ),
      ),
    );
  }
}

class _VehicleHeroCard extends StatelessWidget {
  const _VehicleHeroCard({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = context.cs;
    final pal = context.palette;
    final subtitle = [
      vehicle.fuelType.label,
      if (vehicle.licensePlate?.isNotEmpty == true) vehicle.licensePlate,
    ].join(' • ');

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: pal.fuel.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Icon(
              Icons.directions_car_filled_outlined,
              color: pal.fuel,
              size: 40,
            ),
          ),
          const SizedBox(width: AppSpacing.gutter),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle.displayName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
