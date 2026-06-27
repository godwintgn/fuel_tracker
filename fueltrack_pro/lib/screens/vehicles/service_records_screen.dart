import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/service_record.dart';
import '../../models/vehicle.dart';
import '../../providers/service_records_provider.dart';
import '../../theme/app_spacing.dart';
import '../../theme/theme_x.dart';
import '../../widgets/common/app_card.dart';
import 'add_edit_service_record_screen.dart';

class ServiceRecordsScreen extends ConsumerWidget {
  const ServiceRecordsScreen({super.key, required this.vehicle});

  final Vehicle vehicle;

  static Future<void> open(BuildContext context, {required Vehicle vehicle}) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ServiceRecordsScreen(vehicle: vehicle),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = context.cs;
    final tt = context.tt;
    final vehicleId = vehicle.id!;
    final recordsAsync = ref.watch(vehicleServiceRecordsProvider(vehicleId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${vehicle.name} — Services',
          style: tt.titleMedium?.copyWith(
            color: cs.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            AddEditServiceRecordScreen.open(context, vehicleId: vehicleId),
        icon: const Icon(Icons.add),
        label: const Text('Add service'),
      ),
      body: recordsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (records) {
          if (records.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.build_outlined, size: 48, color: cs.onSurfaceVariant),
                  const SizedBox(height: AppSpacing.stackMd),
                  Text(
                    'No service records',
                    style: tt.titleSmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.stackSm),
                  Text(
                    'Tap + to add your first service reminder',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }

          final active = records.where((r) => !r.isCompleted).toList();
          final completed = records.where((r) => r.isCompleted).toList();

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            children: [
              if (active.isNotEmpty) ...[
                Text(
                  'Upcoming',
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.stackSm),
                ...active.map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.stackMd),
                    child: _ServiceCard(
                      record: r,
                      vehicleId: vehicleId,
                      ref: ref,
                    ),
                  ),
                ),
              ],
              if (completed.isNotEmpty) ...[
                if (active.isNotEmpty)
                  const SizedBox(height: AppSpacing.stackMd),
                Text(
                  'Completed',
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.stackSm),
                ...completed.map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.stackMd),
                    child: _ServiceCard(
                      record: r,
                      vehicleId: vehicleId,
                      ref: ref,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.record,
    required this.vehicleId,
    required this.ref,
  });

  final ServiceRecord record;
  final int vehicleId;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final tt = context.tt;
    final isOverdue = record.isOverdue;
    final accentColor = record.isCompleted
        ? cs.onSurfaceVariant
        : isOverdue
            ? cs.error
            : cs.primary;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  record.isCompleted
                      ? Icons.check_circle_outline
                      : isOverdue
                          ? Icons.warning_outlined
                          : Icons.build_outlined,
                  size: 18,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.title,
                      style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (isOverdue && !record.isCompleted)
                      Text(
                        'Overdue',
                        style: tt.labelSmall?.copyWith(color: cs.error),
                      ),
                  ],
                ),
              ),
              if (!record.isCompleted)
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  iconSize: 18,
                  onSelected: (v) async {
                    if (v == 'edit') {
                      await AddEditServiceRecordScreen.open(
                        context,
                        vehicleId: vehicleId,
                        record: record,
                      );
                    } else if (v == 'complete') {
                      if (context.mounted) await _completeRecord(context);
                    } else if (v == 'delete') {
                      if (context.mounted) await _deleteRecord(context);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(
                      value: 'complete',
                      child: Text('Mark complete'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Delete',
                        style: TextStyle(color: cs.error),
                      ),
                    ),
                  ],
                )
              else
                IconButton(
                  icon: Icon(Icons.delete_outline, size: 18, color: cs.error),
                  onPressed: () => _deleteRecord(context),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              if (record.dueDate != null)
                _InfoChip(
                  icon: Icons.calendar_today_outlined,
                  label: DateFormat.yMMMd().format(record.dueDate!),
                  cs: cs,
                  tt: tt,
                  color: isOverdue && !record.isCompleted ? cs.error : null,
                ),
              if (record.dueOdometer != null)
                _InfoChip(
                  icon: Icons.speed_outlined,
                  label: '${record.dueOdometer!.toStringAsFixed(0)} km',
                  cs: cs,
                  tt: tt,
                ),
              if (record.isCompleted && record.completedDate != null)
                _InfoChip(
                  icon: Icons.check_outlined,
                  label: 'Done ${DateFormat.yMMMd().format(record.completedDate!)}',
                  cs: cs,
                  tt: tt,
                  color: cs.primary,
                ),
              if (record.notes?.isNotEmpty == true)
                _InfoChip(
                  icon: Icons.notes_outlined,
                  label: record.notes!,
                  cs: cs,
                  tt: tt,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _completeRecord(BuildContext context) async {
    DateTime? nextDate;
    double? nextOdometer;
    await showDialog<void>(
      context: context,
      builder: (ctx) => _NextServiceDialog(
        onConfirm: (date, odometer) {
          nextDate = date;
          nextOdometer = odometer;
          Navigator.pop(ctx);
        },
        onSkip: () => Navigator.pop(ctx),
      ),
    );
    await ref
        .read(vehicleServiceRecordsProvider(vehicleId).notifier)
        .complete(record, nextDate: nextDate, nextOdometer: nextOdometer);
  }

  Future<void> _deleteRecord(BuildContext context) async {
    final cs = context.cs;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete service?'),
        content: Text('Remove "${record.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: cs.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && record.id != null) {
      await ref
          .read(vehicleServiceRecordsProvider(vehicleId).notifier)
          .remove(record.id!);
    }
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.cs,
    required this.tt,
    this.color,
  });

  final IconData icon;
  final String label;
  final ColorScheme cs;
  final TextTheme tt;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? cs.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: c),
          const SizedBox(width: 4),
          Text(
            label,
            style: tt.labelSmall?.copyWith(color: c, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _NextServiceDialog extends StatefulWidget {
  const _NextServiceDialog({required this.onConfirm, required this.onSkip});

  final void Function(DateTime? date, double? odometer) onConfirm;
  final VoidCallback onSkip;

  @override
  State<_NextServiceDialog> createState() => _NextServiceDialogState();
}

class _NextServiceDialogState extends State<_NextServiceDialog> {
  final _odoCtrl = TextEditingController();
  DateTime? _nextDate;

  @override
  void dispose() {
    _odoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Schedule next service?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Optionally set next service date or odometer:'),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              _nextDate != null
                  ? DateFormat.yMMMd().format(_nextDate!)
                  : 'No date set',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            trailing: IconButton(
              icon: const Icon(Icons.calendar_today_outlined, size: 18),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 90)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                );
                if (picked != null) setState(() => _nextDate = picked);
              },
            ),
          ),
          TextField(
            controller: _odoCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Next odometer (optional)',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: widget.onSkip,
          child: const Text('Skip'),
        ),
        FilledButton(
          onPressed: () => widget.onConfirm(
            _nextDate,
            double.tryParse(_odoCtrl.text),
          ),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
