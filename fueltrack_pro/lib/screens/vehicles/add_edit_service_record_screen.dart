import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/enums.dart';
import '../../models/service_record.dart';
import '../../providers/service_records_provider.dart';
import '../../theme/app_spacing.dart';
import '../../theme/theme_x.dart';

class AddEditServiceRecordScreen extends ConsumerStatefulWidget {
  const AddEditServiceRecordScreen({
    super.key,
    required this.vehicleId,
    this.record,
  });

  final int vehicleId;
  final ServiceRecord? record;

  static Future<void> open(
    BuildContext context, {
    required int vehicleId,
    ServiceRecord? record,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AddEditServiceRecordScreen(
          vehicleId: vehicleId,
          record: record,
        ),
      ),
    );
  }

  @override
  ConsumerState<AddEditServiceRecordScreen> createState() =>
      _AddEditServiceRecordScreenState();
}

class _AddEditServiceRecordScreenState
    extends ConsumerState<AddEditServiceRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.record?.title);
  late final _notes = TextEditingController(text: widget.record?.notes);
  late final _dueOdometer = TextEditingController(
    text: widget.record?.dueOdometer?.toStringAsFixed(0) ?? '',
  );
  late final _notifyDays = TextEditingController(
    text: widget.record?.notifyBeforeDays.toString() ?? '7',
  );
  late final _notifyKm = TextEditingController(
    text: widget.record?.notifyBeforeKm?.toStringAsFixed(0) ?? '',
  );

  late ServiceTriggerType _triggerType =
      widget.record?.triggerType ?? ServiceTriggerType.date;
  late DateTime? _dueDate = widget.record?.dueDate;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    _dueOdometer.dispose();
    _notifyDays.dispose();
    _notifyKm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final now = DateTime.now();
    final record = ServiceRecord(
      id: widget.record?.id,
      vehicleId: widget.vehicleId,
      title: _title.text.trim(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      triggerType: _triggerType,
      dueDate: (_triggerType == ServiceTriggerType.date ||
              _triggerType == ServiceTriggerType.both)
          ? _dueDate
          : null,
      dueOdometer: (_triggerType == ServiceTriggerType.odometer ||
              _triggerType == ServiceTriggerType.both)
          ? double.tryParse(_dueOdometer.text)
          : null,
      notifyBeforeDays: int.tryParse(_notifyDays.text) ?? 7,
      notifyBeforeKm: _notifyKm.text.isNotEmpty
          ? double.tryParse(_notifyKm.text)
          : null,
      createdAt: widget.record?.createdAt ?? now,
      updatedAt: now,
    );

    if (widget.record == null) {
      await ref
          .read(vehicleServiceRecordsProvider(widget.vehicleId).notifier)
          .add(record);
    } else {
      await ref
          .read(vehicleServiceRecordsProvider(widget.vehicleId).notifier)
          .save(record);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    final cs = context.cs;
    final showDate = _triggerType == ServiceTriggerType.date ||
        _triggerType == ServiceTriggerType.both;
    final showOdometer = _triggerType == ServiceTriggerType.odometer ||
        _triggerType == ServiceTriggerType.both;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.record == null ? 'Add Service' : 'Edit Service',
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
              controller: _title,
              decoration:
                  const InputDecoration(labelText: 'Service title *'),
              validator: (v) =>
                  (v?.trim().isEmpty ?? true) ? 'Required' : null,
            ),
            const SizedBox(height: AppSpacing.stackMd),
            TextFormField(
              controller: _notes,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.stackLg),
            Text(
              'Trigger',
              style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.stackSm),
            SegmentedButton<ServiceTriggerType>(
              segments: ServiceTriggerType.values
                  .map((t) => ButtonSegment(value: t, label: Text(t.label)))
                  .toList(),
              selected: {_triggerType},
              onSelectionChanged: (s) =>
                  setState(() => _triggerType = s.first),
            ),
            if (showDate) ...[
              const SizedBox(height: AppSpacing.stackMd),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Due date'),
                subtitle: Text(
                  _dueDate != null
                      ? DateFormat.yMMMd().format(_dueDate!)
                      : 'Tap to pick a date',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_dueDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() => _dueDate = null),
                      ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today_outlined, size: 18),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _dueDate ?? DateTime.now(),
                          firstDate: DateTime.now()
                              .subtract(const Duration(days: 365)),
                          lastDate: DateTime.now()
                              .add(const Duration(days: 365 * 5)),
                        );
                        if (picked != null) setState(() => _dueDate = picked);
                      },
                    ),
                  ],
                ),
              ),
              TextFormField(
                controller: _notifyDays,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Notify before (days)',
                ),
              ),
            ],
            if (showOdometer) ...[
              const SizedBox(height: AppSpacing.stackMd),
              TextFormField(
                controller: _dueOdometer,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Due odometer'),
                validator: (v) {
                  if (showOdometer && (v == null || v.trim().isEmpty)) {
                    return 'Enter odometer reading';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.stackSm),
              TextFormField(
                controller: _notifyKm,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Notify before (km)',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
