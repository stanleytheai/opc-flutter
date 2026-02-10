import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:opc_flutter/services/market_data_service.dart';

void main() {
  group('MarketDataService', () {
    test('searchTickers parses results', () async {
      final client = MockClient((request) async {
        expect(request.url.path, contains('lookup'));
        return http.Response(
          jsonEncode({
            'securities': {
              'security': [
                {'symbol': 'AAPL', 'description': 'Apple Inc'},
                {'symbol': 'AAPX', 'description': 'Apple ETF'},
              ]
            }
          }),
          200,
        );
      });
      final service = MarketDataService(client: client);
      final results = await service.searchTickers('AAP');
      expect(results.length, 2);
      expect(results[0].symbol, 'AAPL');
      expect(results[1].description, 'Apple ETF');
    });

    test('searchTickers handles single result (non-list)', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'securities': {
              'security': {'symbol': 'AAPL', 'description': 'Apple Inc'}
            }
          }),
          200,
        );
      });
      final service = MarketDataService(client: client);
      final results = await service.searchTickers('AAPL');
      expect(results.length, 1);
      expect(results[0].symbol, 'AAPL');
    });

    test('searchTickers returns empty on null securities', () async {
      final client = MockClient((request) async {
        return http.Response(jsonEncode({'securities': null}), 200);
      });
      final service = MarketDataService(client: client);
      final results = await service.searchTickers('XYZ');
      expect(results, isEmpty);
    });

    test('getQuote parses ticker', () async {
      final client = MockClient((request) async {
        expect(request.url.path, contains('quotes'));
        return http.Response(
          jsonEncode({
            'quotes': {
              'quote': {
                'symbol': 'AAPL',
                'description': 'Apple Inc',
                'last': 185.50,
                'change': 2.30,
                'change_percentage': 1.25,
              }
            }
          }),
          200,
        );
      });
      final service = MarketDataService(client: client);
      final ticker = await service.getQuote('AAPL');
      expect(ticker.symbol, 'AAPL');
      expect(ticker.lastPrice, 185.50);
    });

    test('getOptionExpirations parses dates', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'expirations': {
              'date': ['2024-03-15', '2024-04-19', '2024-05-17']
            }
          }),
          200,
        );
      });
      final service = MarketDataService(client: client);
      final dates = await service.getOptionExpirations('AAPL');
      expect(dates.length, 3);
      expect(dates[0], '2024-03-15');
    });

    test('getOptionExpirations handles single date', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'expirations': {'date': '2024-03-15'}
          }),
          200,
        );
      });
      final service = MarketDataService(client: client);
      final dates = await service.getOptionExpirations('AAPL');
      expect(dates.length, 1);
    });

    test('getOptionExpirations returns empty on null', () async {
      final client = MockClient((request) async {
        return http.Response(jsonEncode({'expirations': null}), 200);
      });
      final service = MarketDataService(client: client);
      final dates = await service.getOptionExpirations('XYZ');
      expect(dates, isEmpty);
    });

    test('getOptionChain parses options', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'options': {
              'option': [
                {
                  'symbol': 'AAPL240315C00185000',
                  'underlying': 'AAPL',
                  'strike': 185.0,
                  'expiration_date': '2024-03-15',
                  'bid': 5.20,
                  'ask': 5.40,
                  'last': 5.30,
                  'open_interest': 1500,
                  'option_type': 'call',
                },
              ]
            }
          }),
          200,
        );
      });
      final service = MarketDataService(client: client);
      final options = await service.getOptionChain('AAPL', '2024-03-15');
      expect(options.length, 1);
      expect(options[0].strike, 185.0);
    });

    test('getOptionStrikes parses and reverses', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'strikes': {
              'strike': [180.0, 185.0, 190.0]
            }
          }),
          200,
        );
      });
      final service = MarketDataService(client: client);
      final strikes = await service.getOptionStrikes('AAPL', '2024-03-15');
      expect(strikes, [190.0, 185.0, 180.0]); // reversed
    });
  });
}
