import '../models/option.dart';
import '../models/settings.dart';

/// Encodes/decodes app state to/from URL query parameters for shareable links.
///
/// URL format:
///   ?t=AAPL&legs=strike:expiry:C|P:B|S:qty,...&ir=4&dy=0&pr=0.25&ps=50
class UrlStateService {
  /// Encode selected options and settings into query parameters.
  static Map<String, String> encode({
    required String? ticker,
    required List<SelectedLegParams> legs,
    required CalculationSettings settings,
  }) {
    final params = <String, String>{};

    if (ticker != null) params['t'] = ticker;

    if (legs.isNotEmpty) {
      final legStrings = legs.map((leg) {
        return '${leg.strike}:${leg.expiry}:${leg.callOrPut.code}:${leg.action.code}:${leg.quantity}';
      }).join(',');
      params['legs'] = legStrings;
    }

    params.addAll(settings.toQueryParams());
    return params;
  }

  /// Decode query parameters back into app state components.
  static DecodedUrlState? decode(Map<String, String> params) {
    final ticker = params['t'];
    if (ticker == null) return null;

    final legs = <SelectedLegParams>[];
    final legsStr = params['legs'];
    if (legsStr != null && legsStr.isNotEmpty) {
      for (final legStr in legsStr.split(',')) {
        final parts = legStr.split(':');
        if (parts.length >= 5) {
          legs.add(SelectedLegParams(
            strike: double.tryParse(parts[0]) ?? 0,
            expiry: parts[1],
            callOrPut: OptionTypeCode.fromCode(parts[2]),
            action: parts[3].toUpperCase() == 'B' ? BuyOrSell.buy : BuyOrSell.sell,
            quantity: int.tryParse(parts[4]) ?? 1,
          ));
        }
      }
    }

    final settings = CalculationSettings.fromQueryParams(params);

    return DecodedUrlState(
      ticker: ticker,
      legs: legs,
      settings: settings,
    );
  }

  /// Build a shareable URL string from current state.
  static String buildShareUrl({
    required String baseUrl,
    required String? ticker,
    required List<SelectedLegParams> legs,
    required CalculationSettings settings,
  }) {
    final params = encode(ticker: ticker, legs: legs, settings: settings);
    if (params.isEmpty) return baseUrl;
    final queryString = params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    return '$baseUrl?$queryString';
  }
}

/// Parameters for a single leg extracted from URL.
class SelectedLegParams {
  final double strike;
  final String expiry;
  final OptionType callOrPut;
  final BuyOrSell action;
  final int quantity;

  const SelectedLegParams({
    required this.strike,
    required this.expiry,
    required this.callOrPut,
    required this.action,
    this.quantity = 1,
  });
}

/// Decoded state from URL query parameters.
class DecodedUrlState {
  final String ticker;
  final List<SelectedLegParams> legs;
  final CalculationSettings settings;

  const DecodedUrlState({
    required this.ticker,
    this.legs = const [],
    required this.settings,
  });
}
