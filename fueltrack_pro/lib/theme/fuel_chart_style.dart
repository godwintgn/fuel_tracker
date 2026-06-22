import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Wealth Journal–style smooth line + area charts for fuel efficiency trends.
abstract final class FuelChartStyle {
  static const double curveSmoothness = 0.42;
  static const bool preventCurveOverShooting = true;
  static const double barWidthFull = 3;
  static const double barWidthMini = 2.5;

  static Shadow lineShadow(Color lineColor, {double blurRadius = 5.5}) {
    return Shadow(
      color: lineColor.withValues(alpha: 0.24),
      blurRadius: blurRadius,
      offset: Offset.zero,
    );
  }

  static BarAreaData areaBelow(Color lineColor) {
    return BarAreaData(
      show: true,
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: 0.32),
          lineColor.withValues(alpha: 0.14),
          lineColor.withValues(alpha: 0.04),
          lineColor.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.32, 0.68, 1.0],
      ),
    );
  }

  static LineChartBarData primarySeries({
    required List<FlSpot> spots,
    required Color color,
    required double barWidth,
    double shadowBlur = 5.5,
    bool showDots = false,
  }) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: curveSmoothness,
      preventCurveOverShooting: preventCurveOverShooting,
      color: color,
      barWidth: barWidth,
      isStrokeCapRound: true,
      isStrokeJoinRound: true,
      dotData: FlDotData(show: showDots),
      shadow: lineShadow(color, blurRadius: shadowBlur),
      belowBarData: areaBelow(color),
    );
  }

  /// Horizontal grid lines for bar/line charts (Wealth Journal pattern).
  static FlGridData horizontalGrid(ColorScheme cs) {
    return FlGridData(
      show: true,
      drawVerticalLine: false,
      getDrawingHorizontalLine: (_) => FlLine(
        color: cs.outlineVariant.withValues(alpha: 0.3),
        strokeWidth: 1,
      ),
    );
  }
}
