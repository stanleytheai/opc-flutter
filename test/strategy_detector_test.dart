import 'package:flutter_test/flutter_test.dart';
import 'package:opc_flutter/models/option.dart';
import 'package:opc_flutter/providers/options_provider.dart';
import 'package:opc_flutter/services/strategy_detector.dart';

Option _makeOption({
  double strike = 100,
  String expiry = '2024-06-21',
  OptionType type = OptionType.call,
}) {
  return Option(
    strike: strike,
    expiry: expiry,
    callOrPut: type,
    bid: 5.0,
    ask: 5.5,
  );
}

SelectedOptionEntry _entry({
  double strike = 100,
  String expiry = '2024-06-21',
  OptionType type = OptionType.call,
  BuyOrSell action = BuyOrSell.buy,
  int quantity = 1,
}) {
  return SelectedOptionEntry(
    option: _makeOption(strike: strike, expiry: expiry, type: type),
    action: action,
    quantity: quantity,
  );
}

void main() {
  group('StrategyDetector', () {
    test('returns null for empty list', () {
      expect(StrategyDetector.detect([]), isNull);
    });

    test('detects Long Call', () {
      final result = StrategyDetector.detect([
        _entry(type: OptionType.call, action: BuyOrSell.buy),
      ]);
      expect(result, isNotNull);
      expect(result!.name, 'Long Call');
      expect(result.sentiment, 'bullish');
    });

    test('detects Short Put', () {
      final result = StrategyDetector.detect([
        _entry(type: OptionType.put, action: BuyOrSell.sell),
      ]);
      expect(result, isNotNull);
      expect(result!.name, 'Short Put');
      expect(result.sentiment, 'bullish');
    });

    test('detects Long Straddle', () {
      final result = StrategyDetector.detect([
        _entry(strike: 100, type: OptionType.call, action: BuyOrSell.buy),
        _entry(strike: 100, type: OptionType.put, action: BuyOrSell.buy),
      ]);
      expect(result, isNotNull);
      expect(result!.name, 'Long Straddle');
      expect(result.sentiment, 'volatile');
    });

    test('detects Short Straddle', () {
      final result = StrategyDetector.detect([
        _entry(strike: 100, type: OptionType.call, action: BuyOrSell.sell),
        _entry(strike: 100, type: OptionType.put, action: BuyOrSell.sell),
      ]);
      expect(result, isNotNull);
      expect(result!.name, 'Short Straddle');
      expect(result.sentiment, 'neutral');
    });

    test('detects Long Strangle', () {
      final result = StrategyDetector.detect([
        _entry(strike: 110, type: OptionType.call, action: BuyOrSell.buy),
        _entry(strike: 90, type: OptionType.put, action: BuyOrSell.buy),
      ]);
      expect(result, isNotNull);
      expect(result!.name, 'Long Strangle');
      expect(result.sentiment, 'volatile');
    });

    test('detects Bull Call Spread', () {
      final result = StrategyDetector.detect([
        _entry(strike: 100, type: OptionType.call, action: BuyOrSell.buy),
        _entry(strike: 110, type: OptionType.call, action: BuyOrSell.sell),
      ]);
      expect(result, isNotNull);
      expect(result!.name, 'Bull Call Spread');
      expect(result.sentiment, 'bullish');
    });

    test('detects Bear Put Spread', () {
      final result = StrategyDetector.detect([
        _entry(strike: 110, type: OptionType.put, action: BuyOrSell.buy),
        _entry(strike: 100, type: OptionType.put, action: BuyOrSell.sell),
      ]);
      expect(result, isNotNull);
      expect(result!.name, 'Bear Put Spread');
      expect(result.sentiment, 'bearish');
    });

    test('detects Bear Call Spread', () {
      final result = StrategyDetector.detect([
        _entry(strike: 110, type: OptionType.call, action: BuyOrSell.buy),
        _entry(strike: 100, type: OptionType.call, action: BuyOrSell.sell),
      ]);
      expect(result, isNotNull);
      expect(result!.name, 'Bear Call Spread');
      expect(result.sentiment, 'bearish');
    });

    test('detects Bull Put Spread', () {
      final result = StrategyDetector.detect([
        _entry(strike: 100, type: OptionType.put, action: BuyOrSell.buy),
        _entry(strike: 110, type: OptionType.put, action: BuyOrSell.sell),
      ]);
      expect(result, isNotNull);
      expect(result!.name, 'Bull Put Spread');
      expect(result.sentiment, 'bullish');
    });

    test('detects Calendar Spread', () {
      final result = StrategyDetector.detect([
        _entry(strike: 100, type: OptionType.call, action: BuyOrSell.sell, expiry: '2024-06-21'),
        _entry(strike: 100, type: OptionType.call, action: BuyOrSell.buy, expiry: '2024-07-19'),
      ]);
      expect(result, isNotNull);
      expect(result!.name, 'Calendar Spread');
      expect(result.sentiment, 'neutral');
    });

    test('detects Iron Condor', () {
      final result = StrategyDetector.detect([
        _entry(strike: 90, type: OptionType.put, action: BuyOrSell.buy),
        _entry(strike: 95, type: OptionType.put, action: BuyOrSell.sell),
        _entry(strike: 105, type: OptionType.call, action: BuyOrSell.sell),
        _entry(strike: 110, type: OptionType.call, action: BuyOrSell.buy),
      ]);
      expect(result, isNotNull);
      expect(result!.name, 'Iron Condor');
      expect(result.sentiment, 'neutral');
    });

    test('detects Iron Butterfly', () {
      final result = StrategyDetector.detect([
        _entry(strike: 90, type: OptionType.put, action: BuyOrSell.buy),
        _entry(strike: 100, type: OptionType.put, action: BuyOrSell.sell),
        _entry(strike: 100, type: OptionType.call, action: BuyOrSell.sell),
        _entry(strike: 110, type: OptionType.call, action: BuyOrSell.buy),
      ]);
      expect(result, isNotNull);
      expect(result!.name, 'Iron Butterfly');
      expect(result.sentiment, 'neutral');
    });

    test('detects Long Call Butterfly (4-leg)', () {
      final result = StrategyDetector.detect([
        _entry(strike: 90, type: OptionType.call, action: BuyOrSell.buy),
        _entry(strike: 100, type: OptionType.call, action: BuyOrSell.sell),
        _entry(strike: 100, type: OptionType.call, action: BuyOrSell.sell),
        _entry(strike: 110, type: OptionType.call, action: BuyOrSell.buy),
      ]);
      expect(result, isNotNull);
      expect(result!.name, 'Long Call Butterfly');
      expect(result.sentiment, 'neutral');
    });

    test('returns Custom for unrecognized multi-leg', () {
      final result = StrategyDetector.detect([
        _entry(strike: 100, type: OptionType.call, action: BuyOrSell.buy),
        _entry(strike: 110, type: OptionType.put, action: BuyOrSell.buy),
        _entry(strike: 120, type: OptionType.call, action: BuyOrSell.buy),
        _entry(strike: 130, type: OptionType.put, action: BuyOrSell.buy),
        _entry(strike: 140, type: OptionType.call, action: BuyOrSell.buy),
      ]);
      expect(result, isNotNull);
      expect(result!.name, contains('Custom'));
    });
  });
}
