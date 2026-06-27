import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../config/donate_config.dart';
import '../../../theme/theme_x.dart';
import '../donate_state.dart';

class AmountSelector extends StatelessWidget {
  const AmountSelector({
    super.key,
    required this.selectedAmount,
    required this.amountController,
    required this.onPreset,
    required this.onAmountChanged,
  });

  final int selectedAmount;
  final TextEditingController amountController;
  final void Function(int amount) onPreset;
  final void Function(String value) onAmountChanged;

  static final _inr = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  bool _presetHighlighted(int amount) {
    final parsed = int.tryParse(amountController.text.trim());
    return parsed == amount && selectedAmount == amount;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pal = context.palette;
    final amber = pal.brandAmber;
    final inactiveBorder = pal.cardBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final a in DonateConfig.presetAmounts) ...[
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onPreset(a),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 14,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _presetHighlighted(a) ? amber : inactiveBorder,
                            width: _presetHighlighted(a) ? 1.5 : 0.5,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _inr.format(a),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (presetSecondaryLabel(a).isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                presetSecondaryLabel(a),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 220,
              child: TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(7),
                ],
                onChanged: onAmountChanged,
                decoration: InputDecoration(
                  hintText: 'Amount (INR)',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
