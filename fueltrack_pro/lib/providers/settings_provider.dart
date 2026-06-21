import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_settings.dart';
import 'database_provider.dart';

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    await ref.watch(databaseInitProvider.future);
    return ref.read(databaseServiceProvider).getSettings();
  }

  Future<void> updateSettings(AppSettings settings) async {
    final updated = settings.copyWith(updatedAt: DateTime.now());
    await ref.read(databaseServiceProvider).saveSettings(updated);
    state = AsyncData(updated);
  }
}
