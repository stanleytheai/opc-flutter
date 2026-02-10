enum OptionType { call, put }

extension OptionTypeCode on OptionType {
  String get code => this == OptionType.call ? 'C' : 'P';

  static OptionType fromCode(String code) =>
      code.toUpperCase() == 'C' ? OptionType.call : OptionType.put;
}

enum BuyOrSell { buy, sell }

extension BuyOrSellCode on BuyOrSell {
  String get code => this == BuyOrSell.buy ? 'B' : 'S';
}

class Option {
  final String symbol;
  final String ticker;
  final double strike;
  final String expiry;
  final double bid;
  final double ask;
  final double last;
  final double impliedVolatility;
  final int openInterest;
  final OptionType callOrPut;
  final double? delta;
  final double? gamma;
  final double? vega;
  final double? theta;
  final double? underlyingStockPrice;
  BuyOrSell? buyOrSell;
  int quantity;

  Option({
    this.symbol = '',
    this.ticker = '',
    required this.strike,
    required this.expiry,
    this.bid = 0,
    this.ask = 0,
    this.last = 0,
    this.impliedVolatility = 0,
    this.openInterest = 0,
    required this.callOrPut,
    this.delta,
    this.gamma,
    this.vega,
    this.theta,
    this.underlyingStockPrice,
    this.buyOrSell,
    this.quantity = 1,
  });

  /// Midpoint of bid/ask × 100 (one contract = 100 shares)
  double get premium =>
      double.parse((((bid + ask) / 2) * 100).toStringAsFixed(2));

  /// Midpoint of bid/ask per share
  double get premiumPerShare =>
      double.parse(((bid + ask) / 2).toStringAsFixed(2));

  /// Cost: negative for buy, positive for sell (per-share)
  double cost(BuyOrSell action) {
    final abs = ((bid + ask) / 2).abs();
    return action == BuyOrSell.buy ? -abs : abs;
  }

  String get optionMapKey => '$expiry:$strike:${callOrPut.code}';

  factory Option.fromTradierJson(Map<String, dynamic> json) {
    final greeks = json['greeks'] as Map<String, dynamic>?;
    return Option(
      symbol: json['symbol'] ?? '',
      ticker: json['underlying'] ?? json['root_symbol'] ?? '',
      strike: (json['strike'] ?? 0).toDouble(),
      expiry: json['expiration_date'] ?? '',
      bid: (json['bid'] ?? 0).toDouble(),
      ask: (json['ask'] ?? 0).toDouble(),
      last: (json['last'] ?? 0).toDouble(),
      impliedVolatility: greeks != null
          ? (double.tryParse(greeks['smv_vol']?.toString() ?? '0') ?? 0) * 100
          : 0,
      openInterest: (json['open_interest'] ?? 0).toInt(),
      callOrPut: (json['option_type'] ?? 'call') == 'call'
          ? OptionType.call
          : OptionType.put,
      delta: greeks != null
          ? double.tryParse(greeks['delta']?.toString() ?? '')
          : null,
      gamma: greeks != null
          ? double.tryParse(greeks['gamma']?.toString() ?? '')
          : null,
      vega: greeks != null
          ? double.tryParse(greeks['vega']?.toString() ?? '')
          : null,
      theta: greeks != null
          ? double.tryParse(greeks['theta']?.toString() ?? '')
          : null,
    );
  }
}

class HypotheticalOption {
  final Option originalOption;
  double hypotheticalPremium;
  final double timeToMaturity; // days until expiration
  final int multiplier; // number of contracts (negative for sell)

  HypotheticalOption({
    required this.originalOption,
    this.hypotheticalPremium = 0,
    required this.timeToMaturity,
    this.multiplier = 1,
  });

  /// Profit for this hypothetical vs the original premium
  double get profit {
    final buyOrSell = originalOption.buyOrSell;
    if (buyOrSell == BuyOrSell.sell || multiplier < 0) {
      return originalOption.premium - hypotheticalPremium;
    } else {
      return hypotheticalPremium - originalOption.premium;
    }
  }

  /// Profit × multiplier
  double get totalProfit => profit * multiplier.abs();
}
