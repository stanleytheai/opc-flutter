import 'package:flutter_test/flutter_test.dart';
import 'package:opc_flutter/models/profit_table.dart';
import 'package:opc_flutter/providers/calculation_provider.dart';

void main() {
  group('ProfitSummary', () {
    test('computes max profit and max loss from table', () {
      // Create a simple profit table with known values
      final dates = ['2024-06-01', '2024-06-15', '2024-06-21'];
      final prices = [90.0, 95.0, 100.0, 105.0, 110.0];
      final data = <String, double>{};

      // At expiration (last column), simulate a long call at 100 with premium of $500
      // price 90: -500, price 95: -500, price 100: -500, price 105: 0, price 110: 500
      for (final date in dates) {
        for (final price in prices) {
          double value;
          if (date == '2024-06-21') {
            // Expiration values
            value = ((price - 100).clamp(0, double.infinity) * 100) - 500;
          } else {
            value = ((price - 100) * 50) - 250; // Simplified pre-expiry
          }
          data[ProfitTable.generateKey(date, price)] = value;
        }
      }

      final table = ProfitTable(xAxis: dates, yAxis: prices, data: data);
      final summary = ProfitSummary.fromTable(table);

      expect(summary.maxProfit, 500.0);
      expect(summary.maxLoss, -500.0);
      expect(summary.maxProfitPrice, 110.0);
      expect(summary.maxLossPrice, 90.0);
    });

    test('finds breakeven prices at expiration', () {
      final dates = ['2024-06-21'];
      final prices = [95.0, 100.0, 105.0, 110.0];
      final data = <String, double>{};

      // -500, -500, 0, 500 at expiration
      data[ProfitTable.generateKey('2024-06-21', 95.0)] = -500.0;
      data[ProfitTable.generateKey('2024-06-21', 100.0)] = -500.0;
      data[ProfitTable.generateKey('2024-06-21', 105.0)] = 0.0;
      data[ProfitTable.generateKey('2024-06-21', 110.0)] = 500.0;

      final table = ProfitTable(xAxis: dates, yAxis: prices, data: data);
      final summary = ProfitSummary.fromTable(table);

      // Breakeven between 100 (-500) and 105 (0), and between 105 (0) and 110 (500)
      // Actually, 0 is >= 0, so crossing from -500 to 0 is a breakeven
      expect(summary.breakevenPrices, isNotEmpty);
    });

    test('handles empty table', () {
      final table = ProfitTable(xAxis: [], yAxis: [], data: {});
      final summary = ProfitSummary.fromTable(table);

      expect(summary.maxProfit, 0.0);
      expect(summary.maxLoss, 0.0);
      expect(summary.breakevenPrices, isEmpty);
    });
  });
}
