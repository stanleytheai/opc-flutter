import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profit_table.dart';
import '../services/profit_calculator.dart';
import 'options_provider.dart';
import 'ticker_provider.dart';

final profitTableProvider = FutureProvider<ProfitTable?>((ref) async {
  final selected = ref.watch(selectedOptionsProvider);
  if (selected.isEmpty) return null;

  final ticker = await ref.watch(selectedTickerProvider.future);
  if (ticker == null) return null;

  final currentPrice = ticker.lastPrice;

  // Find the shortest expiry among selected options
  final expiries = selected.map((s) => s.option.expiry).toList()..sort();
  final shortestExpiry = expiries.first;

  final stockPrices = ProfitCalculator.generatePriceRange(currentPrice);
  final dates = ProfitCalculator.generateDateRange(shortestExpiry);

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
  );
});
