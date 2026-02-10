import 'dart:math' as math;

/// A&S formula 7.1.26 error function approximation
double erf(double x) {
  const a1 = 0.254829592;
  const a2 = -0.284496736;
  const a3 = 1.421413741;
  const a4 = -1.453152027;
  const a5 = 1.061405429;
  const p = 0.3275911;

  final t = 1.0 / (1.0 + p * x.abs());
  return 1.0 -
      ((((a5 * t + a4) * t + a3) * t + a2) * t + a1) *
          t *
          math.exp(-1.0 * x.abs() * x.abs());
}

/// Standard normal cumulative distribution function
double normsDist(double z) {
  final sign = z < 0 ? -1.0 : 1.0;
  return 0.5 * (1.0 + sign * erf(z.abs() / math.sqrt(2)));
}

/// Black-Scholes call premium.
///
/// All rates/volatility/yield as percentages (e.g. 5 = 5%).
/// [timeToExpiration] in days.
double calculateCallPremium(
  double underlyingPrice,
  double interestRate,
  double strike,
  double timeToExpiration,
  double annualVolatility,
  double dividendYield,
) {
  final t = timeToExpiration / 365.0;
  final r = interestRate / 100.0;
  final q = dividendYield / 100.0;
  final sigma = annualVolatility / 100.0;

  final d1 = (math.log(underlyingPrice / strike) +
          (r - q + sigma * sigma / 2) * t) /
      (sigma * math.sqrt(t));
  final d2 = d1 - sigma * math.sqrt(t);

  return underlyingPrice * math.exp(-q * t) * normsDist(d1) -
      strike * math.exp(-r * t) * normsDist(d2);
}

/// Black-Scholes put premium.
///
/// Same parameter conventions as [calculateCallPremium].
double calculatePutPremium(
  double underlyingPrice,
  double interestRate,
  double strike,
  double timeToExpiration,
  double annualVolatility,
  double dividendYield,
) {
  final t = timeToExpiration / 365.0;
  final r = interestRate / 100.0;
  final q = dividendYield / 100.0;
  final sigma = annualVolatility / 100.0;

  final d1 = (math.log(underlyingPrice / strike) +
          (r - q + sigma * sigma / 2) * t) /
      (sigma * math.sqrt(t));
  final d2 = d1 - sigma * math.sqrt(t);

  return strike * math.exp(-r * t) * normsDist(-d2) -
      underlyingPrice * math.exp(-q * t) * normsDist(-d1);
}
