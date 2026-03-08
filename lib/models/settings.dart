/// User-configurable calculation settings.
class CalculationSettings {
  final double interestRate; // annualized %
  final double dividendYield; // annualized %
  final double priceRangePercent; // e.g. 0.25 = ±25%
  final int priceSteps; // number of price points

  const CalculationSettings({
    this.interestRate = 4.0,
    this.dividendYield = 0.0,
    this.priceRangePercent = 0.25,
    this.priceSteps = 50,
  });

  CalculationSettings copyWith({
    double? interestRate,
    double? dividendYield,
    double? priceRangePercent,
    int? priceSteps,
  }) {
    return CalculationSettings(
      interestRate: interestRate ?? this.interestRate,
      dividendYield: dividendYield ?? this.dividendYield,
      priceRangePercent: priceRangePercent ?? this.priceRangePercent,
      priceSteps: priceSteps ?? this.priceSteps,
    );
  }

  /// Serialize to query parameter map.
  Map<String, String> toQueryParams() {
    final params = <String, String>{};
    if (interestRate != 4.0) params['ir'] = interestRate.toString();
    if (dividendYield != 0.0) params['dy'] = dividendYield.toString();
    if (priceRangePercent != 0.25) params['pr'] = priceRangePercent.toString();
    if (priceSteps != 50) params['ps'] = priceSteps.toString();
    return params;
  }

  /// Deserialize from query parameter map.
  factory CalculationSettings.fromQueryParams(Map<String, String> params) {
    return CalculationSettings(
      interestRate: double.tryParse(params['ir'] ?? '') ?? 4.0,
      dividendYield: double.tryParse(params['dy'] ?? '') ?? 0.0,
      priceRangePercent: double.tryParse(params['pr'] ?? '') ?? 0.25,
      priceSteps: int.tryParse(params['ps'] ?? '') ?? 50,
    );
  }
}
