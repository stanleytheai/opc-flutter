import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/option.dart';
import '../models/option_chain.dart';
import 'ticker_provider.dart';

final selectedExpirationProvider = StateProvider<String?>((ref) => null);

final optionExpirationsProvider = FutureProvider<List<String>>((ref) async {
  final symbol = ref.watch(selectedTickerSymbolProvider);
  if (symbol == null) return [];
  final service = ref.read(marketDataServiceProvider);
  return service.getOptionExpirations(symbol);
});

final optionChainProvider = FutureProvider<OptionsChain?>((ref) async {
  final symbol = ref.watch(selectedTickerSymbolProvider);
  final expiry = ref.watch(selectedExpirationProvider);
  if (symbol == null || expiry == null) return null;

  final service = ref.read(marketDataServiceProvider);
  final ticker = await ref.watch(selectedTickerProvider.future);
  final options = await service.getOptionChain(symbol, expiry);

  final map = <String, Option>{};
  for (final opt in options) {
    map[opt.optionMapKey] = opt;
  }

  final strikes = options.map((o) => o.strike).toSet().toList()..sort();

  return OptionsChain(
    underlyingStockPrice: ticker?.lastPrice ?? 0,
    expirations: [expiry],
    strikes: strikes,
    optionMap: map,
  );
});

/// User-selected options for the trade (legs).
class SelectedOptionsNotifier extends StateNotifier<List<SelectedOptionEntry>> {
  SelectedOptionsNotifier() : super([]);

  void add(Option option, BuyOrSell action, {int quantity = 1}) {
    state = [
      ...state,
      SelectedOptionEntry(option: option, action: action, quantity: quantity),
    ];
  }

  void remove(int index) {
    state = [...state]..removeAt(index);
  }

  void updateQuantity(int index, int quantity) {
    if (quantity < 1) return;
    final updated = [...state];
    updated[index] = updated[index].copyWith(quantity: quantity);
    state = updated;
  }

  void updateAction(int index, BuyOrSell action) {
    final updated = [...state];
    updated[index] = updated[index].copyWith(action: action);
    state = updated;
  }

  void toggleAction(int index) {
    final updated = [...state];
    final current = updated[index].action;
    updated[index] = updated[index].copyWith(
      action: current == BuyOrSell.buy ? BuyOrSell.sell : BuyOrSell.buy,
    );
    state = updated;
  }

  void clear() => state = [];
}

class SelectedOptionEntry {
  final Option option;
  final BuyOrSell action;
  final int quantity;

  SelectedOptionEntry({
    required this.option,
    required this.action,
    this.quantity = 1,
  });

  SelectedOptionEntry copyWith({
    Option? option,
    BuyOrSell? action,
    int? quantity,
  }) {
    return SelectedOptionEntry(
      option: option ?? this.option,
      action: action ?? this.action,
      quantity: quantity ?? this.quantity,
    );
  }
}

final selectedOptionsProvider =
    StateNotifierProvider<SelectedOptionsNotifier, List<SelectedOptionEntry>>(
  (ref) => SelectedOptionsNotifier(),
);
