/// Integration tests that hit the real Tradier sandbox API.
/// Run with: flutter test test/integration/
///
/// These tests verify the actual API is accessible and returns
/// data in the expected format. They require network access.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:opc_flutter/models/option.dart';
import 'package:opc_flutter/services/market_data_service.dart';

void main() {
  late MarketDataService service;

  setUp(() {
    service = MarketDataService();
  });

  group('Tradier Sandbox API - Live', () {
    test('searchTickers returns results for AAPL', () async {
      final results = await service.searchTickers('AAPL');
      expect(results, isNotEmpty, reason: 'Should find AAPL');
      expect(
        results.any((r) => r.symbol == 'AAPL'),
        isTrue,
        reason: 'Should contain AAPL in results',
      );
      // Verify fields are populated
      final aapl = results.firstWhere((r) => r.symbol == 'AAPL');
      expect(aapl.description, isNotEmpty);
    });

    test('searchTickers returns empty for nonsense query', () async {
      final results = await service.searchTickers('ZZZZXQQQ');
      expect(results, isEmpty);
    });

    test('getQuote returns valid ticker data for AAPL', () async {
      final ticker = await service.getQuote('AAPL');
      expect(ticker.symbol, 'AAPL');
      expect(ticker.lastPrice, isNotNull);
      expect(ticker.lastPrice, greaterThan(0),
          reason: 'AAPL should have a positive price');
      expect(ticker.description, isNotEmpty);
    });

    test('getOptionExpirations returns future dates for AAPL', () async {
      final dates = await service.getOptionExpirations('AAPL');
      expect(dates, isNotEmpty,
          reason: 'AAPL should have option expirations');
      // Verify dates are valid format YYYY-MM-DD
      for (final date in dates) {
        expect(
          RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date),
          isTrue,
          reason: 'Date "$date" should be YYYY-MM-DD format',
        );
      }
    });

    test('getOptionChain returns options for AAPL', () async {
      // First get a valid expiration
      final expirations = await service.getOptionExpirations('AAPL');
      expect(expirations, isNotEmpty);

      final options = await service.getOptionChain('AAPL', expirations.first);
      expect(options, isNotEmpty,
          reason: 'Should have options for first expiry');

      // Verify option fields
      final opt = options.first;
      expect(opt.strike, greaterThan(0));
      expect(opt.expiry, expirations.first);
      expect(opt.bid, isNotNull);
      expect(opt.ask, isNotNull);
      // Should have both calls and puts
      final hasCall = options.any((o) => o.callOrPut == OptionType.call);
      final hasPut = options.any((o) => o.callOrPut == OptionType.put);
      expect(hasCall, isTrue, reason: 'Should have call options');
      expect(hasPut, isTrue, reason: 'Should have put options');
    });

    test('getOptionStrikes returns strikes for AAPL', () async {
      final expirations = await service.getOptionExpirations('AAPL');
      expect(expirations, isNotEmpty);

      final strikes =
          await service.getOptionStrikes('AAPL', expirations.first);
      expect(strikes, isNotEmpty);
      // Strikes should be in descending order (reversed)
      for (int i = 0; i < strikes.length - 1; i++) {
        expect(strikes[i], greaterThanOrEqualTo(strikes[i + 1]),
            reason: 'Strikes should be descending');
      }
    });

    test('full flow: search → quote → expirations → chain', () async {
      // Step 1: Search
      final searchResults = await service.searchTickers('MSFT');
      expect(searchResults, isNotEmpty);
      final symbol =
          searchResults.firstWhere((r) => r.symbol == 'MSFT').symbol;

      // Step 2: Quote
      final ticker = await service.getQuote(symbol);
      expect(ticker.lastPrice, greaterThan(0));

      // Step 3: Expirations
      final expirations = await service.getOptionExpirations(symbol);
      expect(expirations, isNotEmpty);

      // Step 4: Chain
      final options =
          await service.getOptionChain(symbol, expirations.first);
      expect(options, isNotEmpty);

      // Step 5: Verify we can calculate premium on at least one option
      final callOption = options.firstWhere((o) => o.callOrPut == OptionType.call);
      expect(callOption.premium, isNotNull);
      expect(callOption.premium, greaterThanOrEqualTo(0));
    });

    test('getQuote throws on invalid symbol', () async {
      expect(
        () async => await service.getQuote('ZZZZXQQQ123'),
        throwsA(isA<Exception>()),
      );
    });

    test('API error handling: malformed request', () async {
      expect(
        () => service.getOptionChain('', ''),
        throwsException,
      );
    });
  });
}
