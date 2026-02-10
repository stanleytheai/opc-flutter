import 'option.dart';

class OptionsChain {
  final double underlyingStockPrice;
  final List<String> expirations;
  final List<double> strikes;
  final Map<String, Option> optionMap;

  OptionsChain({
    required this.underlyingStockPrice,
    this.expirations = const [],
    this.strikes = const [],
    Map<String, Option>? optionMap,
  }) : optionMap = optionMap ?? {};

  /// Key format: "expiry:strike:C|P"
  static String generateKey(String expiry, double strike, OptionType type) =>
      '$expiry:$strike:${type.code}';

  Option? getOption(String expiry, double strike, OptionType type) =>
      optionMap[generateKey(expiry, strike, type)];

  List<Option> callsForExpiry(String expiry) => optionMap.values
      .where((o) => o.expiry == expiry && o.callOrPut == OptionType.call)
      .toList()
    ..sort((a, b) => b.strike.compareTo(a.strike));

  List<Option> putsForExpiry(String expiry) => optionMap.values
      .where((o) => o.expiry == expiry && o.callOrPut == OptionType.put)
      .toList()
    ..sort((a, b) => b.strike.compareTo(a.strike));
}
