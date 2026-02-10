import '../models/option.dart';
import '../models/profit_table.dart';
import 'black_scholes.dart';

class SelectedOption {
  final Option option;
  final BuyOrSell action;
  final int quantity;

  SelectedOption({
    required this.option,
    required this.action,
    this.quantity = 1,
  });
}

class ProfitCalculator {
  static const double defaultInterestRate = 4.0; // %
  static const double defaultDividendYield = 0.0; // %

  /// Calculate a full profit table.
  ///
  /// [selectedOptions] — the legs of the trade
  /// [stockPrices] — y-axis price range
  /// [dates] — x-axis date strings (ISO format)
  /// [interestRate] — annualized, as percentage
  /// [dividendYield] — annualized, as percentage
  static ProfitTable calculate({
    required List<SelectedOption> selectedOptions,
    required List<double> stockPrices,
    required List<String> dates,
    double interestRate = defaultInterestRate,
    double dividendYield = defaultDividendYield,
  }) {
    final data = <String, double>{};

    for (final date in dates) {
      final evalDate = DateTime.parse(date);
      for (final price in stockPrices) {
        double totalPnL = 0;

        for (final sel in selectedOptions) {
          final opt = sel.option;
          final expiryDate = DateTime.parse(opt.expiry);
          final daysToExpiry =
              expiryDate.difference(evalDate).inDays.toDouble();

          double hypotheticalPremium;
          if (daysToExpiry <= 0) {
            // At expiration: intrinsic value only
            if (opt.callOrPut == OptionType.call) {
              hypotheticalPremium = (price - opt.strike).clamp(0, double.infinity) * 100;
            } else {
              hypotheticalPremium = (opt.strike - price).clamp(0, double.infinity) * 100;
            }
          } else {
            final perShare = opt.callOrPut == OptionType.call
                ? calculateCallPremium(
                    price, interestRate, opt.strike, daysToExpiry,
                    opt.impliedVolatility, dividendYield)
                : calculatePutPremium(
                    price, interestRate, opt.strike, daysToExpiry,
                    opt.impliedVolatility, dividendYield);
            hypotheticalPremium = perShare * 100;
          }

          final entryCost = opt.premium; // midpoint × 100
          double legPnL;
          if (sel.action == BuyOrSell.buy) {
            legPnL = hypotheticalPremium - entryCost;
          } else {
            legPnL = entryCost - hypotheticalPremium;
          }
          totalPnL += legPnL * sel.quantity;
        }

        data[ProfitTable.generateKey(date, price)] = totalPnL;
      }
    }

    return ProfitTable(xAxis: dates, yAxis: stockPrices, data: data);
  }

  /// Generate a reasonable stock price range around [currentPrice].
  static List<double> generatePriceRange(
    double currentPrice, {
    double rangePct = 0.25,
    int steps = 50,
  }) {
    final low = currentPrice * (1 - rangePct);
    final high = currentPrice * (1 + rangePct);
    final step = (high - low) / steps;
    return List.generate(
      steps + 1,
      (i) => double.parse((low + step * i).toStringAsFixed(2)),
    );
  }

  /// Generate date range from today to [expiryDate].
  static List<String> generateDateRange(String expiryDate, {String? startDate}) {
    final start = startDate != null ? DateTime.parse(startDate) : DateTime.now();
    final end = DateTime.parse(expiryDate);
    final days = end.difference(start).inDays;
    if (days <= 0) return [expiryDate];

    // Aim for ~30 date points max
    final step = (days / 30).ceil().clamp(1, days);
    final dates = <String>[];
    for (var d = start; !d.isAfter(end); d = d.add(Duration(days: step))) {
      dates.add(d.toIso8601String().substring(0, 10));
    }
    // Always include expiry
    final expiryStr = end.toIso8601String().substring(0, 10);
    if (dates.last != expiryStr) dates.add(expiryStr);
    return dates;
  }
}
