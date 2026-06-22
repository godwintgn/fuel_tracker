import 'package:flutter/material.dart';

import '../../data/history_filters.dart';
import '../../models/enums.dart';
import '../../models/vehicle.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../onboarding/onboarding_widgets.dart';

class HistoryFiltersSheet extends StatefulWidget {
  const HistoryFiltersSheet({
    super.key,
    required this.initialFilters,
    required this.vehicles,
  });

  final HistoryFilters initialFilters;
  final List<Vehicle> vehicles;

  static Future<HistoryFilters?> show(
    BuildContext context, {
    required HistoryFilters initialFilters,
    required List<Vehicle> vehicles,
  }) {
    return showModalBottomSheet<HistoryFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HistoryFiltersSheet(
        initialFilters: initialFilters,
        vehicles: vehicles,
      ),
    );
  }

  @override
  State<HistoryFiltersSheet> createState() => _HistoryFiltersSheetState();
}

class _HistoryFiltersSheetState extends State<HistoryFiltersSheet> {
  late int? _vehicleId;
  late FuelType? _fuelType;
  late HistoryDateRange _dateRange;
  DateTime? _customStart;
  DateTime? _customEnd;

  @override
  void initState() {
    super.initState();
    _vehicleId = widget.initialFilters.vehicleId;
    _fuelType = widget.initialFilters.fuelType;
    _dateRange = widget.initialFilters.dateRange;
    _customStart = widget.initialFilters.customStart;
    _customEnd = widget.initialFilters.customEnd;
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final start = await showDatePicker(
      context: context,
      initialDate: _customStart ?? now.subtract(const Duration(days: 30)),
      firstDate: DateTime(2000),
      lastDate: now,
      helpText: 'Start date',
    );
    if (start == null || !mounted) return;

    final end = await showDatePicker(
      context: context,
      initialDate: _customEnd ?? now,
      firstDate: start,
      lastDate: now,
      helpText: 'End date',
    );
    if (end == null || !mounted) return;

    setState(() {
      _customStart = start;
      _customEnd = end;
      _dateRange = HistoryDateRange.custom;
    });
  }

  void _reset() {
    setState(() {
      _vehicleId = null;
      _fuelType = null;
      _dateRange = HistoryDateRange.all;
      _customStart = null;
      _customEnd = null;
    });
  }

  void _apply() {
    Navigator.pop(
      context,
      widget.initialFilters.copyWith(
        vehicleId: _vehicleId,
        fuelType: _fuelType,
        dateRange: _dateRange,
        customStart: _customStart,
        customEnd: _customEnd,
        clearVehicle: _vehicleId == null,
        clearFuelType: _fuelType == null,
        clearCustomDates:
            _dateRange != HistoryDateRange.custom,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(32),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 48,
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.marginMobile,
                AppSpacing.gutter,
                AppSpacing.marginMobile,
                AppSpacing.stackMd,
              ),
              child: Row(
                children: [
                  Text('Filters', style: theme.textTheme.headlineSmall),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.marginMobile,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Vehicle', style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.stackMd),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        SelectionChip(
                          label: 'All vehicles',
                          compact: true,
                          selected: _vehicleId == null,
                          onTap: () => setState(() => _vehicleId = null),
                        ),
                        ...widget.vehicles.map(
                          (vehicle) => SelectionChip(
                            label: vehicle.displayName,
                            compact: true,
                            icon: Icons.directions_car_outlined,
                            selected: _vehicleId == vehicle.id,
                            onTap: () =>
                                setState(() => _vehicleId = vehicle.id),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.stackLg),
                    Text('Fuel Type', style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.stackMd),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        SelectionChip(
                          label: 'All types',
                          compact: true,
                          selected: _fuelType == null,
                          onTap: () => setState(() => _fuelType = null),
                        ),
                        ...FuelType.values.map(
                          (type) => SelectionChip(
                            label: type.label,
                            compact: true,
                            selected: _fuelType == type,
                            onTap: () => setState(() => _fuelType = type),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.stackLg),
                    Text('Date Range', style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.stackMd),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: HistoryDateRange.values.map((range) {
                        return SelectionChip(
                          label: range.label,
                          compact: true,
                          selected: _dateRange == range,
                          onTap: () {
                            if (range == HistoryDateRange.custom) {
                              _pickCustomRange();
                            } else {
                              setState(() => _dateRange = range);
                            }
                          },
                        );
                      }).toList(),
                    ),
                    if (_dateRange == HistoryDateRange.custom &&
                        _customStart != null &&
                        _customEnd != null)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.stackMd),
                        child: Text(
                          '${_customStart!.toLocal().toString().split(' ').first} → '
                          '${_customEnd!.toLocal().toString().split(' ').first}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.marginMobile),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _reset,
                      child: const Text('Reset All'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.gutter),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _apply,
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
