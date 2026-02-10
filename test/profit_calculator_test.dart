import 'package:flutter_test/flutter_test.dart';
import 'package:opc_flutter/models/option.dart';
import 'package:opc_flutter/services/profit_calculator.dart';

void main() {
  group('ProfitCalculator', () {
    test('long call is profitable when stock rises above strike + premium', () {
      final option = Option(
        symbol: 'AAPL240315C00170000',
        ticker: 'AAPL',
        strike: 170,
        expiry: '2024-03-15',
        bid: 4.50,
        ask: 5.00,
        callOrPut: OptionType.call,
        impliedVolatility: 30,
        buyOrSell: BuyOrSell.buy,
      );

      final selected = SelectedOption(
        option: option,
        action: BuyOrSell.buy,
        quantity: 1,
      );

      // At expiration, stock at $180: profit = (180-170)*100 - premium
      final table = ProfitCalculator.calculate(
        selectedOptions: [selected],
        stockPrices: [160, 170, 175, 180, 190],
        dates: ['2024-03-15'], // expiration day
      );

      // At expiry, stock=160 (OTM): loss = -premium = -475
      final premium = option.premium; // (4.50+5.00)/2 * 100 = 475
      expect(premium, 475.0);

      final pnlOTM = table.getValue('2024-03-15', 160)!;
      expect(pnlOTM, closeTo(-475, 1));

      // At expiry, stock=180 (ITM): profit = (180-170)*100 - 475 = 525
      final pnlITM = table.getValue('2024-03-15', 180)!;
      expect(pnlITM, closeTo(525, 1));

      // At expiry, stock=170 (ATM): loss = -premium
      final pnlATM = table.getValue('2024-03-15', 170)!;
      expect(pnlATM, closeTo(-475, 1));
    });

    test('short put profits when stock stays above strike', () {
      final option = Option(
        strike: 100,
        expiry: '2024-06-21',
        bid: 3.00,
        ask: 3.50,
        callOrPut: OptionType.put,
        impliedVolatility: 25,
        buyOrSell: BuyOrSell.sell,
      );

      final selected = SelectedOption(
        option: option,
        action: BuyOrSell.sell,
        quantity: 1,
      );

      final table = ProfitCalculator.calculate(
        selectedOptions: [selected],
        stockPrices: [90, 100, 110],
        dates: ['2024-06-21'],
      );

      // At expiry, stock=110 (OTM put): keep full premium
      final premium = option.premium; // 325
      final pnl110 = table.getValue('2024-06-21', 110)!;
      expect(pnl110, closeTo(premium, 1));

      // At expiry, stock=90 (ITM put): loss = premium - (100-90)*100
      final pnl90 = table.getValue('2024-06-21', 90)!;
      expect(pnl90, closeTo(premium - 1000, 1));
    });

    test('generatePriceRange creates correct range', () {
      final prices = ProfitCalculator.generatePriceRange(100, steps: 10);
      expect(prices.length, 11);
      expect(prices.first, closeTo(75, 1));
      expect(prices.last, closeTo(125, 1));
    });

    test('generateDateRange includes expiry', () {
      final dates = ProfitCalculator.generateDateRange(
        '2024-04-19',
        startDate: '2024-04-01',
      );
      expect(dates.last, '2024-04-19');
      expect(dates.first, '2024-04-01');
    });
  });
}
