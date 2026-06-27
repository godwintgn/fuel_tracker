import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/enums.dart';
import '../../models/fuel_card.dart';
import '../../providers/fuel_cards_provider.dart';
import '../../providers/vehicles_provider.dart';
import '../../theme/app_spacing.dart';
import '../../theme/theme_x.dart';

class AddEditFuelCardScreen extends ConsumerStatefulWidget {
  const AddEditFuelCardScreen({super.key, this.card, this.defaultVehicleId});

  final FuelCard? card;
  final int? defaultVehicleId;

  static Future<void> open(
    BuildContext context, {
    FuelCard? card,
    int? defaultVehicleId,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AddEditFuelCardScreen(
          card: card,
          defaultVehicleId: defaultVehicleId,
        ),
      ),
    );
  }

  @override
  ConsumerState<AddEditFuelCardScreen> createState() =>
      _AddEditFuelCardScreenState();
}

class _AddEditFuelCardScreenState
    extends ConsumerState<AddEditFuelCardScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.card?.name);
  late final _provider = TextEditingController(text: widget.card?.provider);
  late final _company = TextEditingController(text: widget.card?.companyName);
  late final _cardNum = TextEditingController(text: widget.card?.cardNumber);
  late final _limitVal = TextEditingController(
    text: widget.card?.limitValue?.toString() ?? '',
  );

  late FuelCardScope _scope =
      widget.card?.scope ?? FuelCardScope.fleet;
  late FuelCardLimitType _limitType =
      widget.card?.limitType ?? FuelCardLimitType.none;
  late FuelCardResetPeriod _resetPeriod =
      widget.card?.resetPeriod ?? FuelCardResetPeriod.none;
  late DateTime? _expiryDate = widget.card?.expiryDate;
  late bool _isActive = widget.card?.isActive ?? true;
  int? _vehicleId;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _vehicleId = widget.card?.vehicleId ?? widget.defaultVehicleId;
    if (_vehicleId != null) _scope = FuelCardScope.vehicle;
  }

  @override
  void dispose() {
    _name.dispose();
    _provider.dispose();
    _company.dispose();
    _cardNum.dispose();
    _limitVal.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final now = DateTime.now();
    final card = FuelCard(
      id: widget.card?.id,
      name: _name.text.trim(),
      provider: _provider.text.trim(),
      companyName: _company.text.trim().isEmpty ? null : _company.text.trim(),
      cardNumber: _cardNum.text.trim().isEmpty ? null : _cardNum.text.trim(),
      scope: _scope,
      vehicleId: _scope == FuelCardScope.vehicle ? _vehicleId : null,
      limitType: _limitType,
      limitValue: _limitType != FuelCardLimitType.none
          ? double.tryParse(_limitVal.text)
          : null,
      resetPeriod: _resetPeriod,
      expiryDate: _expiryDate,
      isActive: _isActive,
      createdAt: widget.card?.createdAt ?? now,
      updatedAt: now,
    );
    if (widget.card == null) {
      await ref.read(fuelCardsProvider.notifier).addCard(card);
    } else {
      await ref.read(fuelCardsProvider.notifier).updateCard(card);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    final cs = context.cs;
    final vehiclesAsync = ref.watch(vehiclesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.card == null ? 'Add Fuel Card' : 'Edit Fuel Card',
          style: tt.titleMedium?.copyWith(
            color: cs.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Card name *'),
              validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
            ),
            const SizedBox(height: AppSpacing.stackMd),
            TextFormField(
              controller: _provider,
              decoration: const InputDecoration(labelText: 'Provider *'),
              validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
            ),
            const SizedBox(height: AppSpacing.stackMd),
            TextFormField(
              controller: _company,
              decoration:
                  const InputDecoration(labelText: 'Company name (optional)'),
            ),
            const SizedBox(height: AppSpacing.stackMd),
            TextFormField(
              controller: _cardNum,
              decoration:
                  const InputDecoration(labelText: 'Card number (optional)'),
            ),
            const SizedBox(height: AppSpacing.stackLg),
            Text('Scope', style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.stackSm),
            SegmentedButton<FuelCardScope>(
              segments: FuelCardScope.values
                  .map((s) => ButtonSegment(
                        value: s,
                        label: Text(s.label),
                      ))
                  .toList(),
              selected: {_scope},
              onSelectionChanged: (s) => setState(() => _scope = s.first),
            ),
            if (_scope == FuelCardScope.vehicle) ...[
              const SizedBox(height: AppSpacing.stackMd),
                vehiclesAsync.when(
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('$e'),
                data: (vehicles) => DropdownButtonFormField<int>(
                  // ignore: deprecated_member_use
                  value: vehicles.any((v) => v.id == _vehicleId) ? _vehicleId : null,
                  decoration: const InputDecoration(labelText: 'Vehicle *'),
                  items: vehicles
                      .map((v) => DropdownMenuItem(
                            value: v.id,
                            child: Text(v.name),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _vehicleId = v),
                  validator: (v) =>
                      _scope == FuelCardScope.vehicle && v == null
                          ? 'Select a vehicle'
                          : null,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.stackLg),
            Text('Limit', style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.stackSm),
            SegmentedButton<FuelCardLimitType>(
              segments: FuelCardLimitType.values
                  .map((l) => ButtonSegment(value: l, label: Text(l.label)))
                  .toList(),
              selected: {_limitType},
              onSelectionChanged: (s) => setState(() => _limitType = s.first),
            ),
            if (_limitType != FuelCardLimitType.none) ...[
              const SizedBox(height: AppSpacing.stackMd),
              TextFormField(
                controller: _limitVal,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: _limitType == FuelCardLimitType.price
                      ? 'Price limit'
                      : 'Quantity limit (L)',
                ),
                validator: (v) => _limitType != FuelCardLimitType.none &&
                        (v == null || double.tryParse(v) == null)
                    ? 'Enter a valid number'
                    : null,
              ),
            ],
            const SizedBox(height: AppSpacing.stackLg),
            Text('Reset period', style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.stackSm),
            SegmentedButton<FuelCardResetPeriod>(
              segments: FuelCardResetPeriod.values
                  .map((r) => ButtonSegment(value: r, label: Text(r.label)))
                  .toList(),
              selected: {_resetPeriod},
              onSelectionChanged: (s) =>
                  setState(() => _resetPeriod = s.first),
            ),
            const SizedBox(height: AppSpacing.stackLg),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Expiry date'),
              subtitle: Text(
                _expiryDate != null
                    ? DateFormat.yMMMd().format(_expiryDate!)
                    : 'No expiry',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_expiryDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => setState(() => _expiryDate = null),
                    ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today_outlined, size: 18),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _expiryDate ??
                            DateTime.now().add(const Duration(days: 365)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                      );
                      if (picked != null) setState(() => _expiryDate = picked);
                    },
                  ),
                ],
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active'),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
          ],
        ),
      ),
    );
  }
}
