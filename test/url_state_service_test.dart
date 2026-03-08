import 'package:flutter_test/flutter_test.dart';
import 'package:opc_flutter/models/option.dart';
import 'package:opc_flutter/models/settings.dart';
import 'package:opc_flutter/services/url_state_service.dart';

void main() {
  group('UrlStateService', () {
    test('encode produces correct query params', () {
      final params = UrlStateService.encode(
        ticker: 'AAPL',
        legs: [
          SelectedLegParams(
            strike: 150,
            expiry: '2024-06-21',
            callOrPut: OptionType.call,
            action: BuyOrSell.buy,
            quantity: 2,
          ),
        ],
        settings: const CalculationSettings(),
      );

      expect(params['t'], 'AAPL');
      expect(params['legs'], '150.0:2024-06-21:C:B:2');
      // Default settings should not produce extra params
      expect(params.containsKey('ir'), isFalse);
    });

    test('encode includes non-default settings', () {
      final params = UrlStateService.encode(
        ticker: 'SPY',
        legs: [],
        settings: const CalculationSettings(interestRate: 5.0, dividendYield: 1.5),
      );

      expect(params['ir'], '5.0');
      expect(params['dy'], '1.5');
    });

    test('decode returns null without ticker', () {
      final result = UrlStateService.decode({});
      expect(result, isNull);
    });

    test('decode restores ticker and legs', () {
      final result = UrlStateService.decode({
        't': 'TSLA',
        'legs': '200.0:2024-07-19:P:S:3',
      });

      expect(result, isNotNull);
      expect(result!.ticker, 'TSLA');
      expect(result.legs.length, 1);
      expect(result.legs[0].strike, 200.0);
      expect(result.legs[0].expiry, '2024-07-19');
      expect(result.legs[0].callOrPut, OptionType.put);
      expect(result.legs[0].action, BuyOrSell.sell);
      expect(result.legs[0].quantity, 3);
    });

    test('decode restores custom settings', () {
      final result = UrlStateService.decode({
        't': 'AAPL',
        'ir': '3.5',
        'dy': '0.7',
        'pr': '0.3',
        'ps': '60',
      });

      expect(result, isNotNull);
      expect(result!.settings.interestRate, 3.5);
      expect(result.settings.dividendYield, 0.7);
      expect(result.settings.priceRangePercent, 0.3);
      expect(result.settings.priceSteps, 60);
    });

    test('decode handles multiple legs', () {
      final result = UrlStateService.decode({
        't': 'SPY',
        'legs': '450.0:2024-06-21:C:B:1,440.0:2024-06-21:P:S:2',
      });

      expect(result!.legs.length, 2);
      expect(result.legs[0].strike, 450.0);
      expect(result.legs[0].callOrPut, OptionType.call);
      expect(result.legs[1].strike, 440.0);
      expect(result.legs[1].callOrPut, OptionType.put);
    });

    test('encode and decode round-trip', () {
      final settings = const CalculationSettings(interestRate: 5.0, dividendYield: 1.0);
      final legs = [
        SelectedLegParams(
          strike: 100,
          expiry: '2024-06-21',
          callOrPut: OptionType.call,
          action: BuyOrSell.buy,
          quantity: 1,
        ),
        SelectedLegParams(
          strike: 110,
          expiry: '2024-06-21',
          callOrPut: OptionType.call,
          action: BuyOrSell.sell,
          quantity: 1,
        ),
      ];

      final params = UrlStateService.encode(
        ticker: 'AAPL',
        legs: legs,
        settings: settings,
      );

      final decoded = UrlStateService.decode(params);
      expect(decoded, isNotNull);
      expect(decoded!.ticker, 'AAPL');
      expect(decoded.legs.length, 2);
      expect(decoded.settings.interestRate, 5.0);
      expect(decoded.settings.dividendYield, 1.0);
    });

    test('buildShareUrl produces valid URL', () {
      final url = UrlStateService.buildShareUrl(
        baseUrl: 'https://example.com/opc',
        ticker: 'AAPL',
        legs: [
          SelectedLegParams(
            strike: 150,
            expiry: '2024-06-21',
            callOrPut: OptionType.call,
            action: BuyOrSell.buy,
            quantity: 1,
          ),
        ],
        settings: const CalculationSettings(),
      );

      expect(url, contains('https://example.com/opc'));
      expect(url, contains('t=AAPL'));
      expect(url, contains('legs='));
    });
  });
}
