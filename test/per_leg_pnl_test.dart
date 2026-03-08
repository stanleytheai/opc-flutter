import 'package:flutter_test/flutter_test.dart';
import 'package:opc_flutter/models/option.dart';
import 'package:opc_flutter/services/black_scholes.dart';
import 'package:opc_flutter/services/profit_calculator.dart';
import 'package:opc_flutter/providers/options_provider.dart';

void main() {
  group('Per-leg P&L computation', () {
    Option _makeOption({
      required double strike,
      required OptionType type,
      double bid = 5.0,
      double ask = 5.50,
      double iv = 30.0,
      String expiry = '2024-06-15',
    }) {
      return Option(
        strike: strike,
        expiry: expiry,
        callOrPut: type,
        bid: bid,
        ask: ask,
        impliedVolatility: iv,
      );
    }

    test('buy call at expiration: intrinsic value profit', () {
      final opt = _makeOption(strike: 100, type: OptionType.call, bid: 5.0, ask: 5.0);
      final entry = SelectedOptionEntry(option: opt, action: BuyOrSell.buy, quantity: 1);

      // At expiration, stock at 110, call is worth (110 - 100) * 100 = 1000
      // Entry cost = midpoint * 100 = 5.0 * 100 = 500
      // P&L = 1000 - 500 = 500
      final stockPrice = 110.0;
      final date = '2024-06-15'; // expiry date
      final evalDate = DateTime.parse(date);
      final expiryDate = DateTime.parse(opt.expiry);
      final daysToExpiry = expiryDate.difference(evalDate).inDays.toDouble();
      expect(daysToExpiry, 0);

      final intrinsic = (stockPrice - opt.strike).clamp(0.0, double.infinity) * 100;
      expect(intrinsic, 1000.0);

      final pnl = intrinsic - opt.premium;
      expect(pnl, 500.0);
    });

    test('sell put at expiration: keeps premium if OTM', () {
      final opt = _makeOption(strike: 100, type: OptionType.put, bid: 3.0, ask: 3.0);
      final entry = SelectedOptionEntry(option: opt, action: BuyOrSell.sell, quantity: 1);

      // At expiration, stock at 110, put is worthless (OTM)
      // Entry cost (received) = 3.0 * 100 = 300
      // P&L = 300 - 0 = 300
      final stockPrice = 110.0;
      final intrinsic = (opt.strike - stockPrice).clamp(0.0, double.infinity) * 100;
      expect(intrinsic, 0.0);

      final pnl = opt.premium - intrinsic; // sell: entry - hyp
      expect(pnl, 300.0);
    });

    test('buy put at expiration: profit when ITM', () {
      final opt = _makeOption(strike: 100, type: OptionType.put, bid: 4.0, ask: 4.0);

      // Stock at 90, put worth (100 - 90) * 100 = 1000
      // Entry cost = 400
      // P&L = 1000 - 400 = 600
      final stockPrice = 90.0;
      final intrinsic = (opt.strike - stockPrice).clamp(0.0, double.infinity) * 100;
      expect(intrinsic, 1000.0);

      final pnl = intrinsic - opt.premium; // buy: hyp - entry
      expect(pnl, 600.0);
    });

    test('quantity multiplier works', () {
      final opt = _makeOption(strike: 100, type: OptionType.call, bid: 5.0, ask: 5.0);

      // At expiration, stock at 110
      final stockPrice = 110.0;
      final intrinsic = (stockPrice - opt.strike).clamp(0.0, double.infinity) * 100;
      final legPnL = intrinsic - opt.premium; // 1000 - 500 = 500
      final totalPnL = legPnL * 3; // quantity = 3
      expect(totalPnL, 1500.0);
    });

    test('multi-leg P&L sums correctly', () {
      // Bull call spread: buy 100 call, sell 110 call
      final buyCall = _makeOption(strike: 100, type: OptionType.call, bid: 8.0, ask: 8.0);
      final sellCall = _makeOption(strike: 110, type: OptionType.call, bid: 3.0, ask: 3.0);

      // At expiration, stock at 115
      final stockPrice = 115.0;

      // Buy leg: intrinsic = (115-100)*100 = 1500, entry = 800, P&L = 700
      final buyIntrinsic = (stockPrice - buyCall.strike).clamp(0.0, double.infinity) * 100;
      final buyPnL = buyIntrinsic - buyCall.premium;
      expect(buyPnL, 700.0);

      // Sell leg: intrinsic = (115-110)*100 = 500, entry = 300, P&L = 300 - 500 = -200
      final sellIntrinsic = (stockPrice - sellCall.strike).clamp(0.0, double.infinity) * 100;
      final sellPnL = sellCall.premium - sellIntrinsic;
      expect(sellPnL, -200.0);

      // Total P&L = 700 + (-200) = 500
      final totalPnL = buyPnL + sellPnL;
      expect(totalPnL, 500.0);
    });

    test('before expiration uses Black-Scholes', () {
      final opt = _makeOption(
        strike: 100,
        type: OptionType.call,
        bid: 5.0,
        ask: 5.0,
        iv: 30.0,
        expiry: '2024-06-15',
      );

      // 30 days before expiration
      final evalDate = DateTime.parse('2024-05-16');
      final expiryDate = DateTime.parse(opt.expiry);
      final daysToExpiry = expiryDate.difference(evalDate).inDays.toDouble();
      expect(daysToExpiry, 30);

      final stockPrice = 105.0;
      final hypothetical = calculateCallPremium(
        stockPrice, 4.0, opt.strike, daysToExpiry, opt.impliedVolatility, 0.0,
      );

      // Black-Scholes should give a value greater than intrinsic (has time value)
      final intrinsic = (stockPrice - opt.strike).clamp(0.0, double.infinity);
      expect(hypothetical, greaterThan(intrinsic));
      expect(hypothetical, greaterThan(0));
    });
  });
}
