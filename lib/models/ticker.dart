class Ticker {
  final String symbol;
  final String description;
  final double lastPrice;
  final double change;
  final double changePercent;

  Ticker({
    required this.symbol,
    this.description = '',
    this.lastPrice = 0,
    this.change = 0,
    this.changePercent = 0,
  });

  factory Ticker.fromTradierJson(Map<String, dynamic> json) {
    return Ticker(
      symbol: json['symbol'] ?? '',
      description: json['description'] ?? '',
      lastPrice: (json['last'] ?? 0).toDouble(),
      change: (json['change'] ?? 0).toDouble(),
      changePercent: (json['change_percentage'] ?? 0).toDouble(),
    );
  }
}

class TickerSearchResult {
  final String symbol;
  final String description;

  TickerSearchResult({required this.symbol, this.description = ''});

  factory TickerSearchResult.fromTradierJson(Map<String, dynamic> json) {
    return TickerSearchResult(
      symbol: json['symbol'] ?? '',
      description: json['description'] ?? '',
    );
  }
}
