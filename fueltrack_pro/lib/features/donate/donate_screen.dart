import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/donate_config.dart';
import '../../theme/app_spacing.dart';
import '../../theme/theme_x.dart';
import '../../widgets/common/app_card.dart';
import 'donate_notifier.dart';
import 'donate_state.dart';
import 'widgets/amount_selector.dart';
import 'widgets/crypto_address_row.dart';
import 'widgets/method_card.dart';

/// Donation flow — UPI, PayPal, crypto (Wealth Journal pattern).
class DonateScreen extends StatefulWidget {
  const DonateScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const DonateScreen()),
    );
  }

  @override
  State<DonateScreen> createState() => _DonateScreenState();
}

class _DonateScreenState extends State<DonateScreen> {
  late final DonateNotifier _n;
  late final TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _n = DonateNotifier();
    _amountController =
        TextEditingController(text: '${DonateConfig.defaultAmount}');
  }

  @override
  void dispose() {
    _amountController.dispose();
    _n.dispose();
    super.dispose();
  }

  Future<bool> _tryLaunchExternal(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Donate: launch failed for $uri — $e');
      return false;
    }
  }

  Future<void> _openUpiPaymentApp() async {
    if (!_n.hasValidAmount || _n.busyOpening) return;
    await _launchUpiPayment(_n.selectedAmount);
  }

  Future<void> _launchUpiPayment(int amount) async {
    _n.setOpeningBusy();
    try {
      final deep = buildUpiDeepLink(
        upiId: DonateConfig.upiId,
        payeeName: DonateConfig.upiPayeeName,
        amount: amount,
        note: DonateConfig.upiNote,
      );
      final ok = await _tryLaunchExternal(Uri.parse(deep));
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No UPI app opened. Copy the UPI ID and pay from your banking app.',
            ),
          ),
        );
      }
    } finally {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (mounted) _n.clearOpeningBusy();
    }
  }

  Future<void> _onPayPalPressed() async {
    if (_n.busyOpening) return;
    _n.setOpeningBusy();
    try {
      final url = DonateConfig.paypalProfileUri;
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } finally {
      await Future<void>.delayed(const Duration(seconds: 2));
      if (mounted) _n.clearOpeningBusy();
    }
  }

  Future<void> _openCryptoWallet({required bool bitcoin}) async {
    final address =
        bitcoin ? DonateConfig.btcAddress : DonateConfig.erc20Address;
    final ok = await _tryLaunchExternal(
      cryptoWalletUri(bitcoin: bitcoin, address: address),
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No wallet app opened. Copy the address instead.'),
        ),
      );
    }
  }

  Future<void> _openSolanaWallet() async {
    final ok = await _tryLaunchExternal(
      solanaWalletUri(DonateConfig.solanaAddress),
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No Solana wallet opened. Copy the address instead.'),
        ),
      );
    }
  }

  Future<void> _openTerms() async {
    final ok = await _tryLaunchExternal(DonateConfig.termsUri);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open terms in browser.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pal = context.palette;
    final amber = pal.brandAmber;

    return ListenableBuilder(
      listenable: _n,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Support development'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.marginMobile,
              AppSpacing.stackLg,
              AppSpacing.marginMobile,
              120,
            ),
            children: [
              AppCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer
                            .withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.favorite_rounded,
                        color: theme.colorScheme.error,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FuelTrack Pro is free',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'No subscriptions, no ads. If the app helps you track fuel and costs, a small contribution keeps development going.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              height: 1.4,
                              color: pal.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.stackLg),
              AmountSelector(
                selectedAmount: _n.selectedAmount,
                amountController: _amountController,
                onPreset: (a) {
                  _amountController.text = a.toString();
                  _n.applyPresetAmount(a);
                },
                onAmountChanged: _n.updateAmountFromField,
              ),
              const SizedBox(height: AppSpacing.stackMd),
              MethodCard(
                title: 'UPI',
                badge: 'Recommended',
                expanded: _n.expandedMethod == DonateMethod.upi,
                onHeaderTap: () => _n.tapMethodHeader(DonateMethod.upi),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _n.hasValidAmount
                          ? 'Opens your UPI app with ₹${_n.selectedAmount} prefilled.'
                          : 'Enter at least ₹${DonateConfig.minimumAmount} to open a payment app.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: pal.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    CryptoAddressRow(
                      label: 'UPI ID',
                      address: DonateConfig.upiId,
                      labelColor: Colors.green.shade700,
                      copyTooltip: 'Copy UPI ID',
                      openTooltip: 'Open UPI payment app',
                      openEnabled: _n.hasValidAmount && !_n.busyOpening,
                      onCopied: () {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('UPI ID copied')),
                        );
                      },
                      onOpenWallet: _openUpiPaymentApp,
                    ),
                  ],
                ),
              ),
              MethodCard(
                title: 'PayPal',
                badge: 'International',
                expanded: _n.expandedMethod == DonateMethod.paypal,
                onHeaderTap: () => _n.tapMethodHeader(DonateMethod.paypal),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Opens PayPal in your browser. Enter any amount on the PayPal page.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: pal.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _n.busyOpening ? null : _onPayPalPressed,
                      icon: _n.busyOpening
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.onPrimary,
                              ),
                            )
                          : const Icon(Icons.open_in_new_rounded),
                      label: const Text('Open PayPal'),
                    ),
                  ],
                ),
              ),
              MethodCard(
                title: 'Crypto',
                expanded: _n.expandedMethod == DonateMethod.crypto,
                onHeaderTap: () => _n.tapMethodHeader(DonateMethod.crypto),
                child: Column(
                  children: [
                    CryptoAddressRow(
                      label: 'Bitcoin',
                      address: DonateConfig.btcAddress,
                      labelColor: Colors.orange.shade700,
                      onCopied: () {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Bitcoin address copied')),
                        );
                      },
                      onOpenWallet: () => _openCryptoWallet(bitcoin: true),
                    ),
                    CryptoAddressRow(
                      label: 'ERC-20',
                      address: DonateConfig.erc20Address,
                      labelColor: Colors.blue.shade600,
                      onCopied: () {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Address copied')),
                        );
                      },
                      onOpenWallet: () => _openCryptoWallet(bitcoin: false),
                    ),
                    CryptoAddressRow(
                      label: 'Solana',
                      address: DonateConfig.solanaAddress,
                      labelColor: Colors.deepPurple.shade400,
                      onCopied: () {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Solana address copied')),
                        );
                      },
                      onOpenWallet: _openSolanaWallet,
                    ),
                    Text(
                      'Verify the full address before sending.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: amber,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.stackMd),
              Text.rich(
                TextSpan(
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  children: [
                    const TextSpan(
                      text:
                          'Donations are voluntary and non-refundable. See ',
                    ),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.baseline,
                      baseline: TextBaseline.alphabetic,
                      child: GestureDetector(
                        onTap: _openTerms,
                        child: Text(
                          'Terms',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
