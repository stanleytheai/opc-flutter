import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/settings.dart';

class SettingsNotifier extends StateNotifier<CalculationSettings> {
  SettingsNotifier() : super(const CalculationSettings());

  void updateInterestRate(double rate) =>
      state = state.copyWith(interestRate: rate);

  void updateDividendYield(double yield_) =>
      state = state.copyWith(dividendYield: yield_);

  void updatePriceRangePercent(double pct) =>
      state = state.copyWith(priceRangePercent: pct);

  void updatePriceSteps(int steps) =>
      state = state.copyWith(priceSteps: steps);

  void reset() => state = const CalculationSettings();

  void setAll(CalculationSettings settings) => state = settings;
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, CalculationSettings>(
  (ref) => SettingsNotifier(),
);
