import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/app_settings.dart';
import '../models/refuel_entry.dart';
import '../models/report_filters.dart';
import '../models/vehicle.dart';
import 'fuel_calculations.dart';

class VehicleReportSummary {
  const VehicleReportSummary({
    required this.vehicle,
    required this.fillCount,
    required this.totalSpent,
    required this.totalLiters,
    this.avgKmPerLiter,
  });

  final Vehicle vehicle;
  final int fillCount;
  final double totalSpent;
  final double totalLiters;
  final double? avgKmPerLiter;
}

class FuelReportData {
  const FuelReportData({
    required this.filters,
    required this.rangeStart,
    required this.rangeEnd,
    required this.entries,
    required this.vehicles,
    required this.fillCount,
    required this.totalSpent,
    required this.totalLiters,
    this.avgKmPerLiter,
    this.costPerKm,
    required this.byVehicle,
    required this.monthlySpending,
  });

  final ReportFilters filters;
  final DateTime rangeStart;
  final DateTime rangeEnd;
  final List<RefuelEntry> entries;
  final List<Vehicle> vehicles;
  final int fillCount;
  final double totalSpent;
  final double totalLiters;
  final double? avgKmPerLiter;
  final double? costPerKm;
  final List<VehicleReportSummary> byVehicle;
  final Map<String, double> monthlySpending;
}

enum ReportExportStatus { saved, cancelled, failed, noData }

class ReportExportOutcome {
  const ReportExportOutcome(this.status, [this.message]);

  final ReportExportStatus status;
  final String? message;
}

abstract final class FuelReportService {
  static FuelReportData build({
    required ReportFilters filters,
    required List<RefuelEntry> allEntries,
    required List<Vehicle> allVehicles,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final range = filters.resolveRange(clock);

    final selectedVehicles = filters.allVehicles
        ? allVehicles
        : allVehicles.where((v) => v.id != null && filters.vehicleIds.contains(v.id)).toList();

    final entries = allEntries.where((e) {
      if (e.refuelDate.isBefore(range.start) || e.refuelDate.isAfter(range.end)) {
        return false;
      }
      if (filters.allVehicles) return true;
      return filters.vehicleIds.contains(e.vehicleId);
    }).toList()
      ..sort((a, b) => b.refuelDate.compareTo(a.refuelDate));

    final avg = FuelCalculations.averageKmPerLiter(entries);
    final costPerKm = FuelCalculations.costPerKm(
      entries: entries,
      since: range.start,
    );

    final byVehicle = <VehicleReportSummary>[];
    for (final vehicle in selectedVehicles) {
      final id = vehicle.id;
      if (id == null) continue;
      final vehicleEntries = entries.where((e) => e.vehicleId == id).toList();
      if (vehicleEntries.isEmpty) continue;
      byVehicle.add(
        VehicleReportSummary(
          vehicle: vehicle,
          fillCount: vehicleEntries.length,
          totalSpent: vehicleEntries.fold<double>(0, (s, e) => s + e.totalPrice),
          totalLiters: vehicleEntries.fold<double>(0, (s, e) => s + e.quantity),
          avgKmPerLiter: FuelCalculations.averageKmPerLiter(vehicleEntries),
        ),
      );
    }
    byVehicle.sort((a, b) => b.totalSpent.compareTo(a.totalSpent));

    final monthlySpending = <String, double>{};
    for (final entry in entries) {
      final key = DateFormat('yyyy-MM').format(entry.refuelDate);
      monthlySpending[key] = (monthlySpending[key] ?? 0) + entry.totalPrice;
    }

    return FuelReportData(
      filters: filters,
      rangeStart: range.start,
      rangeEnd: range.end,
      entries: entries,
      vehicles: selectedVehicles,
      fillCount: entries.length,
      totalSpent: entries.fold<double>(0, (s, e) => s + e.totalPrice),
      totalLiters: entries.fold<double>(0, (s, e) => s + e.quantity),
      avgKmPerLiter: avg,
      costPerKm: costPerKm,
      byVehicle: byVehicle,
      monthlySpending: monthlySpending,
    );
  }

  static String suggestedFileName(FuelReportData data, [DateTime? when]) {
    final stamp = DateFormat('yyyyMMdd').format(when ?? DateTime.now());
    final period = data.filters.period == ReportPeriod.custom
        ? 'custom'
        : data.filters.period.name;
    return 'fueltrack_pro_report_${period}_$stamp.pdf';
  }

  static String periodLabel(FuelReportData data) {
    if (data.filters.period == ReportPeriod.allTime) {
      return 'All time';
    }
    final fmt = DateFormat.yMMMd();
    return '${fmt.format(data.rangeStart)} – ${fmt.format(data.rangeEnd)}';
  }

  static String vehiclesLabel(FuelReportData data) {
    if (data.filters.allVehicles) return 'All vehicles';
    if (data.vehicles.length == 1) return data.vehicles.first.name;
    return data.vehicles.map((v) => v.name).join(', ');
  }

  static Future<Uint8List> buildPdfBytes({
    required FuelReportData data,
    required AppSettings settings,
  }) async {
    final currency = settings.currencySymbol;
    final distance = settings.distanceUnit.abbreviation;
    final fuelUnit = settings.fuelUnit.abbreviation;
    final dateFmt = DateFormat.yMMMd();
    final dateTimeFmt = DateFormat('yyyy-MM-dd HH:mm');
    final generatedAt = DateFormat.yMMMd().add_jm().format(DateTime.now());

    final doc = pw.Document();
    final green = PdfColor.fromHex('#0D631B');
    final muted = PdfColors.grey700;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 36),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'FuelTrack Pro',
                      style: pw.TextStyle(
                        fontSize: 11,
                        color: muted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Fuel Report',
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: green,
                      ),
                    ),
                  ],
                ),
                pw.Text(
                  'Page ${context.pageNumber}',
                  style: pw.TextStyle(fontSize: 9, color: muted),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Divider(color: PdfColors.grey300, thickness: 0.5),
            pw.SizedBox(height: 12),
          ],
        ),
        footer: (context) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 8),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Generated $generatedAt',
                style: pw.TextStyle(fontSize: 8, color: muted),
              ),
              pw.Text(
                'FuelTrack Pro · Local fuel analytics',
                style: pw.TextStyle(fontSize: 8, color: muted),
              ),
            ],
          ),
        ),
        build: (context) {
          final blocks = <pw.Widget>[
            _infoRow('Period', periodLabel(data)),
            _infoRow('Vehicles', vehiclesLabel(data)),
            pw.SizedBox(height: 20),
            pw.Text(
              'Summary',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: green,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _statBox('Refuels', '${data.fillCount}'),
                _statBox('Total spent', '$currency ${_fmtMoney(data.totalSpent)}'),
                _statBox('Fuel volume', '${_fmtQty(data.totalLiters)} $fuelUnit'),
                if (data.avgKmPerLiter != null)
                  _statBox(
                    'Avg efficiency',
                    '${data.avgKmPerLiter!.toStringAsFixed(2)} $distance/$fuelUnit',
                  ),
                if (data.costPerKm != null)
                  _statBox(
                    'Cost per $distance',
                    '$currency ${data.costPerKm!.toStringAsFixed(3)}',
                  ),
              ],
            ),
          ];

          if (data.byVehicle.length > 1) {
            blocks.addAll([
              pw.SizedBox(height: 24),
              pw.Text(
                'By vehicle',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: green,
                ),
              ),
              pw.SizedBox(height: 8),
              _vehicleTable(data, currency, distance, fuelUnit),
            ]);
          }

          if (data.monthlySpending.isNotEmpty) {
            blocks.addAll([
              pw.SizedBox(height: 24),
              pw.Text(
                'Monthly spending',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: green,
                ),
              ),
              pw.SizedBox(height: 8),
              _monthlyTable(data, currency),
            ]);
          }

          if (data.entries.isNotEmpty) {
            blocks.addAll([
              pw.SizedBox(height: 24),
              pw.Text(
                'Refuel history',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: green,
                ),
              ),
              pw.SizedBox(height: 8),
              _refuelTable(
                data: data,
                currency: currency,
                fuelUnit: fuelUnit,
                distance: distance,
                dateTimeFmt: dateTimeFmt,
                dateFmt: dateFmt,
              ),
            ]);
          } else {
            blocks.addAll([
              pw.SizedBox(height: 24),
              pw.Text(
                'No refuels found for the selected filters.',
                style: pw.TextStyle(fontSize: 11, color: muted),
              ),
            ]);
          }

          return blocks;
        },
      ),
    );

    return doc.save();
  }

  static pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '$label: ',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey800,
              ),
            ),
            pw.TextSpan(
              text: value,
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _statBox(String label, String value) {
    return pw.Container(
      width: 150,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _vehicleTable(
    FuelReportData data,
    String currency,
    String distance,
    String fuelUnit,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1.2),
        3: const pw.FlexColumnWidth(1.2),
        4: const pw.FlexColumnWidth(1.4),
      },
      children: [
        _tableHeaderRow([
          'Vehicle',
          'Fills',
          'Spent',
          'Volume',
          'Efficiency',
        ]),
        ...data.byVehicle.map((row) {
          final eff = row.avgKmPerLiter != null
              ? '${row.avgKmPerLiter!.toStringAsFixed(2)} $distance/$fuelUnit'
              : '—';
          return _tableDataRow([
            row.vehicle.name,
            '${row.fillCount}',
            '$currency ${_fmtMoney(row.totalSpent)}',
            '${_fmtQty(row.totalLiters)} $fuelUnit',
            eff,
          ]);
        }),
      ],
    );
  }

  static pw.Widget _monthlyTable(FuelReportData data, String currency) {
    final sortedKeys = data.monthlySpending.keys.toList()..sort();
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1),
      },
      children: [
        _tableHeaderRow(['Month', 'Spent']),
        ...sortedKeys.map((key) {
          final label = FuelCalculations.monthLabel(key);
          return _tableDataRow([
            label,
            '$currency ${_fmtMoney(data.monthlySpending[key]!)}',
          ]);
        }),
      ],
    );
  }

  static pw.Widget _refuelTable({
    required FuelReportData data,
    required String currency,
    required String fuelUnit,
    required String distance,
    required DateFormat dateTimeFmt,
    required DateFormat dateFmt,
  }) {
    final vehiclesById = {
      for (final v in data.vehicles)
        if (v.id != null) v.id!: v.name,
    };

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.6),
        1: const pw.FlexColumnWidth(1.4),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(0.8),
        4: const pw.FlexColumnWidth(0.9),
        5: const pw.FlexColumnWidth(0.9),
        6: const pw.FlexColumnWidth(1.2),
      },
      children: [
        _tableHeaderRow([
          'Date',
          'Vehicle',
          'Odometer',
          'Qty',
          'Price/L',
          'Total',
          'Station',
        ]),
        ...data.entries.map((e) {
          return _tableDataRow([
            dateTimeFmt.format(e.refuelDate),
            vehiclesById[e.vehicleId] ?? 'Vehicle',
            e.odometer.toStringAsFixed(0),
            '${_fmtQty(e.quantity)} $fuelUnit',
            e.pricePerLiter != null
                ? '$currency ${e.pricePerLiter!.toStringAsFixed(3)}'
                : '—',
            '$currency ${_fmtMoney(e.totalPrice)}',
            e.stationName?.isNotEmpty == true ? e.stationName! : '—',
          ]);
        }),
      ],
    );
  }

  static pw.TableRow _tableHeaderRow(List<String> cells) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
      children: cells
          .map(
            (c) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: pw.Text(
                c,
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  static pw.TableRow _tableDataRow(List<String> cells) {
    return pw.TableRow(
      children: cells
          .map(
            (c) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              child: pw.Text(c, style: const pw.TextStyle(fontSize: 8)),
            ),
          )
          .toList(),
    );
  }

  static String _fmtMoney(double value) => value.toStringAsFixed(2);

  static String _fmtQty(double value) => value.toStringAsFixed(2);
}
