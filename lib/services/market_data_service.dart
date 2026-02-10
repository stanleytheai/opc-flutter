import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ticker.dart';
import '../models/option.dart';
import '../models/option_chain.dart';

class MarketDataService {
  static const _baseUrl = 'https://sandbox.tradier.com/v1/markets';
  static const _token = 'Bearer vhelrOcGiNAYi6XnpM3z4IU93oi4';

  final http.Client _client;

  MarketDataService({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> get _headers => {
        'Authorization': _token,
        'Accept': 'application/json',
      };

  Future<List<TickerSearchResult>> searchTickers(String query) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/lookup').replace(queryParameters: {
        'q': query,
        'exchanges': 'Q,N',
      }),
      headers: _headers,
    );
    final json = jsonDecode(response.body);
    if (json['securities'] == null) return [];
    var securities = json['securities']['security'];
    if (securities is! List) securities = [securities];
    return (securities as List)
        .map((s) => TickerSearchResult.fromTradierJson(s))
        .toList();
  }

  Future<Ticker> getQuote(String symbol) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/quotes').replace(queryParameters: {
        'symbols': symbol,
        'greeks': 'true',
      }),
      headers: _headers,
    );
    final json = jsonDecode(response.body);
    return Ticker.fromTradierJson(json['quotes']['quote']);
  }

  Future<List<String>> getOptionExpirations(String symbol) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/options/expirations').replace(queryParameters: {
        'symbol': symbol,
      }),
      headers: _headers,
    );
    final json = jsonDecode(response.body);
    if (json['expirations'] == null) return [];
    final dates = json['expirations']['date'];
    if (dates is List) return dates.cast<String>();
    return [dates.toString()];
  }

  Future<List<Option>> getOptionChain(String symbol, String expiry) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/options/chains').replace(queryParameters: {
        'symbol': symbol,
        'expiration': expiry,
        'greeks': 'true',
      }),
      headers: _headers,
    );
    final json = jsonDecode(response.body);
    if (json['options'] == null) return [];
    final options = json['options']['option'] as List;
    return options
        .map((o) => Option.fromTradierJson(o as Map<String, dynamic>))
        .toList();
  }

  Future<List<double>> getOptionStrikes(String symbol, String expiry) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/options/strikes').replace(queryParameters: {
        'symbol': symbol,
        'expiration': expiry,
      }),
      headers: _headers,
    );
    final json = jsonDecode(response.body);
    if (json['strikes'] == null) return [];
    final strikes = json['strikes']['strike'] as List;
    return strikes.map((s) => (s as num).toDouble()).toList().reversed.toList();
  }
}
