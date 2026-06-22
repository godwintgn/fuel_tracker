import 'package:flutter/material.dart';

import '../../theme/theme_x.dart';

/// Label/value row used across read-only detail screens.
class DetailRow extends StatelessWidget {
  const DetailRow({
    super.key,
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: tt.bodyMedium?.copyWith(
                color: context.cs.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: (emphasized ? tt.titleMedium : tt.bodyLarge)?.copyWith(
                fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
