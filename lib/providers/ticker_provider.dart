import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ticker.dart';
import '../services/market_data_service.dart';

final marketDataServiceProvider = Provider<MarketDataService>((ref) {
  return MarketDataService();
});

final tickerSearchQueryProvider = StateProvider<String>((ref) => '');

final tickerSearchResultsProvider =
    FutureProvider<List<TickerSearchResult>>((ref) async {
  final query = ref.watch(tickerSearchQueryProvider);
  if (query.length < 2) return [];
  final service = ref.read(marketDataServiceProvider);
  return service.searchTickers(query);
});

final selectedTickerSymbolProvider = StateProvider<String?>((ref) => null);

/// Family provider for one-off ticker search (used by search screen).
final tickerSearchProvider =
    FutureProvider.family<List<TickerSearchResult>, String>((ref, query) async {
  if (query.length < 2) return [];
  final service = ref.read(marketDataServiceProvider);
  return service.searchTickers(query);
});

/// Family provider for one-off quote lookup.
final tickerQuoteProvider =
    FutureProvider.family<Ticker, String>((ref, symbol) async {
  final service = ref.read(marketDataServiceProvider);
  return service.getQuote(symbol);
});

final selectedTickerProvider = FutureProvider<Ticker?>((ref) async {
  final symbol = ref.watch(selectedTickerSymbolProvider);
  if (symbol == null) return null;
  final service = ref.read(marketDataServiceProvider);
  return service.getQuote(symbol);
});
