import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/countries.dart';
import '../../data/currencies.dart';
import '../../models/app_settings.dart';
import '../../models/enums.dart';
import '../../providers/backup_provider.dart';
import '../../providers/data_refresh.dart';
import '../../providers/settings_provider.dart';
import '../../services/backup_service.dart';
import '../../features/donate/donate_screen.dart';
import '../../theme/app_spacing.dart';
import '../../theme/theme_x.dart';
import '../fuel_cards/fuel_card_list_screen.dart';
import '../vehicles/vehicle_list_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  static Future<void> open(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
    );
  }

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  var _busy = false;
  var _status = '';

  Future<String?> _promptPassphrase({
    required String title,
    bool confirm = false,
  }) async {
    final controller = TextEditingController();
    final confirmController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Passphrase',
                  hintText: 'At least 8 characters',
                ),
              ),
              if (confirm) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: confirmController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm passphrase',
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final pass = controller.text.trim();
                if (pass.length < 8) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Passphrase must be at least 8 characters'),
                    ),
                  );
                  return;
                }
                if (confirm && pass != confirmController.text.trim()) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Passphrases do not match')),
                  );
                  return;
                }
                Navigator.pop(context, pass);
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveSettings(AppSettings settings) async {
    await ref.read(settingsProvider.notifier).updateSettings(settings);
  }

  Future<void> _exportCsv() async {
    setState(() {
      _busy = true;
      _status = 'Exporting CSV…';
    });
    try {
      final outcome =
          await ref.read(backupServiceProvider).exportRefuelsCsv();
      if (!mounted) return;
      final message = switch (outcome.status) {
        BackupExportStatus.saved => 'CSV exported successfully',
        BackupExportStatus.cancelled => 'Export cancelled',
        BackupExportStatus.failed => outcome.message ?? 'Export failed',
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _status = '';
        });
      }
    }
  }

  Future<void> _localRestore() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore from file?'),
        content: const Text(
          'This replaces all vehicles, refuels, and settings on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final passphrase = await _promptPassphrase(title: 'Unlock backup');
    if (passphrase == null || !mounted) return;

    setState(() {
      _busy = true;
      _status = 'Restoring…';
    });
    try {
      final ok = await ref
          .read(backupServiceProvider)
          .importEncryptedBackupFromFile(passphrase);
      if (!mounted) return;
      if (ok) {
        invalidateAllDataProviders(ref);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup restored')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Restore failed — wrong passphrase or invalid file'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _status = '';
        });
      }
    }
  }

  Future<void> _toggleGoogleAccount() async {
    final drive = ref.read(driveBackupServiceProvider);
    setState(() => _busy = true);
    try {
      if (drive.currentUser != null) {
        await drive.signOut();
      } else {
        await drive.signIn();
      }
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google sign-in failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _driveBackup() async {
    final drive = ref.read(driveBackupServiceProvider);
    if (drive.currentUser == null) {
      await _toggleGoogleAccount();
      if (drive.currentUser == null) return;
    }

    final passphrase = await _promptPassphrase(
      title: 'Encrypt cloud backup',
      confirm: true,
    );
    if (passphrase == null || !mounted) return;

    setState(() {
      _busy = true;
      _status = 'Uploading to Google Drive…';
    });
    try {
      final backup = ref.read(backupServiceProvider);
      final prefs = ref.read(driveBackupPrefsProvider);
      final built = await backup.buildEncryptedBackupBytes(passphrase);
      if (!built.ok || built.bytes == null) {
        throw StateError(built.message ?? 'Backup build failed');
      }
      await drive.uploadEncryptedBackup(bytes: built.bytes!, prefs: prefs);
      await prefs.setDriveBackupEnabled(true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backed up to Google Drive')),
        );
      }
    } catch (e) {
      await ref.read(driveBackupPrefsProvider).setLastError(e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Drive backup failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _status = '';
        });
      }
    }
  }

  Future<void> _driveRestore() async {
    final drive = ref.read(driveBackupServiceProvider);
    if (drive.currentUser == null) {
      await _toggleGoogleAccount();
      if (!mounted || drive.currentUser == null) return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore from Google Drive?'),
        content: const Text(
          'This replaces all local fuel data with your cloud backup.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final passphrase = await _promptPassphrase(title: 'Unlock cloud backup');
    if (passphrase == null || !mounted) return;

    setState(() {
      _busy = true;
      _status = 'Downloading from Drive…';
    });
    try {
      final sealed = await drive.downloadCanonicalSealedUtf8();
      final ok = await ref.read(backupServiceProvider)
          .importEncryptedBackupFromSealedContents(sealed, passphrase);
      if (!mounted) return;
      if (ok) {
        invalidateAllDataProviders(ref);
        final prefs = ref.read(driveBackupPrefsProvider);
        await prefs.recordSuccessfulUpload(
          remoteModifiedMs: prefs.lastKnownRemoteModifiedMs,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Restored from Google Drive')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wrong passphrase or corrupt backup')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Drive restore failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _status = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);
    final drive = ref.watch(driveBackupServiceProvider);
    final prefs = ref.watch(driveBackupPrefsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (settings) {
          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.marginMobile,
                  AppSpacing.stackLg,
                  AppSpacing.marginMobile,
                  AppSpacing.stackLg,
                ),
                children: [
                  Text('Preferences', style: theme.textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.stackMd),
                  _SettingsCard(
                    children: [
                      ListTile(
                        title: const Text('Country'),
                        subtitle: Text(
                          () {
                            final c = Countries.findByCode(settings.countryCode);
                            return c != null ? '${c.flag}  ${c.name}' : settings.countryCode;
                          }(),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _pickCountry(settings),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        title: const Text('Currency'),
                        subtitle: Text(
                          '${settings.currencyCode} (${settings.currencySymbol})',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _pickCurrency(settings),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        title: const Text('Distance unit'),
                        subtitle: Text(settings.distanceUnit.label),
                        onTap: () => _pickDistanceUnit(settings),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        title: const Text('Fuel unit'),
                        subtitle: Text(settings.fuelUnit.label),
                        onTap: () => _pickFuelUnit(settings),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        title: const Text('Theme'),
                        subtitle: Text(settings.themeMode.label),
                        onTap: () => _pickTheme(settings),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.stackLg),
                  Text('Vehicles', style: theme.textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.stackMd),
                  _SettingsCard(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.directions_car_outlined),
                        title: const Text('Manage vehicles'),
                        subtitle: const Text('Add, edit, or remove vehicles'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const VehicleListScreen(),
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.credit_card_outlined),
                        title: const Text('Fuel cards'),
                        subtitle: const Text('Manage fleet and vehicle fuel cards'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => FuelCardListScreen.open(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.stackLg),
                  Text('Data & export', style: theme.textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.stackMd),
                  _SettingsCard(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.table_chart_outlined),
                        title: const Text('Export refuel history (CSV)'),
                        subtitle: const Text('Unencrypted spreadsheet export'),
                        onTap: _busy ? null : _exportCsv,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.restore_outlined),
                        title: const Text('Restore from file'),
                        subtitle: const Text('.ftbak encrypted backup'),
                        onTap: _busy ? null : _localRestore,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.stackLg),
                  Text('Support', style: theme.textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.stackMd),
                  _SettingsCard(
                    children: [
                      ListTile(
                        leading: Icon(
                          Icons.volunteer_activism_outlined,
                          color: theme.colorScheme.error,
                        ),
                        title: const Text('Donate'),
                        subtitle: const Text(
                          'UPI, PayPal, and crypto — support development',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => DonateScreen.open(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.stackLg),
                  Text('Google Drive', style: theme.textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.stackSm),
                  Text(
                    'Optional encrypted backup in your Google account app data folder (not visible in Drive).',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.stackMd),
                  _SettingsCard(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.account_circle_outlined),
                        title: Text(
                          drive.currentUser?.email ?? 'Not signed in',
                        ),
                        subtitle: Text(
                          prefs.driveBackupEnabled
                              ? 'Cloud backup enabled'
                              : 'Sign in to back up',
                        ),
                        trailing: TextButton(
                          onPressed: _busy ? null : _toggleGoogleAccount,
                          child: Text(
                            drive.currentUser != null ? 'Sign out' : 'Sign in',
                          ),
                        ),
                      ),
                      if (prefs.lastSuccessfulUploadMs > 0) ...[
                        const Divider(height: 1),
                        ListTile(
                          title: const Text('Last cloud backup'),
                          subtitle: Text(
                            DateFormat.yMMMd().add_jm().format(
                              DateTime.fromMillisecondsSinceEpoch(
                                prefs.lastSuccessfulUploadMs,
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (prefs.lastError != null) ...[
                        const Divider(height: 1),
                        ListTile(
                          title: const Text('Last error'),
                          subtitle: Text(
                            prefs.lastError!,
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ),
                      ],
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.cloud_upload_outlined),
                        title: const Text('Back up now'),
                        onTap: _busy ? null : _driveBackup,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.cloud_download_outlined),
                        title: const Text('Restore from Drive'),
                        onTap: _busy ? null : _driveRestore,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.stackLg),
                  Text(
                    'FuelTrack Pro v1.14.0',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              if (_busy)
                ColoredBox(
                  color: Colors.black26,
                  child: Center(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.stackLg),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: AppSpacing.stackMd),
                            Text(_status),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _pickCountry(AppSettings settings) async {
    final search = TextEditingController();
    final picked = await showModalBottomSheet<CountryOption>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _SearchPickerSheet<CountryOption>(
        title: 'Country',
        items: Countries.all,
        searchController: search,
        labelFor: (c) => c.displayName,
        searchMatch: (c, q) =>
            c.name.toLowerCase().contains(q) || c.code.toLowerCase().contains(q),
        isSelected: (c) => c.code == settings.countryCode,
      ),
    );
    search.dispose();
    if (picked == null) return;
    await _saveSettings(settings.copyWith(countryCode: picked.code));
  }

  Future<void> _pickCurrency(AppSettings settings) async {
    final search = TextEditingController();
    final picked = await showModalBottomSheet<CurrencyOption>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _SearchPickerSheet<CurrencyOption>(
        title: 'Currency',
        items: Currencies.all,
        searchController: search,
        labelFor: (c) => c.displayLabel,
        searchMatch: (c, q) =>
            c.name.toLowerCase().contains(q) ||
            c.code.toLowerCase().contains(q) ||
            c.symbol.toLowerCase().contains(q),
        isSelected: (c) => c.code == settings.currencyCode,
      ),
    );
    search.dispose();
    if (picked == null) return;
    await _saveSettings(
      settings.copyWith(
        currencyCode: picked.code,
        currencySymbol: picked.symbol,
      ),
    );
  }

  Future<void> _pickDistanceUnit(AppSettings settings) async {
    await _pickEnum(
      title: 'Distance unit',
      values: DistanceUnit.values,
      label: (v) => v.label,
      current: settings.distanceUnit,
      onPick: (v) => _saveSettings(settings.copyWith(distanceUnit: v)),
    );
  }

  Future<void> _pickFuelUnit(AppSettings settings) async {
    await _pickEnum(
      title: 'Fuel unit',
      values: FuelUnit.values,
      label: (v) => v.label,
      current: settings.fuelUnit,
      onPick: (v) => _saveSettings(settings.copyWith(fuelUnit: v)),
    );
  }

  Future<void> _pickTheme(AppSettings settings) async {
    await _pickEnum(
      title: 'Theme',
      values: ThemeModePreference.values,
      label: (v) => v.label,
      current: settings.themeMode,
      onPick: (v) => _saveSettings(settings.copyWith(themeMode: v)),
    );
  }

  Future<void> _pickEnum<T>({
    required String title,
    required List<T> values,
    required String Function(T) label,
    required T current,
    required Future<void> Function(T) onPick,
  }) async {
    final picked = await showModalBottomSheet<T>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.gutter),
              child: Text(title, style: Theme.of(context).textTheme.titleMedium),
            ),
            ...values.map(
              (value) => ListTile(
                title: Text(label(value)),
                trailing: value == current ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(context, value),
              ),
            ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    await onPick(picked);
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _SearchPickerSheet<T> extends StatefulWidget {
  const _SearchPickerSheet({
    required this.title,
    required this.items,
    required this.searchController,
    required this.labelFor,
    required this.searchMatch,
    required this.isSelected,
  });

  final String title;
  final List<T> items;
  final TextEditingController searchController;
  final String Function(T) labelFor;
  final bool Function(T, String) searchMatch;
  final bool Function(T) isSelected;

  @override
  State<_SearchPickerSheet<T>> createState() => _SearchPickerSheetState<T>();
}

class _SearchPickerSheetState<T> extends State<_SearchPickerSheet<T>> {
  List<T> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.items;
    widget.searchController.addListener(_onSearch);
  }

  void _onSearch() {
    final q = widget.searchController.text.toLowerCase().trim();
    setState(() {
      _filtered = q.isEmpty
          ? widget.items
          : widget.items.where((i) => widget.searchMatch(i, q)).toList();
    });
  }

  @override
  void dispose() {
    widget.searchController.removeListener(_onSearch);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final tt = context.tt;
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: cs.outlineVariant,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
          child: Text(
            widget.title,
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
          child: TextField(
            controller: widget.searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search…',
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: cs.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: _filtered.length,
            itemBuilder: (_, i) {
              final item = _filtered[i];
              final selected = widget.isSelected(item);
              return ListTile(
                dense: true,
                title: Text(
                  widget.labelFor(item),
                  style: tt.bodyMedium?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : null,
                  ),
                ),
                trailing: selected
                    ? Icon(Icons.check, color: cs.primary, size: 18)
                    : null,
                onTap: () => Navigator.of(context).pop(item),
              );
            },
          ),
        ),
      ],
    );
  }
}
