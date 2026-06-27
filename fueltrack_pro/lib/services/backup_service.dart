import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

import 'database_service.dart';

const int kBackupSchemaVersion = 2;

typedef BackupProgressCallback = void Function(String message);

enum BackupExportStatus { saved, cancelled, failed }

enum BackupImportStatus { restored, cancelled, failed }

class BackupImportOutcome {
  const BackupImportOutcome(this.status, [this.message]);

  final BackupImportStatus status;
  final String? message;
}

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

  static String backupSuggestedFileName([DateTime? when]) {
    final n = when ?? DateTime.now();
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(n);
    return 'fueltrack_pro_backup_$stamp.json';
  }

  Future<Map<String, dynamic>> buildBackupPayload() async {
    final db = await _db.database;
    return {
      'dbSchemaVersion': kBackupSchemaVersion,
      'app': 'fueltrack_pro',
      'exportedAt': DateTime.now().toIso8601String(),
      'vehicles': await db.query('vehicles'),
      'refuel_entries': await db.query('refuel_entries'),
      'fuel_cards': await db.query('fuel_cards'),
      'service_records': await db.query('service_records'),
      'settings': await db.query('settings'),
    };
  }

  Future<BackupBytesOutcome> buildPlainBackupBytes({
    BackupProgressCallback? onProgress,
  }) async {
    try {
      onProgress?.call('Gathering data…');
      final jsonData = jsonEncode(await buildBackupPayload());
      return BackupBytesOutcome.success(_utf8Bytes(jsonData));
    } catch (e) {
      return BackupBytesOutcome.failure(e.toString());
    }
  }

  Future<bool> importPlainBackupFromJsonString(
    String jsonText, {
    BackupProgressCallback? onProgress,
  }) async {
    try {
      onProgress?.call('Reading backup…');
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

  Future<BackupExportOutcome> exportPlainBackupToFile() async {
    try {
      final built = await buildPlainBackupBytes();
      if (!built.ok || built.bytes == null) {
        return BackupExportOutcome(
          BackupExportStatus.failed,
          built.message ?? 'Backup failed',
        );
      }

      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save local backup',
        fileName: backupSuggestedFileName(),
        type: FileType.custom,
        allowedExtensions: const ['json'],
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

  Future<BackupImportOutcome> importPlainBackupFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        return const BackupImportOutcome(BackupImportStatus.cancelled);
      }

      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null) {
        return const BackupImportOutcome(
          BackupImportStatus.failed,
          'Could not read file',
        );
      }

      final jsonText = utf8.decode(bytes);
      final ok = await importPlainBackupFromJsonString(jsonText);
      if (!ok) {
        return const BackupImportOutcome(
          BackupImportStatus.failed,
          'Invalid or corrupt backup file',
        );
      }
      return const BackupImportOutcome(BackupImportStatus.restored);
    } catch (e) {
      return BackupImportOutcome(BackupImportStatus.failed, e.toString());
    }
  }

  Future<void> _restoreData(Map<String, dynamic> data) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.delete('refuel_entries');
      await txn.delete('service_records');
      await txn.delete('fuel_cards');
      await txn.delete('vehicles');

      for (final row in data['vehicles'] as List? ?? []) {
        await txn.insert(
          'vehicles',
          Map<String, dynamic>.from(row as Map),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      for (final row in data['fuel_cards'] as List? ?? []) {
        await txn.insert(
          'fuel_cards',
          Map<String, dynamic>.from(row as Map),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      for (final row in data['refuel_entries'] as List? ?? []) {
        await txn.insert(
          'refuel_entries',
          Map<String, dynamic>.from(row as Map),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      for (final row in data['service_records'] as List? ?? []) {
        await txn.insert(
          'service_records',
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
}
