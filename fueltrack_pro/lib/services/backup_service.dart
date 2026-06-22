import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

import 'backup_crypto.dart';
import 'database_service.dart';

const int kBackupSchemaVersion = 1;

typedef BackupProgressCallback = void Function(String message);

enum BackupExportStatus { saved, cancelled, failed }

class BackupExportOutcome {
  const BackupExportOutcome(this.status, [this.message]);

  final BackupExportStatus status;
  final String? message;
}

class BackupBytesOutcome {
  const BackupBytesOutcome._(this.ok, this.bytes, this.message);

  const BackupBytesOutcome.success(Uint8List bytes)
      : this._(true, bytes, null);

  const BackupBytesOutcome.failure(String message)
      : this._(false, null, message);

  final bool ok;
  final Uint8List? bytes;
  final String? message;
}

class BackupService {
  BackupService(this._db);

  final DatabaseService _db;

  static Uint8List _utf8Bytes(String s) => Uint8List.fromList(utf8.encode(s));

  static String encryptedBackupSuggestedFileName([DateTime? when]) {
    final n = when ?? DateTime.now();
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(n);
    return 'fueltrack_pro_backup_$stamp.ftbak';
  }

  static String refuelCsvSuggestedFileName([DateTime? when]) {
    final n = when ?? DateTime.now();
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(n);
    return 'fueltrack_pro_refuels_$stamp.csv';
  }

  Future<Map<String, dynamic>> buildBackupPayload() async {
    final db = await _db.database;
    return {
      'dbSchemaVersion': kBackupSchemaVersion,
      'app': 'fueltrack_pro',
      'exportedAt': DateTime.now().toIso8601String(),
      'vehicles': await db.query('vehicles'),
      'refuel_entries': await db.query('refuel_entries'),
      'settings': await db.query('settings'),
    };
  }

  Future<BackupBytesOutcome> buildEncryptedBackupBytes(
    String passphrase, {
    BackupProgressCallback? onProgress,
  }) async {
    try {
      onProgress?.call('Gathering data…');
      final jsonData = jsonEncode(await buildBackupPayload());
      onProgress?.call('Encrypting…');
      final sealed = await BackupCrypto.sealUtf8Payload(jsonData, passphrase);
      return BackupBytesOutcome.success(_utf8Bytes(sealed));
    } catch (e) {
      return BackupBytesOutcome.failure(e.toString());
    }
  }

  Future<BackupExportOutcome> exportEncryptedBackup(String passphrase) async {
    try {
      final built = await buildEncryptedBackupBytes(passphrase);
      if (!built.ok || built.bytes == null) {
        return BackupExportOutcome(
          BackupExportStatus.failed,
          built.message ?? 'Backup failed',
        );
      }

      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save FuelTrack Pro backup',
        fileName: encryptedBackupSuggestedFileName(),
        type: FileType.custom,
        allowedExtensions: const ['ftbak'],
        bytes: built.bytes,
      );

      if (outputPath == null) {
        return const BackupExportOutcome(BackupExportStatus.cancelled);
      }
      return const BackupExportOutcome(BackupExportStatus.saved);
    } catch (e) {
      return BackupExportOutcome(BackupExportStatus.failed, e.toString());
    }
  }

  Future<BackupExportOutcome> exportRefuelsCsv() async {
    try {
      final db = await _db.database;
      final vehicles = await db.query('vehicles');
      final vehicleNames = {
        for (final row in vehicles)
          row['id'] as int: row['name'] as String? ?? 'Vehicle',
      };
      final refuels = await db.query('refuel_entries', orderBy: 'refuel_date ASC');
      final dateFmt = DateFormat('yyyy-MM-dd HH:mm');

      final csv = StringBuffer()
        ..writeln(
          'date,vehicle,odometer,quantity,price_per_liter,total_price,fuel_type,station,notes',
        );

      for (final row in refuels) {
        final date = DateTime.fromMillisecondsSinceEpoch(row['refuel_date'] as int);
        final vehicle = vehicleNames[row['vehicle_id'] as int] ?? 'Vehicle';
        csv.writeln([
          dateFmt.format(date),
          _csvEscape(vehicle),
          row['odometer'],
          row['quantity'],
          row['price_per_liter'],
          row['total_price'],
          row['fuel_type'],
          _csvEscape(row['station_name']?.toString() ?? ''),
          _csvEscape(row['notes']?.toString() ?? ''),
        ].join(','));
      }

      final bytes = _utf8Bytes(csv.toString());
      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Export refuel history CSV',
        fileName: refuelCsvSuggestedFileName(),
        type: FileType.custom,
        allowedExtensions: const ['csv'],
        bytes: bytes,
      );

      if (outputPath == null) {
        return const BackupExportOutcome(BackupExportStatus.cancelled);
      }
      return const BackupExportOutcome(BackupExportStatus.saved);
    } catch (e) {
      return BackupExportOutcome(BackupExportStatus.failed, e.toString());
    }
  }

  Future<bool> importEncryptedBackupFromFile(String passphrase) async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select FuelTrack Pro backup',
      type: FileType.custom,
      allowedExtensions: const ['ftbak'],
    );
    if (result == null || result.files.isEmpty) {
      return false;
    }

    final file = result.files.single;
    final String contents;
    if (file.bytes != null) {
      contents = utf8.decode(file.bytes!);
    } else if (file.path != null) {
      contents = await File(file.path!).readAsString();
    } else {
      return false;
    }
    return importEncryptedBackupFromSealedContents(contents, passphrase);
  }

  Future<bool> importEncryptedBackupFromSealedContents(
    String sealedUtf8Contents,
    String passphrase, {
    BackupProgressCallback? onProgress,
  }) async {
    try {
      onProgress?.call('Unlocking backup…');
      final jsonText = await BackupCrypto.openUtf8Payload(
        sealedUtf8Contents,
        passphrase,
      );
      final data = jsonDecode(jsonText) as Map<String, dynamic>;
      _ensurePayloadImportable(data);
      onProgress?.call('Restoring data…');
      await _restoreData(data);
      onProgress?.call('Done');
      return true;
    } catch (_) {
      return false;
    }
  }

  void _ensurePayloadImportable(Map<String, dynamic> data) {
    final app = data['app'] as String?;
    if (app != null && app != 'fueltrack_pro') {
      throw const FormatException('Not a FuelTrack Pro backup');
    }
    final version = (data['dbSchemaVersion'] as num?)?.toInt() ?? 1;
    if (version > kBackupSchemaVersion) {
      throw FormatException(
        'Backup needs a newer app (schema $version > $kBackupSchemaVersion).',
      );
    }
  }

  Future<void> _restoreData(Map<String, dynamic> data) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.delete('refuel_entries');
      await txn.delete('vehicles');

      final vehicles = data['vehicles'] as List? ?? [];
      for (final row in vehicles) {
        await txn.insert(
          'vehicles',
          Map<String, dynamic>.from(row as Map),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      final refuels = data['refuel_entries'] as List? ?? [];
      for (final row in refuels) {
        await txn.insert(
          'refuel_entries',
          Map<String, dynamic>.from(row as Map),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      final settings = data['settings'] as List? ?? [];
      if (settings.isNotEmpty) {
        await txn.insert(
          'settings',
          Map<String, dynamic>.from(settings.first as Map),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  static String _csvEscape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
