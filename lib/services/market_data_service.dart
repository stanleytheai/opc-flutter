import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/ticker.dart';
import '../models/option.dart';

class MarketDataService {
  static const _baseUrl = 'https://sandbox.tradier.com/v1/markets';
  static const _token = 'Bearer vhelrOcGiNAYi6XnpM3z4IU93oi4';

  /// CORS proxies to try in order (web only).
  static const _corsProxies = [
    'https://corsproxy.io/?',
    'https://api.allorigins.win/raw?url=',
  ];

  final http.Client _client;
  final Map<String, dynamic> _cache = {};

  MarketDataService({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> get _headers => {
        'Authorization': _token,
        'Accept': 'application/json',
      };

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final key = uri.toString();
    if (_cache.containsKey(key)) return _cache[key] as Map<String, dynamic>;

    if (!kIsWeb) {
      // Direct call for non-web platforms
      final response = await _client.get(uri, headers: _headers);
      if (response.statusCode != 200) {
        throw Exception('API error: ${response.statusCode}');
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      _cache[key] = json;
      return json;
    }

    // Web: try CORS proxies in order
    Exception? lastError;
    for (final proxy in _corsProxies) {
      try {
        final proxyUrl =
            Uri.parse('$proxy${Uri.encodeComponent(uri.toString())}');
        final response = await _client.get(proxyUrl, headers: _headers);
        if (response.statusCode == 200) {
          final json = jsonDecode(response.body) as Map<String, dynamic>;
          _cache[key] = json;
          return json;
        }
        lastError = Exception('HTTP ${response.statusCode}');
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
      }
    }

    // All proxies failed — try direct (may work if CORS headers are present)
    try {
      final response = await _client.get(uri, headers: _headers);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        _cache[key] = json;
        return json;
      }
    } catch (_) {}

    throw lastError ?? Exception('All CORS proxies failed');
  }

  Future<List<TickerSearchResult>> searchTickers(String query) async {
    final json = await _getJson(
      Uri.parse('$_baseUrl/lookup').replace(queryParameters: {
        'q': query,
        'exchanges': 'Q,N',
      }),
    );
    if (json['securities'] == null) return [];
    var securities = json['securities']['security'];
    if (securities is! List) securities = [securities];
    return securities
        .map((s) =>
            TickerSearchResult.fromTradierJson(s as Map<String, dynamic>))
        .toList();
  }

  Future<Ticker> getQuote(String symbol) async {
    final json = await _getJson(
      Uri.parse('$_baseUrl/quotes').replace(queryParameters: {
        'symbols': symbol,
        'greeks': 'true',
      }),
    );
    return Ticker.fromTradierJson(json['quotes']['quote']);
  }

  Future<List<String>> getOptionExpirations(String symbol) async {
    final json = await _getJson(
      Uri.parse('$_baseUrl/options/expirations').replace(queryParameters: {
        'symbol': symbol,
      }),
    );
    if (json['expirations'] == null) return [];
    final dates = json['expirations']['date'];
    if (dates is List) return dates.cast<String>();
    return [dates.toString()];
  }

  Future<List<Option>> getOptionChain(String symbol, String expiry) async {
    final json = await _getJson(
      Uri.parse('$_baseUrl/options/chains').replace(queryParameters: {
        'symbol': symbol,
        'expiration': expiry,
        'greeks': 'true',
      }),
    );
    if (json['options'] == null) return [];
    final options = json['options']['option'] as List;
    return options
        .map((o) => Option.fromTradierJson(o as Map<String, dynamic>))
        .toList();
  }

  Future<List<double>> getOptionStrikes(String symbol, String expiry) async {
    final json = await _getJson(
      Uri.parse('$_baseUrl/options/strikes').replace(queryParameters: {
        'symbol': symbol,
        'expiration': expiry,
      }),
    );
    if (json['strikes'] == null) return [];
    final strikes = json['strikes']['strike'] as List;
    return strikes.map((s) => (s as num).toDouble()).toList().reversed.toList();
  }
}
