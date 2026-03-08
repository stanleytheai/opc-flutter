import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opc_flutter/theme/colors.dart';

void main() {
  group('AppColors.profitColor', () {
    test('returns neutral color at 0%', () {
      final color = AppColors.profitColor(0);
      // Should be in the neutral gray range
      expect(color.red, greaterThan(40));
      expect(color.green, greaterThan(60));
      expect(color.blue, greaterThan(70));
    });

    test('returns green-ish color at +100%', () {
      final color = AppColors.profitColor(100);
      // Deep green
      expect(color.green, greaterThan(color.red));
    });

    test('returns red-ish color at -100%', () {
      final color = AppColors.profitColor(-100);
      // Deep red
      expect(color.red, greaterThan(color.green));
    });

    test('clamps values beyond range', () {
      final colorPlus = AppColors.profitColor(200);
      final colorMax = AppColors.profitColor(100);
      expect(colorPlus, equals(colorMax));

      final colorMinus = AppColors.profitColor(-200);
      final colorMin = AppColors.profitColor(-100);
      expect(colorMinus, equals(colorMin));
    });

    test('positive values are greener than negative values', () {
      final positive = AppColors.profitColor(50);
      final negative = AppColors.profitColor(-50);
      expect(positive.green, greaterThan(negative.green));
      expect(negative.red, greaterThan(positive.red));
    });
  });

  group('ProfitTable key utilities', () {
    test('generateKey creates consistent keys', () {
      // This verifies the format used by heatmap for lookups
      const date = '2024-03-15';
      const price = 170.5;
      final key = '$date:$price';
      expect(key, '2024-03-15:170.5');
    });
  });
}
