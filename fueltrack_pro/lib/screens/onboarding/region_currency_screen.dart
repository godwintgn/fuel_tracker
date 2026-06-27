import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/countries.dart';
import '../../data/currencies.dart';
import '../../providers/onboarding_provider.dart';
import '../../theme/app_spacing.dart';
import '../../theme/theme_x.dart';
import '../../widgets/onboarding/onboarding_widgets.dart';

class OnboardingRegionCurrencyScreen extends ConsumerStatefulWidget {
  const OnboardingRegionCurrencyScreen({
    super.key,
    required this.onNext,
    required this.onSkip,
  });

  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  ConsumerState<OnboardingRegionCurrencyScreen> createState() =>
      _OnboardingRegionCurrencyScreenState();
}

class _OnboardingRegionCurrencyScreenState
    extends ConsumerState<OnboardingRegionCurrencyScreen> {
  final _countrySearch = TextEditingController();
  final _currencySearch = TextEditingController();

  @override
  void dispose() {
    _countrySearch.dispose();
    _currencySearch.dispose();
    super.dispose();
  }

  Future<void> _pickCountry(String currentCode) async {
    final picked = await _showSearchPicker<CountryOption>(
      context: context,
      title: 'Select Country',
      items: Countries.all,
      searchController: _countrySearch,
      labelFor: (c) => c.displayName,
      searchMatch: (c, q) =>
          c.name.toLowerCase().contains(q) || c.code.toLowerCase().contains(q),
      isSelected: (c) => c.code == currentCode,
    );
    if (picked == null) return;
    final suggestedCurrency = Countries.defaultCurrencyFor(picked.code);
    final currency = Currencies.findByCode(suggestedCurrency);
    ref.read(onboardingDraftProvider.notifier).patch(
          countryCode: picked.code,
          currencyCode: currency?.code ?? suggestedCurrency,
          currencySymbol: currency?.symbol ?? suggestedCurrency,
        );
  }

  Future<void> _pickCurrency(String currentCode) async {
    final picked = await _showSearchPicker<CurrencyOption>(
      context: context,
      title: 'Select Currency',
      items: Currencies.all,
      searchController: _currencySearch,
      labelFor: (c) => c.displayLabel,
      searchMatch: (c, q) =>
          c.name.toLowerCase().contains(q) ||
          c.code.toLowerCase().contains(q) ||
          c.symbol.toLowerCase().contains(q),
      isSelected: (c) => c.code == currentCode,
    );
    if (picked == null) return;
    ref.read(onboardingDraftProvider.notifier).patch(
          currencyCode: picked.code,
          currencySymbol: picked.symbol,
        );
  }

  Future<T?> _showSearchPicker<T>({
    required BuildContext context,
    required String title,
    required List<T> items,
    required TextEditingController searchController,
    required String Function(T) labelFor,
    required bool Function(T, String) searchMatch,
    required bool Function(T) isSelected,
  }) async {
    searchController.clear();
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _SearchPickerSheet<T>(
        title: title,
        items: items,
        searchController: searchController,
        labelFor: labelFor,
        searchMatch: searchMatch,
        isSelected: isSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final draft = ref.watch(onboardingDraftProvider);
    final country = Countries.findByCode(draft.countryCode);
    final currency = Currencies.findByCode(draft.currencyCode);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.marginMobile,
              ),
              child: Row(
                children: [
                  Icon(Icons.local_gas_station, color: cs.primary),
                  const SizedBox(width: 8),
                  Text(
                    'FuelTrack Pro',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton(onPressed: widget.onSkip, child: const Text('Skip')),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.marginMobile,
                  AppSpacing.stackLg,
                  AppSpacing.marginMobile,
                  120,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const OnboardingProgressBar(
                      currentStep: 2,
                      totalSteps: 4,
                      segmented: true,
                    ),
                    const SizedBox(height: AppSpacing.stackLg),
                    Text(
                      'Country & Currency',
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.stackSm),
                    Text(
                      'Select your country and preferred currency independently for accurate cost analysis.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.stackLg),
                    _SettingsCard(
                      children: [
                        Text(
                          'Country',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: cs.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          tileColor: cs.surfaceContainerHighest,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                          ),
                          leading: Text(
                            country?.flag ?? '🌍',
                            style: const TextStyle(fontSize: 24),
                          ),
                          title: Text(country?.name ?? draft.countryCode),
                          subtitle: Text(
                            draft.countryCode,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _pickCountry(draft.countryCode),
                        ),
                        const SizedBox(height: AppSpacing.stackLg),
                        Text(
                          'Currency',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: cs.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          tileColor: cs.surfaceContainerHighest,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                          ),
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: cs.secondaryContainer,
                            child: Text(
                              draft.currencySymbol.length > 3
                                  ? draft.currencyCode.substring(0, 2)
                                  : draft.currencySymbol,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: cs.onSecondaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            currency?.name ?? draft.currencyCode,
                          ),
                          subtitle: Text(
                            '${draft.currencyCode} · ${draft.currencySymbol}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _pickCurrency(draft.currencyCode),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.gutter),
                    _SettingsCard(
                      children: [
                        Text(
                          'Measurement Units',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.stackLg),
                        _UnitToggleRow(
                          icon: Icons.straighten_outlined,
                          title: 'Distance',
                          subtitle: draft.useKm ? 'Kilometers (km)' : 'Miles (mi)',
                          value: draft.useKm,
                          onChanged: (v) => ref
                              .read(onboardingDraftProvider.notifier)
                              .patch(useKm: v),
                        ),
                        const SizedBox(height: AppSpacing.stackLg),
                        _UnitToggleRow(
                          icon: Icons.ev_station_outlined,
                          title: 'Fuel Volume',
                          subtitle: draft.useLiters ? 'Liters (L)' : 'Gallons (gal)',
                          value: draft.useLiters,
                          onChanged: (v) => ref
                              .read(onboardingDraftProvider.notifier)
                              .patch(useLiters: v),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.gutter),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.gutter),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor:
                                cs.onPrimaryContainer.withValues(alpha: 0.2),
                            child: Icon(
                              Icons.info_outline,
                              color: cs.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.stackMd),
                          Expanded(
                            child: Text(
                              'Country and currency can be changed independently in Settings anytime.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: cs.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.marginMobile),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              OnboardingPrimaryButton(
                label: 'Next Step',
                icon: Icons.arrow_forward,
                onPressed: widget.onNext,
              ),
              const SizedBox(height: AppSpacing.stackSm),
              Text(
                'By continuing, you agree to our local data handling policies.',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Search picker bottom sheet ─────────────────────────────────────────────────

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

// ── Local widgets ──────────────────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.gutter),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _UnitToggleRow extends StatelessWidget {
  const _UnitToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final tt = context.tt;
    return Row(
      children: [
        Icon(icon, color: cs.primary),
        const SizedBox(width: AppSpacing.gutter),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: tt.titleMedium),
              Text(
                subtitle,
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}
