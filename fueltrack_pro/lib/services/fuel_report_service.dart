import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/app_settings.dart';
import '../models/refuel_entry.dart';
import '../models/report_filters.dart';
import '../models/vehicle.dart';
import 'analytics_service.dart';
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
    this.totalDistanceKm,
    this.avgPricePerLiter,
    required this.stationStats,
    this.bestFill,
    this.worstFill,
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
  final double? totalDistanceKm;
  final double? avgPricePerLiter;
  final List<StationStat> stationStats;
  final RefuelEntry? bestFill;
  final RefuelEntry? worstFill;
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

    final trips = FuelCalculations.tripEfficiencies(entries);
    final totalDistanceKm = trips.isEmpty
        ? null
        : trips.fold<double>(0, (s, t) => s + t.distanceKm);

    final totalLiters = entries.fold<double>(0, (s, e) => s + e.quantity);
    final totalSpent = entries.fold<double>(0, (s, e) => s + e.totalPrice);
    final avgPricePerLiter =
        totalLiters > 0 ? totalSpent / totalLiters : null;

    return FuelReportData(
      filters: filters,
      rangeStart: range.start,
      rangeEnd: range.end,
      entries: entries,
      vehicles: selectedVehicles,
      fillCount: entries.length,
      totalSpent: totalSpent,
      totalLiters: totalLiters,
      avgKmPerLiter: avg,
      costPerKm: costPerKm,
      byVehicle: byVehicle,
      monthlySpending: monthlySpending,
      totalDistanceKm: totalDistanceKm,
      avgPricePerLiter: avgPricePerLiter,
      stationStats: AnalyticsService.stationStatsForEntries(entries),
      bestFill: AnalyticsService.cheapestFill(entries),
      worstFill: AnalyticsService.costliestFill(entries),
    );
  }

  static String generateReportId([DateTime? when]) {
    final n = when ?? DateTime.now();
    final stamp = DateFormat('yyyyMMdd-HHmmss').format(n);
    final ms = n.millisecond.toString().padLeft(3, '0');
    return 'RPT-$stamp-$ms';
  }

  static String suggestedFileName(
    FuelReportData data, {
    DateTime? when,
    String? reportId,
  }) {
    final n = when ?? DateTime.now();
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(n);
    final ms = n.millisecond.toString().padLeft(3, '0');
    final period = data.filters.period == ReportPeriod.custom
        ? 'custom'
        : data.filters.period.name;
    final idSuffix = (reportId ?? generateReportId(n))
        .replaceAll('RPT-', '')
        .replaceAll('-', '');
    return 'fueltrack_pro_report_${period}_${stamp}_${ms}_$idSuffix.pdf';
  }

  static String _registration(Vehicle vehicle) {
    final plate = vehicle.licensePlate?.trim();
    if (plate == null || plate.isEmpty) return '—';
    return plate;
  }

  static String _vehicleLine(Vehicle vehicle) {
    final plate = vehicle.licensePlate?.trim();
    if (plate == null || plate.isEmpty) return vehicle.name;
    return '${vehicle.name} ($plate)';
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
    if (data.vehicles.length == 1) return _vehicleLine(data.vehicles.first);
    return data.vehicles.map(_vehicleLine).join('; ');
  }

  static Future<Uint8List> buildPdfBytes({
    required FuelReportData data,
    required AppSettings settings,
    String? reportId,
  }) async {
    final id = reportId ?? generateReportId();
    final currency = settings.currencySymbol;
    final distance = settings.distanceUnit.abbreviation;
    final fuelUnit = settings.fuelUnit.abbreviation;
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
                      'Fleet fuel expense report',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: muted,
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
                'Generated $generatedAt · $id',
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
            _infoRow('Report ID', id),
            _infoRow('Period', periodLabel(data)),
            _infoRow('Vehicles', vehiclesLabel(data)),
            _infoRow('Currency', settings.currencyCode),
            if (data.vehicles.isNotEmpty) ...[
              pw.SizedBox(height: 16),
              pw.Text(
                'Vehicles in report',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: green,
                ),
              ),
              pw.SizedBox(height: 8),
              _vehiclesRosterTable(data),
            ],
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
                if (data.avgPricePerLiter != null)
                  _statBox(
                    'Avg price/$fuelUnit',
                    '$currency ${data.avgPricePerLiter!.toStringAsFixed(3)}',
                  ),
                if (data.totalDistanceKm != null)
                  _statBox(
                    'Distance',
                    '${data.totalDistanceKm!.toStringAsFixed(0)} $distance',
                  ),
              ],
            ),
          ];

          if (data.byVehicle.isNotEmpty) {
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
              _monthlySpendChart(data, currency, green),
              pw.SizedBox(height: 10),
              _monthlyTable(data, currency),
            ]);
          }

          if (data.bestFill != null || data.worstFill != null) {
            blocks.addAll([
              pw.SizedBox(height: 24),
              pw.Text(
                'Best & worst fill',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: green,
                ),
              ),
              pw.SizedBox(height: 8),
              _fillHighlights(data, currency, fuelUnit, dateTimeFmt),
            ]);
          }

          if (data.stationStats.isNotEmpty) {
            blocks.addAll([
              pw.SizedBox(height: 24),
              pw.Text(
                'Station comparison',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: green,
                ),
              ),
              pw.SizedBox(height: 8),
              _stationTable(data, currency, fuelUnit),
            ]);
          }

          if (data.entries.isEmpty) {
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

    if (data.entries.isNotEmpty) {
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          header: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Refuel history · $id',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: green,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                periodLabel(data),
                style: pw.TextStyle(fontSize: 9, color: muted),
              ),
              pw.SizedBox(height: 8),
              pw.Divider(color: PdfColors.grey300, thickness: 0.5),
              pw.SizedBox(height: 8),
            ],
          ),
          footer: (context) => pw.Padding(
            padding: const pw.EdgeInsets.only(top: 6),
            child: pw.Text(
              'FuelTrack Pro · $id · Page ${context.pageNumber}',
              style: pw.TextStyle(fontSize: 8, color: muted),
            ),
          ),
          build: (context) => [
            _refuelTable(
              data: data,
              currency: currency,
              fuelUnit: fuelUnit,
              dateTimeFmt: dateTimeFmt,
            ),
          ],
        ),
      );
    }

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

  static pw.Widget _vehiclesRosterTable(FuelReportData data) {
    final fillsByVehicleId = {
      for (final row in data.byVehicle)
        if (row.vehicle.id != null) row.vehicle.id!: row.fillCount,
    };

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1.4),
        2: const pw.FlexColumnWidth(1.2),
        3: const pw.FlexColumnWidth(0.8),
      },
      children: [
        _tableHeaderRow([
          'Vehicle',
          'Registration',
          'Fuel type',
          'Fills',
        ]),
        ...data.vehicles.map((vehicle) {
          final fills = vehicle.id != null ? fillsByVehicleId[vehicle.id!] ?? 0 : 0;
          return _tableDataRow([
            vehicle.name,
            _registration(vehicle),
            vehicle.fuelType.label,
            '$fills',
          ]);
        }),
      ],
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
        0: const pw.FlexColumnWidth(1.6),
        1: const pw.FlexColumnWidth(1.2),
        2: const pw.FlexColumnWidth(0.8),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(1.2),
        5: const pw.FlexColumnWidth(1.2),
      },
      children: [
        _tableHeaderRow([
          'Vehicle',
          'Registration',
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
            _registration(row.vehicle),
            '${row.fillCount}',
            '$currency ${_fmtMoney(row.totalSpent)}',
            '${_fmtQty(row.totalLiters)} $fuelUnit',
            eff,
          ]);
        }),
      ],
    );
  }

  static pw.Widget _monthlySpendChart(
    FuelReportData data,
    String currency,
    PdfColor accent,
  ) {
    final keys = data.monthlySpending.keys.toList()..sort();
    if (keys.isEmpty) return pw.SizedBox();

    final maxSpend = data.monthlySpending.values.reduce(
      (a, b) => a > b ? a : b,
    );
    const chartHeight = 88.0;

    return pw.Container(
      height: chartHeight + 28,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: keys.map((key) {
          final amount = data.monthlySpending[key]!;
          final barHeight =
              maxSpend > 0 ? (amount / maxSpend) * chartHeight : 0.0;
          final label = FuelCalculations.monthLabel(key);
          return pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 3),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    '$currency ${_fmtMoney(amount)}',
                    style: const pw.TextStyle(fontSize: 6),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 3),
                  pw.Container(
                    height: barHeight,
                    decoration: pw.BoxDecoration(
                      color: accent,
                      borderRadius: const pw.BorderRadius.vertical(
                        top: pw.Radius.circular(2),
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    label,
                    style: const pw.TextStyle(fontSize: 7),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  static pw.Widget _fillHighlights(
    FuelReportData data,
    String currency,
    String fuelUnit,
    DateFormat dateTimeFmt,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (data.bestFill != null)
          pw.Expanded(
            child: _fillHighlightCard(
              title: 'Cheapest fill',
              entry: data.bestFill!,
              currency: currency,
              fuelUnit: fuelUnit,
              dateTimeFmt: dateTimeFmt,
              accent: PdfColor.fromHex('#0D631B'),
            ),
          ),
        if (data.bestFill != null && data.worstFill != null)
          pw.SizedBox(width: 12),
        if (data.worstFill != null)
          pw.Expanded(
            child: _fillHighlightCard(
              title: 'Most expensive fill',
              entry: data.worstFill!,
              currency: currency,
              fuelUnit: fuelUnit,
              dateTimeFmt: dateTimeFmt,
              accent: PdfColors.red700,
            ),
          ),
      ],
    );
  }

  static pw.Widget _fillHighlightCard({
    required String title,
    required RefuelEntry entry,
    required String currency,
    required String fuelUnit,
    required DateFormat dateTimeFmt,
    required PdfColor accent,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: accent,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(dateTimeFmt.format(entry.refuelDate),
              style: const pw.TextStyle(fontSize: 8)),
          if (entry.stationName?.isNotEmpty == true)
            pw.Text(entry.stationName!,
                style: const pw.TextStyle(fontSize: 8)),
          pw.SizedBox(height: 4),
          pw.Text(
            entry.pricePerLiter != null
                ? '$currency ${entry.pricePerLiter!.toStringAsFixed(3)}/$fuelUnit'
                : '—',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            'Total $currency ${_fmtMoney(entry.totalPrice)}',
            style: const pw.TextStyle(fontSize: 8),
          ),
        ],
      ),
    );
  }

  static pw.Widget _stationTable(
    FuelReportData data,
    String currency,
    String fuelUnit,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(0.8),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1.2),
      },
      children: [
        _tableHeaderRow(['Station', 'Visits', 'Spent', 'Avg price/$fuelUnit']),
        ...data.stationStats.map((s) {
          return _tableDataRow([
            s.name,
            '${s.visitCount}',
            '$currency ${_fmtMoney(s.totalSpent)}',
            s.avgPricePerLiter != null
                ? '$currency ${s.avgPricePerLiter!.toStringAsFixed(3)}'
                : '—',
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
    required DateFormat dateTimeFmt,
  }) {
    final vehiclesById = {
      for (final v in data.vehicles)
        if (v.id != null) v.id!: v,
    };

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.4),
        1: const pw.FlexColumnWidth(1.1),
        2: const pw.FlexColumnWidth(0.9),
        3: const pw.FlexColumnWidth(0.8),
        4: const pw.FlexColumnWidth(0.7),
        5: const pw.FlexColumnWidth(0.7),
        6: const pw.FlexColumnWidth(0.8),
        7: const pw.FlexColumnWidth(0.8),
        8: const pw.FlexColumnWidth(1),
        9: const pw.FlexColumnWidth(1.2),
      },
      children: [
        _tableHeaderRow([
          'Date',
          'Vehicle',
          'Reg.',
          'Odometer',
          'Qty',
          'Fuel',
          'Price/L',
          'Total',
          'Station',
          'Notes',
        ]),
        ...data.entries.map((e) {
          final vehicle = vehiclesById[e.vehicleId];
          return _tableDataRow([
            dateTimeFmt.format(e.refuelDate),
            vehicle?.name ?? 'Vehicle',
            vehicle != null ? _registration(vehicle) : '—',
            e.odometer.toStringAsFixed(0),
            '${_fmtQty(e.quantity)} $fuelUnit',
            e.fuelType.label,
            e.pricePerLiter != null
                ? '$currency ${e.pricePerLiter!.toStringAsFixed(3)}'
                : '—',
            '$currency ${_fmtMoney(e.totalPrice)}',
            e.stationName?.isNotEmpty == true ? e.stationName! : '—',
            _truncateNote(e.notes),
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

  static String _truncateNote(String? note, {int maxLen = 48}) {
    final text = note?.trim();
    if (text == null || text.isEmpty) return '—';
    if (text.length <= maxLen) return text;
    return '${text.substring(0, maxLen - 1)}…';
  }
}
