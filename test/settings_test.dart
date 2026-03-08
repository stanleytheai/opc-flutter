import 'package:flutter_test/flutter_test.dart';
import 'package:opc_flutter/models/settings.dart';

void main() {
  group('CalculationSettings', () {
    test('default values', () {
      const s = CalculationSettings();
      expect(s.interestRate, 4.0);
      expect(s.dividendYield, 0.0);
      expect(s.priceRangePercent, 0.25);
      expect(s.priceSteps, 50);
    });

    test('copyWith overrides specific fields', () {
      const s = CalculationSettings();
      final updated = s.copyWith(interestRate: 5.0, dividendYield: 1.0);
      expect(updated.interestRate, 5.0);
      expect(updated.dividendYield, 1.0);
      expect(updated.priceRangePercent, 0.25);
      expect(updated.priceSteps, 50);
    });

    test('toQueryParams omits defaults', () {
      const s = CalculationSettings();
      expect(s.toQueryParams(), isEmpty);
    });

    test('toQueryParams includes non-defaults', () {
      const s = CalculationSettings(interestRate: 5.0, priceSteps: 100);
      final params = s.toQueryParams();
      expect(params['ir'], '5.0');
      expect(params['ps'], '100');
      expect(params.containsKey('dy'), isFalse);
      expect(params.containsKey('pr'), isFalse);
    });

    test('fromQueryParams parses correctly', () {
      final s = CalculationSettings.fromQueryParams({
        'ir': '3.5',
        'dy': '0.7',
        'pr': '0.3',
        'ps': '60',
      });
      expect(s.interestRate, 3.5);
      expect(s.dividendYield, 0.7);
      expect(s.priceRangePercent, 0.3);
      expect(s.priceSteps, 60);
    });

    test('fromQueryParams uses defaults for missing values', () {
      final s = CalculationSettings.fromQueryParams({});
      expect(s.interestRate, 4.0);
      expect(s.dividendYield, 0.0);
      expect(s.priceRangePercent, 0.25);
      expect(s.priceSteps, 50);
    });
  });
}
