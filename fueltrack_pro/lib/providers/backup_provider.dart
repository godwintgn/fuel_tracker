import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/backup_service.dart';
import '../services/database_service.dart';
import '../services/drive_backup_prefs.dart';
import '../services/drive_backup_service.dart';

final driveBackupPrefsProvider = Provider<DriveBackupPrefs>(
  (ref) => throw StateError('driveBackupPrefsProvider not initialized'),
);

final driveBackupServiceProvider = Provider<DriveBackupService>(
  (ref) => DriveBackupService(),
);

final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(DatabaseService.instance),
);
