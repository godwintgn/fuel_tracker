import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/report_filters.dart';
import '../../providers/refuels_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/vehicles_provider.dart';
import '../../services/fuel_report_service.dart';
import '../../theme/app_spacing.dart';
import '../../theme/theme_x.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  static Future<void> open(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ReportsScreen()),
    );
  }

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  ReportPeriod _period = ReportPeriod.last30Days;
  DateTime? _customStart;
  DateTime? _customEnd;
  final Set<int> _selectedVehicleIds = {};
  var _allVehicles = true;
  var _exporting = false;

  ReportFilters get _filters => ReportFilters(
        period: _period,
        customStart: _customStart,
        customEnd: _customEnd,
        vehicleIds: _allVehicles ? const {} : Set<int>.from(_selectedVehicleIds),
      );

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final initialStart = _customStart ?? now.subtract(const Duration(days: 30));
    final initialEnd = _customEnd ?? now;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: now,
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
      helpText: 'Select report period',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _period = ReportPeriod.custom;
      _customStart = picked.start;
      _customEnd = picked.end;
    });
  }

  Future<({FuelReportData data, Uint8List bytes, String fileName})?>
      _buildReportBundle() async {
    final settings = ref.read(settingsProvider).valueOrNull;
    final refuels = ref.read(refuelsProvider).valueOrNull;
    final vehicles = ref.read(vehiclesProvider).valueOrNull;

    if (settings == null || refuels == null || vehicles == null) {
      return null;
    }

    final reportData = FuelReportService.build(
      filters: _filters,
      allEntries: refuels,
      allVehicles: vehicles,
    );
    if (reportData.entries.isEmpty) {
      return null;
    }

    final reportId = FuelReportService.generateReportId();
    final bytes = await FuelReportService.buildPdfBytes(
      data: reportData,
      settings: settings,
      reportId: reportId,
    );
    final fileName = FuelReportService.suggestedFileName(
      reportData,
      reportId: reportId,
    );

    return (data: reportData, bytes: bytes, fileName: fileName);
  }

  Future<void> _exportPdf() async {
    if (!_allVehicles && _selectedVehicleIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one vehicle')),
      );
      return;
    }

    setState(() => _exporting = true);
    try {
      final bundle = await _buildReportBundle();
      if (!mounted) return;
      if (bundle == null) {
        final loading = ref.read(settingsProvider).valueOrNull == null ||
            ref.read(refuelsProvider).valueOrNull == null ||
            ref.read(vehiclesProvider).valueOrNull == null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              loading
                  ? 'Loading data — try again in a moment'
                  : 'No refuels match the selected filters',
            ),
          ),
        );
        return;
      }

      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Export fuel report (PDF)',
        fileName: bundle.fileName,
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        bytes: bundle.bytes,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            outputPath == null
                ? 'Export cancelled'
                : 'PDF report exported successfully',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _sharePdf() async {
    if (!_allVehicles && _selectedVehicleIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one vehicle')),
      );
      return;
    }

    setState(() => _exporting = true);
    try {
      final bundle = await _buildReportBundle();
      if (!mounted) return;
      if (bundle == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No refuels match the selected filters')),
        );
        return;
      }

      await Share.shareXFiles(
        [
          XFile.fromData(
            bundle.bytes,
            name: bundle.fileName,
            mimeType: 'application/pdf',
          ),
        ],
        subject: 'FuelTrack Pro fuel report',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = context.cs;
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final refuelsAsync = ref.watch(refuelsProvider);
    final settings = ref.watch(settingsProvider).valueOrNull;

    final vehicles = vehiclesAsync.valueOrNull ?? const [];
    final refuels = refuelsAsync.valueOrNull ?? const [];
    final preview = FuelReportService.build(
      filters: _filters,
      allEntries: refuels,
      allVehicles: vehicles,
    );

    final spentLabel = settings != null
        ? '${settings.currencySymbol} ${preview.totalSpent.toStringAsFixed(2)}'
        : preview.totalSpent.toStringAsFixed(2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.marginMobile),
        children: [
          Text(
            'Generate a formatted PDF with fuel spending, efficiency, and refuel history for the period and vehicles you choose.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.stackLg),
          Text('Time period', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.stackMd),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ReportPeriod.values.map((period) {
              if (period == ReportPeriod.custom) {
                return FilterChip(
                  label: Text(
                    _period == ReportPeriod.custom && _customStart != null
                        ? _customRangeLabel()
                        : period.label,
                  ),
                  selected: _period == ReportPeriod.custom,
                  onSelected: _exporting ? null : (_) => _pickCustomRange(),
                );
              }
              return FilterChip(
                label: Text(period.label),
                selected: _period == period,
                onSelected: _exporting
                    ? null
                    : (_) => setState(() => _period = period),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.stackLg),
          Text('Vehicles', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.stackSm),
          Text(
            'Choose all vehicles or select one or more.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.stackMd),
          FilterChip(
            label: const Text('All vehicles'),
            selected: _allVehicles,
            onSelected: _exporting
                ? null
                : (selected) {
                    setState(() {
                      _allVehicles = selected;
                      if (selected) _selectedVehicleIds.clear();
                    });
                  },
          ),
          if (!_allVehicles) ...[
            const SizedBox(height: AppSpacing.stackSm),
            if (vehiclesAsync.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(),
              )
            else if (vehicles.isEmpty)
              Text(
                'No vehicles yet — add one in Settings.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: vehicles.map((vehicle) {
                  final id = vehicle.id;
                  if (id == null) return const SizedBox.shrink();
                  return FilterChip(
                    label: Text(vehicle.name),
                    selected: _selectedVehicleIds.contains(id),
                    onSelected: _exporting
                        ? null
                        : (selected) {
                            setState(() {
                              if (selected) {
                                _selectedVehicleIds.add(id);
                              } else {
                                _selectedVehicleIds.remove(id);
                              }
                            });
                          },
                  );
                }).toList(),
              ),
          ],
          const SizedBox(height: AppSpacing.stackLg),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Preview', style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.stackMd),
                  _PreviewRow(
                    label: 'Period',
                    value: FuelReportService.periodLabel(preview),
                  ),
                  _PreviewRow(
                    label: 'Refuels',
                    value: '${preview.fillCount}',
                  ),
                  _PreviewRow(
                    label: 'Total spent',
                    value: spentLabel,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.stackLg),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _exporting ||
                          refuelsAsync.isLoading ||
                          vehiclesAsync.isLoading
                      ? null
                      : _exportPdf,
                  icon: _exporting
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.onPrimary,
                          ),
                        )
                      : const Icon(Icons.picture_as_pdf_outlined),
                  label: Text(_exporting ? 'Working…' : 'Export PDF'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _exporting ||
                          refuelsAsync.isLoading ||
                          vehiclesAsync.isLoading
                      ? null
                      : _sharePdf,
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Share'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _customRangeLabel() {
    if (_customStart == null || _customEnd == null) return 'Custom';
    final fmt = DateFormat.yMMMd();
    return '${fmt.format(_customStart!)} – ${fmt.format(_customEnd!)}';
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
