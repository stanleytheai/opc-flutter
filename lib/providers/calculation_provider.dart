import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profit_table.dart';
import '../services/profit_calculator.dart';
import '../services/strategy_detector.dart';
import 'options_provider.dart';
import 'settings_provider.dart';
import 'ticker_provider.dart';

final profitTableProvider = FutureProvider<ProfitTable?>((ref) async {
  final selected = ref.watch(selectedOptionsProvider);
  if (selected.isEmpty) return null;

  final ticker = await ref.watch(selectedTickerProvider.future);
  if (ticker == null) return null;

  final settings = ref.watch(settingsProvider);
  final currentPrice = ticker.lastPrice;

  // Find the longest expiry among selected options for full date range
  final expiries = selected.map((s) => s.option.expiry).toList()..sort();
  final longestExpiry = expiries.last;

  final stockPrices = ProfitCalculator.generatePriceRange(
    currentPrice,
    rangePct: settings.priceRangePercent,
    steps: settings.priceSteps,
  );
  final dates = ProfitCalculator.generateDateRange(longestExpiry);

  final legs = selected
      .map((s) => SelectedOption(
            option: s.option,
            action: s.action,
            quantity: s.quantity,
          ))
      .toList();

  return ProfitCalculator.calculate(
    selectedOptions: legs,
    stockPrices: stockPrices,
    dates: dates,
    interestRate: settings.interestRate,
    dividendYield: settings.dividendYield,
  );
});

/// Detected strategy based on current selections.
final detectedStrategyProvider = Provider<DetectedStrategy?>((ref) {
  final selected = ref.watch(selectedOptionsProvider);
  return StrategyDetector.detect(selected);
});

/// Profit summary stats computed from the profit table.
final profitSummaryProvider = Provider<ProfitSummary?>((ref) {
  final tableAsync = ref.watch(profitTableProvider);
  return tableAsync.whenData((table) {
    if (table == null) return null;
    return ProfitSummary.fromTable(table);
  }).value;
});

/// Summary statistics for the profit table.
class ProfitSummary {
  final double maxProfit;
  final double maxLoss;
  final List<double> breakevenPrices; // at expiration
  final double maxProfitPrice;
  final double maxLossPrice;

  const ProfitSummary({
    required this.maxProfit,
    required this.maxLoss,
    required this.breakevenPrices,
    required this.maxProfitPrice,
    required this.maxLossPrice,
  });

  factory ProfitSummary.fromTable(ProfitTable table) {
    double maxProfit = double.negativeInfinity;
    double maxLoss = double.infinity;
    double maxProfitPrice = 0;
    double maxLossPrice = 0;
    final breakevenPrices = <double>[];

    if (table.dates.isEmpty || table.prices.isEmpty) {
      return const ProfitSummary(
        maxProfit: 0,
        maxLoss: 0,
        breakevenPrices: [],
        maxProfitPrice: 0,
        maxLossPrice: 0,
      );
    }

    // Look at the expiration column (last column) for max/min/breakeven
    final expiryCol = table.dates.length - 1;
    for (int r = 0; r < table.prices.length; r++) {
      final val = table.values[r][expiryCol];
      if (val > maxProfit) {
        maxProfit = val;
        maxProfitPrice = table.prices[r];
      }
      if (val < maxLoss) {
        maxLoss = val;
        maxLossPrice = table.prices[r];
      }
    }

    // Find breakeven prices at expiration (where P&L crosses zero)
    for (int r = 1; r < table.prices.length; r++) {
      final prev = table.values[r - 1][expiryCol];
      final curr = table.values[r][expiryCol];
      if ((prev <= 0 && curr >= 0) || (prev >= 0 && curr <= 0)) {
        // Linear interpolation to find exact breakeven
        if ((curr - prev).abs() > 0.001) {
          final ratio = prev.abs() / (prev.abs() + curr.abs());
          final breakeven = table.prices[r - 1] +
              ratio * (table.prices[r] - table.prices[r - 1]);
          breakevenPrices.add(double.parse(breakeven.toStringAsFixed(2)));
        } else {
          breakevenPrices.add(table.prices[r]);
        }
      }
    }

    return ProfitSummary(
      maxProfit: maxProfit == double.negativeInfinity ? 0 : maxProfit,
      maxLoss: maxLoss == double.infinity ? 0 : maxLoss,
      breakevenPrices: breakevenPrices,
      maxProfitPrice: maxProfitPrice,
      maxLossPrice: maxLossPrice,
    );
  }
}
