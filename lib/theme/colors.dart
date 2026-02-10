import 'package:flutter/material.dart';

class AppColors {
  // Core palette
  static const background = Color(0xFF0D1117);
  static const surface = Color(0xFF161B22);
  static const surfaceLight = Color(0xFF21262D);
  static const border = Color(0xFF30363D);

  static const primary = Color(0xFF00BFA5);
  static const primaryDark = Color(0xFF00897B);
  static const primaryLight = Color(0xFF64FFDA);

  static const profit = Color(0xFF4CAF50);
  static const loss = Color(0xFFF44336);

  static const textPrimary = Color(0xFFE6EDF3);
  static const textSecondary = Color(0xFF8B949E);
  static const textMuted = Color(0xFF484F58);

  // Heatmap gradient stops: deep red → orange → neutral → light green → deep green
  static const _heatmapStops = [
    Color(0xFFD32F2F), // -100%
    Color(0xFFE53935), // -75%
    Color(0xFFFF7043), // -50%
    Color(0xFFFFB74D), // -25%
    Color(0xFF37474F), // 0% (neutral)
    Color(0xFF81C784), // +25%
    Color(0xFF66BB6A), // +50%
    Color(0xFF43A047), // +75%
    Color(0xFF2E7D32), // +100%
  ];

  /// Maps a profit percentage (-100..+100) to a color on the heatmap gradient.
  static Color profitColor(double profitPercent) {
    final clamped = profitPercent.clamp(-100.0, 100.0);
    // Normalize to 0..1
    final t = (clamped + 100.0) / 200.0;
    final segmentCount = _heatmapStops.length - 1;
    final segment = (t * segmentCount).floor().clamp(0, segmentCount - 1);
    final segmentT = (t * segmentCount) - segment;
    return Color.lerp(_heatmapStops[segment], _heatmapStops[segment + 1], segmentT)!;
  }
}
