import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'providers/backup_provider.dart';
import 'services/drive_backup_prefs.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final drivePrefs = await DriveBackupPrefs.open();
  runApp(
    ProviderScope(
      overrides: [
        driveBackupPrefsProvider.overrideWithValue(drivePrefs),
      ],
      child: const FuelTrackApp(),
    ),
  );
}
