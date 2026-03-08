import 'dart:math' as math;
import 'package:flutter/material.dart';

class AppColors {
  // Core palette — matches Angular's dark theme (#121212 base)
  static const background = Color(0xFF121212);
  static const surface = Color(0xFF1D1D1D);
  static const surfaceLight = Color(0xFF292929);
  static const border = Color(0xFF3A3A3A);

  static const primary = Color(0xFF00BFA5);
  static const primaryDark = Color(0xFF00897B);
  static const primaryLight = Color(0xFF64FFDA);

  static const profit = Color(0xFF4CAF50);
  static const loss = Color(0xFFF44336);

  static const textPrimary = Color(0xFFE6EDF3);
  static const textSecondary = Color(0xFFABABAB);
  static const textMuted = Color(0xFF5A5A5A);

  /// Heatmap gradient matching Angular's canvas approach:
  /// Negative: rgb(255, 255-|i|, 255-|i|) → red at -100%
  /// Positive: rgb(255-i, 255, 255-i) → green at +100%
  /// Neutral (0%): near-white, dimmed for dark theme
  ///
  /// We use 11 stops for a smooth, balanced gradient.
  static const _heatmapStops = [
    Color(0xFFFF0000), // -100%  pure red
    Color(0xFFFF3333), // -80%
    Color(0xFFFF6644), // -60%
    Color(0xFFFF9966), // -40%
    Color(0xFFFFCC99), // -20%
    Color(0xFF455A64), // 0%  neutral (dark-theme adjusted)
    Color(0xFF99CC99), // +20%
    Color(0xFF66BB66), // +40%
    Color(0xFF44AA44), // +60%
    Color(0xFF339933), // +80%
    Color(0xFF00CC00), // +100% pure green
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

  /// Alternate: direct Angular-style gradient (linear interpolation).
  /// Returns color with built-in alpha for dark theme rendering.
  static Color profitColorAngular(double profitPercent) {
    final clamped = profitPercent.clamp(-100.0, 100.0);
    final t = clamped / 100.0; // -1..+1
    final intensity = (t.abs() * 255).round().clamp(0, 255);
    if (t >= 0) {
      // Green channel dominant
      return Color.fromARGB(200, 255 - intensity, 255, 255 - intensity);
    } else {
      // Red channel dominant
      return Color.fromARGB(200, 255, 255 - intensity, 255 - intensity);
    }
  }

  /// Semantic colors for the heatmap — blended for dark theme visibility.
  static Color heatmapCellColor(double profitPercent) {
    final angular = profitColorAngular(profitPercent);
    // Darken the color to sit well on the #121212 background
    final r = (angular.r * 0.6).round();
    final g = (angular.g * 0.6).round();
    final b = (angular.b * 0.6).round();
    return Color.fromARGB(math.max(angular.a.round(), 160), r, g, b);
  }
}
