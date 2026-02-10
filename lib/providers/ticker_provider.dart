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

final selectedTickerProvider = FutureProvider<Ticker?>((ref) async {
  final symbol = ref.watch(selectedTickerSymbolProvider);
  if (symbol == null) return null;
  final service = ref.read(marketDataServiceProvider);
  return service.getQuote(symbol);
});
