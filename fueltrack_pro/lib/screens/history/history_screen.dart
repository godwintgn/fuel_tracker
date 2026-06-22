import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/history_filters.dart';
import '../../models/refuel_entry.dart';
import '../../models/vehicle.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/refuels_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/vehicles_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/history/history_filters_sheet.dart';
import '../../widgets/history/refuel_history_card.dart';
import '../refuel/add_refuel_screen.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _searchController = TextEditingController();
  var _filters = HistoryFilters.defaults;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Map<int, Vehicle> _vehiclesById(List<Vehicle> vehicles) {
    return {for (final v in vehicles) if (v.id != null) v.id!: v};
  }

  Future<void> _openFilters(List<Vehicle> vehicles) async {
    final result = await HistoryFiltersSheet.show(
      context,
      initialFilters: _filters,
      vehicles: vehicles,
    );
    if (result != null) {
      setState(() => _filters = result);
    }
  }

  Future<void> _editEntry(RefuelEntry entry) async {
    await AddRefuelScreen.openForEdit(context, entry: entry);
  }

  Future<bool> _confirmDelete(RefuelEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete refuel?'),
        content: const Text(
          'This entry will be removed from your history and dashboard stats.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _deleteEntry(RefuelEntry entry) async {
    if (entry.id == null) return;
    await ref.read(refuelsProvider.notifier).deleteEntry(entry.id!);
    ref.invalidate(dashboardProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Refuel entry deleted')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final refuelsAsync = ref.watch(refuelsProvider);
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final settings = ref.watch(settingsProvider).valueOrNull;
    final currency = settings?.currencyCode ?? 'OMR';
    final fuelUnit = settings?.fuelUnit.abbreviation ?? 'L';
    final distanceUnit = settings?.distanceUnit.abbreviation ?? 'km';

    return vehiclesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (vehicles) {
        return refuelsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (allEntries) {
            final vehiclesById = _vehiclesById(vehicles);
            final activeFilters = _filters.copyWith(
              searchQuery: _searchController.text,
            );
            final entries = RefuelHistoryFilter.apply(
              entries: allEntries,
              filters: activeFilters,
              vehiclesById: vehiclesById,
            );
            final summary = RefuelHistoryFilter.summarize(
              entries: entries,
              filters: activeFilters,
            );

            if (allEntries.isEmpty) {
              return EmptyState(
                icon: Icons.history,
                title: 'No refuel history yet',
                message:
                    'Log your first fill-up to see spending, stations, and odometer readings here.',
                actionLabel: 'Log Refuel',
                onAction: () => AddRefuelScreen.open(context),
              );
            }

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.marginMobile,
                      AppSpacing.stackLg,
                      AppSpacing.marginMobile,
                      AppSpacing.stackMd,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FuelTrack Pro',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.stackMd),
                        Material(
                          color: AppColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(999),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.search,
                                  color: AppColors.onSurfaceVariant,
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    decoration: const InputDecoration(
                                      hintText: 'Search stations or types...',
                                      border: InputBorder.none,
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _openFilters(vehicles),
                                  icon: Badge(
                                    isLabelVisible: _filters.hasActiveFilters,
                                    child: const Icon(Icons.tune),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.marginMobile,
                      0,
                      AppSpacing.marginMobile,
                      AppSpacing.stackMd,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Refuel History',
                                style: theme.textTheme.titleLarge,
                              ),
                              Text(
                                '${summary.periodLabel} • ${summary.entryCount} entries',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryFixed,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Total: ${summary.totalSpent.toStringAsFixed(3)} $currency',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: AppColors.onPrimaryFixed,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (entries.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.filter_alt_off_outlined,
                      title: 'No matching entries',
                      message:
                          'Try clearing search or filters to see more refuels.',
                      actionLabel: 'Reset Filters',
                      onAction: () {
                        setState(() {
                          _filters = HistoryFilters.defaults;
                          _searchController.clear();
                        });
                      },
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.marginMobile,
                      0,
                      AppSpacing.marginMobile,
                      120,
                    ),
                    sliver: SliverList.separated(
                      itemCount: entries.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: AppSpacing.gutter),
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        final vehicle = vehiclesById[entry.vehicleId];

                        return Dismissible(
                          key: ValueKey('refuel-${entry.id}'),
                          direction: DismissDirection.horizontal,
                          background: Container(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 24),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryContainer,
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusXl),
                            ),
                            child: const Icon(
                              Icons.edit_outlined,
                              color: AppColors.onSecondaryContainer,
                            ),
                          ),
                          secondaryBackground: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            decoration: BoxDecoration(
                              color: AppColors.errorContainer,
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusXl),
                            ),
                            child: const Icon(
                              Icons.delete_outline,
                              color: AppColors.error,
                            ),
                          ),
                          confirmDismiss: (direction) async {
                            if (direction == DismissDirection.startToEnd) {
                              await _editEntry(entry);
                              return false;
                            }
                            return _confirmDelete(entry);
                          },
                          onDismissed: (_) => _deleteEntry(entry),
                          child: RefuelHistoryCard(
                            entry: entry,
                            vehicle: vehicle,
                            currency: currency,
                            fuelUnit: fuelUnit,
                            distanceUnit: distanceUnit,
                            alternateAccent: index.isOdd,
                            onTap: () => _editEntry(entry),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
