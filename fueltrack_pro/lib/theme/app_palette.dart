import 'package:flutter/material.dart';

/// Semantic colours aligned with Wealth Journal's [AppPalette] pattern.
/// Access via `context.palette` or `Theme.of(context).extension<AppPalette>()`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.cardBorder,
    required this.textSecondary,
    required this.textMuted,
    required this.gain,
    required this.loss,
    required this.brandAmber,
    required this.efficiency,
    required this.spend,
    required this.fuel,
    required this.neutral,
  });

  final Color cardBorder;
  final Color textSecondary;
  final Color textMuted;
  final Color gain;
  final Color loss;
  final Color brandAmber;
  /// Efficiency / km·L trend line colour.
  final Color efficiency;
  /// Spend / cost metrics.
  final Color spend;
  /// Fuel volume / fill-up accent.
  final Color fuel;
  final Color neutral;

  static const AppPalette dark = AppPalette(
    cardBorder: Color(0xFF2a2d36),
    textSecondary: Color(0xFF888888),
    textMuted: Color(0xFF555555),
    gain: Color(0xFF22c55e),
    loss: Color(0xFFef4444),
    brandAmber: Color(0xFFd97706),
    efficiency: Color(0xFF22c55e),
    spend: Color(0xFF378add),
    fuel: Color(0xFFf59e0b),
    neutral: Color(0xFF6b7280),
  );

  static const AppPalette light = AppPalette(
    cardBorder: Color(0xFFd1d5db),
    textSecondary: Color(0xFF6b7280),
    textMuted: Color(0xFF9ca3af),
    gain: Color(0xFF16a34a),
    loss: Color(0xFFdc2626),
    brandAmber: Color(0xFFd97706),
    efficiency: Color(0xFF16a34a),
    spend: Color(0xFF2563eb),
    fuel: Color(0xFFd97706),
    neutral: Color(0xFF6b7280),
  );

  @override
  AppPalette copyWith({
    Color? cardBorder,
    Color? textSecondary,
    Color? textMuted,
    Color? gain,
    Color? loss,
    Color? brandAmber,
    Color? efficiency,
    Color? spend,
    Color? fuel,
    Color? neutral,
  }) {
    return AppPalette(
      cardBorder: cardBorder ?? this.cardBorder,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      gain: gain ?? this.gain,
      loss: loss ?? this.loss,
      brandAmber: brandAmber ?? this.brandAmber,
      efficiency: efficiency ?? this.efficiency,
      spend: spend ?? this.spend,
      fuel: fuel ?? this.fuel,
      neutral: neutral ?? this.neutral,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      gain: Color.lerp(gain, other.gain, t)!,
      loss: Color.lerp(loss, other.loss, t)!,
      brandAmber: Color.lerp(brandAmber, other.brandAmber, t)!,
      efficiency: Color.lerp(efficiency, other.efficiency, t)!,
      spend: Color.lerp(spend, other.spend, t)!,
      fuel: Color.lerp(fuel, other.fuel, t)!,
      neutral: Color.lerp(neutral, other.neutral, t)!,
    );
  }
}

extension AppPaletteX on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
