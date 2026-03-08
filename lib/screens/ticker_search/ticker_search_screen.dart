import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/colors.dart';
import '../../theme/animations.dart';
import '../../models/ticker.dart';
import '../../providers/ticker_provider.dart';
import 'widgets/ticker_search_bar.dart';
import 'widgets/ticker_result_tile.dart';
import 'widgets/ticker_info_card.dart';

class TickerSearchScreen extends ConsumerStatefulWidget {
  final VoidCallback onNext;

  const TickerSearchScreen({super.key, required this.onNext});

  @override
  ConsumerState<TickerSearchScreen> createState() =>
      _TickerSearchScreenState();
}

class _TickerSearchScreenState extends ConsumerState<TickerSearchScreen> {
  final _controller = TextEditingController();
  List<TickerSearchResult> _results = [];
  Ticker? _selected;
  bool _loading = false;
  String? _error;
  Timer? _debounce;

  void _onSearch(String query) {
    _debounce?.cancel();
    setState(() => _error = null);
    if (query.length < 2) {
      setState(() {
        _results = [];
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final results = await ref.read(tickerSearchProvider(query).future);
        if (mounted) setState(() => _results = results);
      } catch (e) {
        if (mounted) setState(() => _error = 'Search failed. Try again.');
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    });
  }

  void _onSelect(TickerSearchResult result) async {
    _controller.text = result.symbol;
    setState(() {
      _results = [];
      _loading = true;
      _error = null;
    });
    try {
      final ticker =
          await ref.read(tickerQuoteProvider(result.symbol).future);
      // Wire into global state so other screens can access
      ref.read(selectedTickerSymbolProvider.notifier).state = result.symbol;
      if (mounted) setState(() => _selected = ticker);
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Could not load quote for ${result.symbol}');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Animated header area — shrinks when ticker is selected
          AnimatedAlign(
            duration: Anim.medium,
            curve: Anim.smooth,
            alignment:
                _selected != null ? Alignment.topCenter : Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title + subtitle: only show when no ticker selected
                AnimatedCrossFade(
                  duration: Anim.medium,
                  crossFadeState: _selected == null
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
                  firstChild: Column(
                    children: [
                      Text(
                        'Search a Ticker',
                        style: Theme.of(context).textTheme.headlineLarge,
                      )
                          .animate()
                          .fadeIn(duration: Anim.medium)
                          .slideY(begin: -0.2, end: 0),
                      const SizedBox(height: 8),
                      Text(
                        'Start by finding a stock or ETF',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ).animate().fadeIn(duration: Anim.medium, delay: 100.ms),
                      const SizedBox(height: 32),
                    ],
                  ),
                  secondChild: const SizedBox(height: 24),
                ),
                TickerSearchBar(
                  controller: _controller,
                  onChanged: _onSearch,
                  loading: _loading,
                ),
              ],
            ),
          ),

          // Error message
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.loss, fontSize: 13),
              ),
            ).animate().fadeIn(duration: Anim.fast).shake(hz: 2, offset: const Offset(4, 0)),

          // Search results list
          if (_results.isNotEmpty)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 8),
                itemCount: _results.length,
                itemBuilder: (_, i) => TickerResultTile(
                  result: _results[i],
                  onTap: () => _onSelect(_results[i]),
                )
                    .animate()
                    .fadeIn(
                      duration: Anim.fast,
                      delay: Anim.staggerDelay(i),
                    )
                    .slideX(begin: 0.05, end: 0),
              ),
            ),

          // Selected ticker info + next button
          if (_selected != null) ...[
            const SizedBox(height: 16),
            TickerInfoCard(ticker: _selected!)
                .animate()
                .fadeIn(duration: Anim.medium)
                .slideY(begin: 0.1, end: 0),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.onNext,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Select Options'),
              ),
            )
                .animate()
                .scale(
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1, 1),
                    duration: Anim.fast,
                    curve: Anim.snappy)
                .fadeIn(duration: Anim.fast),
          ],

          if (_results.isEmpty && _selected == null) const Spacer(),
        ],
      ),
    );
  }
}
