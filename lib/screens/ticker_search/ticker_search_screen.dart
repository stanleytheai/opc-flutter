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
  ConsumerState<TickerSearchScreen> createState() => _TickerSearchScreenState();
}

class _TickerSearchScreenState extends ConsumerState<TickerSearchScreen> {
  final _controller = TextEditingController();
  List<TickerSearchResult> _results = [];
  Ticker? _selected;
  bool _loading = false;

  void _onSearch(String query) async {
    if (query.length < 1) {
      setState(() => _results = []);
      return;
    }
    setState(() => _loading = true);
    try {
      final results = await ref.read(tickerSearchProvider(query).future);
      if (mounted) setState(() => _results = results);
    } catch (_) {
      // Handled by provider
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSelect(TickerSearchResult result) async {
    _controller.text = result.symbol;
    setState(() {
      _results = [];
      _loading = true;
    });
    try {
      final ticker = await ref.read(tickerQuoteProvider(result.symbol).future);
      if (mounted) setState(() => _selected = ticker);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          AnimatedAlign(
            duration: Anim.medium,
            curve: Anim.smooth,
            alignment: _selected != null ? Alignment.topCenter : Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_selected == null) ...[
                  Text(
                    'Search a Ticker',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ).animate().fadeIn(duration: Anim.medium).slideY(begin: -0.2, end: 0),
                  const SizedBox(height: 8),
                  Text(
                    'Start by finding a stock or ETF',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ).animate().fadeIn(duration: Anim.medium, delay: 100.ms),
                  const SizedBox(height: 32),
                ],
                if (_selected != null) const SizedBox(height: 24),
                TickerSearchBar(
                  controller: _controller,
                  onChanged: _onSearch,
                  loading: _loading,
                ),
              ],
            ),
          ),
          if (_results.isNotEmpty)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 8),
                itemCount: _results.length,
                itemBuilder: (_, i) => TickerResultTile(
                  result: _results[i],
                  onTap: () => _onSelect(_results[i]),
                ).animate().fadeIn(
                  duration: Anim.fast,
                  delay: Anim.staggerDelay(i),
                ).slideX(begin: 0.05, end: 0),
              ),
            ),
          if (_selected != null) ...[
            const SizedBox(height: 16),
            TickerInfoCard(ticker: _selected!)
                .animate()
                .fadeIn(duration: Anim.medium)
                .slideY(begin: 0.1, end: 0),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: widget.onNext,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Select Options'),
            )
                .animate()
                .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), duration: Anim.fast, curve: Anim.snappy)
                .fadeIn(duration: Anim.fast),
          ],
          if (_results.isEmpty && _selected == null)
            const Spacer(),
        ],
      ),
    );
  }
}
