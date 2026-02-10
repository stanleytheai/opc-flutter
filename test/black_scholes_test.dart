import 'package:flutter_test/flutter_test.dart';
import 'package:opc_flutter/services/black_scholes.dart';

void main() {
  group('NORMSDIST', () {
    test('z=0 returns 0.5', () {
      expect(normsDist(0), closeTo(0.5, 1e-6));
    });

    test('z=1 returns ~0.8413', () {
      expect(normsDist(1), closeTo(0.8413, 1e-3));
    });

    test('z=-1 returns ~0.1587', () {
      expect(normsDist(-1), closeTo(0.1587, 1e-3));
    });

    test('z=2 returns ~0.9772', () {
      expect(normsDist(2), closeTo(0.9772, 1e-3));
    });
  });

  group('erf', () {
    test('erf(0) ≈ 0', () {
      expect(erf(0), closeTo(0, 1e-6));
    });

    test('erf(1) ≈ 0.8427', () {
      expect(erf(1), closeTo(0.8427, 1e-3));
    });
  });

  group('Black-Scholes Call Premium', () {
    test('ATM call has reasonable premium', () {
      // Stock=100, rate=5%, strike=100, 30 days, vol=30%, div=0%
      final premium = calculateCallPremium(100, 5, 100, 30, 30, 0);
      // Should be roughly $3-5 for an ATM 30-day option with 30% vol
      expect(premium, greaterThan(2));
      expect(premium, lessThan(6));
    });

    test('deep ITM call ≈ intrinsic + time value', () {
      final premium = calculateCallPremium(110, 5, 100, 30, 30, 0);
      expect(premium, greaterThan(10)); // at least intrinsic
    });

    test('deep OTM call is small', () {
      final premium = calculateCallPremium(90, 5, 100, 30, 30, 0);
      expect(premium, lessThan(1));
    });
  });

  group('Black-Scholes Put Premium', () {
    test('ATM put has reasonable premium', () {
      final premium = calculatePutPremium(100, 5, 100, 30, 30, 0);
      expect(premium, greaterThan(2));
      expect(premium, lessThan(6));
    });

    test('deep ITM put ≈ intrinsic + time value', () {
      final premium = calculatePutPremium(90, 5, 100, 30, 30, 0);
      expect(premium, greaterThan(10));
    });
  });

  group('Put-Call Parity', () {
    test('C - P ≈ S*exp(-qT) - K*exp(-rT)', () {
      const s = 100.0, k = 100.0, r = 5.0, t = 90.0, v = 25.0, q = 1.0;
      final call = calculateCallPremium(s, r, k, t, v, q);
      final put = calculatePutPremium(s, r, k, t, v, q);
      final tYears = t / 365;
      final expected =
          s * _exp(-q / 100 * tYears) - k * _exp(-r / 100 * tYears);
      expect(call - put, closeTo(expected, 0.01));
    });
  });
}

double _exp(double x) {
  // dart:math exp
  return 2.718281828459045 * 0 + _realExp(x);
}

double _realExp(double x) {
  double result = 1.0;
  double term = 1.0;
  for (int i = 1; i < 100; i++) {
    term *= x / i;
    result += term;
  }
  return result;
}
