import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CryptoAddressRow extends StatelessWidget {
  const CryptoAddressRow({
    super.key,
    required this.label,
    required this.address,
    required this.labelColor,
    required this.onCopied,
    required this.onOpenWallet,
    this.copyTooltip = 'Copy address',
    this.openTooltip = 'Open in wallet app',
    this.openEnabled = true,
  });

  final String label;
  final String address;
  final Color labelColor;
  final VoidCallback onCopied;
  final VoidCallback onOpenWallet;
  final String copyTooltip;
  final String openTooltip;
  final bool openEnabled;

  String _truncated() {
    if (address.length <= 14) return address;
    return '${address.substring(0, 6)}…${address.substring(address.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: labelColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              _truncated(),
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                fontFamilyFallback: const ['monospace'],
              ),
            ),
          ),
          IconButton(
            tooltip: copyTooltip,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: address));
              onCopied();
            },
            icon: const Icon(Icons.copy_rounded),
          ),
          IconButton(
            tooltip: openTooltip,
            onPressed: openEnabled ? onOpenWallet : null,
            icon: const Icon(Icons.account_balance_wallet_outlined),
          ),
        ],
      ),
    );
  }
}
