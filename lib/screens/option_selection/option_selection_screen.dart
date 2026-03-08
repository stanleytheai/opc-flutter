import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/colors.dart';
import '../../theme/animations.dart';
import '../../models/option.dart';
import '../../models/option_chain.dart';
import '../../providers/options_provider.dart';
import '../../providers/ticker_provider.dart';
import '../../widgets/shimmer_loading.dart';
import 'widgets/expiry_tabs.dart';
import 'widgets/option_chain_row.dart';
import 'widgets/selected_options_panel.dart';

class OptionSelectionScreen extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const OptionSelectionScreen(
      {super.key, required this.onNext, required this.onBack});

  @override
  ConsumerState<OptionSelectionScreen> createState() =>
      _OptionSelectionScreenState();
}

class _OptionSelectionScreenState extends ConsumerState<OptionSelectionScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _addToPosition(Option option, BuyOrSell action) {
    final notifier = ref.read(selectedOptionsProvider.notifier);
    final selected = ref.read(selectedOptionsProvider);
    // Check if already selected
    final idx =
        selected.indexWhere((e) => e.option.optionMapKey == option.optionMapKey);
    if (idx >= 0) {
      // Toggle action if different, otherwise remove
      if (selected[idx].action != action) {
        notifier.updateAction(idx, action);
      } else {
        notifier.remove(idx);
      }
    } else {
      notifier.add(option, action, quantity: 1);
    }
  }

  void _toggleOption(Option option) {
    final notifier = ref.read(selectedOptionsProvider.notifier);
    final selected = ref.read(selectedOptionsProvider);
    final idx =
        selected.indexWhere((e) => e.option.optionMapKey == option.optionMapKey);
    if (idx >= 0) {
      notifier.remove(idx);
    } else {
      notifier.add(option, BuyOrSell.buy, quantity: 1);
    }
  }

  bool _isSelected(Option option) {
    return ref
        .watch(selectedOptionsProvider)
        .any((e) => e.option.optionMapKey == option.optionMapKey);
  }

  @override
  Widget build(BuildContext context) {
    final expirations = ref.watch(optionExpirationsProvider);
    final selectedExpiry = ref.watch(selectedExpirationProvider);
    final chain = ref.watch(optionChainProvider);
    final selectedEntries = ref.watch(selectedOptionsProvider);
    final tickerAsync = ref.watch(selectedTickerProvider);
    final currentPrice = tickerAsync.valueOrNull?.lastPrice;

    return Column(
      children: [
        // Calls / Strike / Puts header labels
        Container(
          height: 22,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text('CALLS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.profit.withValues(alpha: 0.6),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1)),
              ),
              const SizedBox(width: 72), // strike column space
              Expanded(
                child: Text('PUTS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.loss.withValues(alpha: 0.6),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1)),
              ),
            ],
          ),
        ),

        // Expiration tabs
        expirations.when(
          data: (dates) => ExpiryTabs(
            expirations: dates,
            selected: selectedExpiry,
            onSelected: (d) =>
                ref.read(selectedExpirationProvider.notifier).state = d,
          ),
          loading: () => const ShimmerLoading(height: 36),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(8),
            child: Text('Error loading dates',
                style: TextStyle(color: AppColors.loss, fontSize: 12)),
          ),
        ),

        // Column headers (Bid Ask Last OI Delta | Strike | Bid Ask Last OI Delta)
        const OptionChainHeader(),

        // Option chain list
        Expanded(
          child: selectedExpiry == null
              ? Center(
                  child: Text(
                    'Select an expiration date above',
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: 13),
                  ).animate().fadeIn(duration: Anim.medium),
                )
              : chain.when(
                  data: (chainData) {
                    if (chainData == null) {
                      return Center(
                          child: Text('No data',
                              style: TextStyle(
                                  color: AppColors.textMuted, fontSize: 13)));
                    }
                    return _buildUnifiedChain(
                        chainData, selectedExpiry, currentPrice);
                  },
                  loading: () => const ShimmerOptionList(),
                  error: (e, _) => Center(
                      child: Text('Error: $e',
                          style: const TextStyle(color: AppColors.loss))),
                ),
        ),

        // Selected options panel
        if (selectedEntries.isNotEmpty)
          SelectedOptionsPanel(onCalculate: widget.onNext),
      ],
    );
  }

  Widget _buildUnifiedChain(
      OptionsChain chainData, String expiry, double? currentPrice) {
    final strikes = chainData.strikes;
    // strikes are already sorted ascending; we want descending (high to low)
    final sortedStrikes = List<double>.from(strikes)..sort((a, b) => b.compareTo(a));

    // Find where to insert the price marker
    int priceMarkerIndex = -1;
    if (currentPrice != null) {
      for (int i = 0; i < sortedStrikes.length - 1; i++) {
        if (sortedStrikes[i] >= currentPrice &&
            sortedStrikes[i + 1] < currentPrice) {
          priceMarkerIndex = i + 1;
          break;
        }
      }
      // Edge cases
      if (priceMarkerIndex == -1) {
        if (sortedStrikes.isNotEmpty && currentPrice >= sortedStrikes.first) {
          priceMarkerIndex = 0;
        } else if (sortedStrikes.isNotEmpty &&
            currentPrice < sortedStrikes.last) {
          priceMarkerIndex = sortedStrikes.length;
        }
      }
    }

    // Total items = strikes + (1 if price marker)
    final hasMarker = priceMarkerIndex >= 0;
    final itemCount = sortedStrikes.length + (hasMarker ? 1 : 0);

    // Scroll to price marker on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (hasMarker && _scrollController.hasClients) {
        final targetOffset = priceMarkerIndex * 38.0 - 100;
        if (targetOffset > 0 &&
            _scrollController.position.pixels == 0) {
          _scrollController.animateTo(
            targetOffset,
            duration: Anim.medium,
            curve: Anim.smooth,
          );
        }
      }
    });

    return ListView.builder(
      controller: _scrollController,
      itemCount: itemCount,
      itemExtent: null,
      padding: EdgeInsets.zero,
      itemBuilder: (_, i) {
        // Price marker line
        if (hasMarker && i == priceMarkerIndex) {
          return PriceMarkerLine(price: currentPrice!);
        }

        // Adjust index if past marker
        final strikeIndex =
            hasMarker && i > priceMarkerIndex ? i - 1 : i;
        if (strikeIndex >= sortedStrikes.length) {
          return const SizedBox.shrink();
        }

        final strike = sortedStrikes[strikeIndex];
        final call = chainData.getOption(expiry, strike, OptionType.call);
        final put = chainData.getOption(expiry, strike, OptionType.put);

        // ITM: calls are ITM when strike < current price, puts when strike > current price
        final isITMCall =
            currentPrice != null ? strike < currentPrice : false;
        final isITMPut =
            currentPrice != null ? strike > currentPrice : false;

        return OptionChainRow(
          key: ValueKey(strike),
          call: call,
          put: put,
          strike: strike,
          isCallSelected: call != null && _isSelected(call),
          isPutSelected: put != null && _isSelected(put),
          isITMCall: isITMCall,
          isITMPut: isITMPut,
          onCallTap: call != null ? () => _toggleOption(call) : null,
          onPutTap: put != null ? () => _toggleOption(put) : null,
          onAddToPosition: _addToPosition,
        );
      },
    );
  }
}
