import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/colors.dart';
import '../../theme/animations.dart';
import '../../models/option.dart';
import '../../providers/options_provider.dart';
import '../../providers/calculation_provider.dart';
import '../settings/settings_sheet.dart';
import 'widgets/expiry_chips.dart';
import 'widgets/option_card.dart';
import 'widgets/selection_summary.dart';
import 'widgets/legs_panel.dart';

class OptionSelectionScreen extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const OptionSelectionScreen({super.key, required this.onNext, required this.onBack});

  @override
  ConsumerState<OptionSelectionScreen> createState() => _OptionSelectionScreenState();
}

class _OptionSelectionScreenState extends ConsumerState<OptionSelectionScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _showLegs = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleOption(Option option) {
    final notifier = ref.read(selectedOptionsProvider.notifier);
    final selected = ref.read(selectedOptionsProvider);
    final idx = selected.indexWhere((e) => e.option.optionMapKey == option.optionMapKey);
    if (idx >= 0) {
      notifier.remove(idx);
    } else {
      notifier.add(option, BuyOrSell.buy, quantity: 1);
    }
  }

  bool _isSelected(Option option) {
    final selected = ref.watch(selectedOptionsProvider);
    return selected.any((e) => e.option.optionMapKey == option.optionMapKey);
  }

  @override
  Widget build(BuildContext context) {
    final expirations = ref.watch(optionExpirationsProvider);
    final selectedExpiry = ref.watch(selectedExpirationProvider);
    final chain = ref.watch(optionChainProvider);
    final selectedEntries = ref.watch(selectedOptionsProvider);
    final selectedCount = selectedEntries.length;
    final strategy = ref.watch(detectedStrategyProvider);
    final netCost = selectedEntries.fold<double>(0.0, (sum, e) {
      final sign = e.action == BuyOrSell.buy ? -1 : 1;
      return sum + sign * e.option.premium * e.quantity;
    });

    return Column(
      children: [
        // Expiry chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: expirations.when(
                  data: (dates) => ExpiryChips(
                    expirations: dates,
                    selected: selectedExpiry,
                    onSelected: (d) => ref.read(selectedExpirationProvider.notifier).state = d,
                  ),
                  loading: () => const SizedBox(
                    height: 48,
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                  ),
                  error: (e, _) => Text('Error loading dates', style: TextStyle(color: AppColors.loss)),
                ),
              ),
              IconButton(
                onPressed: () => SettingsSheet.show(context),
                icon: const Icon(Icons.tune_rounded, color: AppColors.textSecondary, size: 22),
                tooltip: 'Calculation Settings',
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),

        // Strategy indicator
        if (strategy != null && selectedCount > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: GestureDetector(
              onTap: () => setState(() => _showLegs = !_showLegs),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _sentimentColor(strategy.sentiment).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _sentimentColor(strategy.sentiment).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _sentimentIcon(strategy.sentiment),
                      size: 14,
                      color: _sentimentColor(strategy.sentiment),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      strategy.name,
                      style: TextStyle(
                        color: _sentimentColor(strategy.sentiment),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _showLegs ? Icons.expand_less : Icons.expand_more,
                      size: 16,
                      color: _sentimentColor(strategy.sentiment),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: Anim.fast),
          ),

        // Legs panel (expandable)
        if (_showLegs && selectedCount > 0) const LegsPanel(),

        // Calls / Puts tabs
        TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'CALLS'),
            Tab(text: 'PUTS'),
          ],
        ),

        // Options list
        Expanded(
          child: selectedExpiry == null
              ? Center(
                  child: Text(
                    'Select an expiration date',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ).animate().fadeIn(duration: Anim.medium),
                )
              : chain.when(
                  data: (chainData) {
                    if (chainData == null) {
                      return Center(child: Text('No data', style: Theme.of(context).textTheme.bodyMedium));
                    }
                    final calls = chainData.callsForExpiry(selectedExpiry);
                    final puts = chainData.putsForExpiry(selectedExpiry);
                    return TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOptionList(calls),
                        _buildOptionList(puts),
                      ],
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
        ),

        // Bottom summary bar
        if (selectedCount > 0)
          SelectionSummary(
            selectedCount: selectedCount,
            netCost: netCost,
            strategyName: strategy?.name,
            onNext: widget.onNext,
          ).animate().slideY(begin: 1, end: 0, duration: Anim.fast, curve: Anim.snappy),
      ],
    );
  }

  Widget _buildOptionList(List<Option> options) {
    if (options.isEmpty) {
      return Center(child: Text('No options available', style: Theme.of(context).textTheme.bodyMedium));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: options.length,
      itemBuilder: (_, i) {
        final o = options[i];
        return OptionCard(
          option: o,
          isSelected: _isSelected(o),
          onTap: () => _toggleOption(o),
        ).animate().fadeIn(
          duration: Anim.fast,
          delay: Anim.staggerDelay(i, interval: const Duration(milliseconds: 30)),
        ).slideY(begin: 0.05, end: 0);
      },
    );
  }

  Color _sentimentColor(String sentiment) {
    switch (sentiment) {
      case 'bullish':
        return AppColors.profit;
      case 'bearish':
        return AppColors.loss;
      case 'volatile':
        return const Color(0xFFFF9800);
      default:
        return AppColors.primary;
    }
  }

  IconData _sentimentIcon(String sentiment) {
    switch (sentiment) {
      case 'bullish':
        return Icons.trending_up_rounded;
      case 'bearish':
        return Icons.trending_down_rounded;
      case 'volatile':
        return Icons.swap_vert_rounded;
      default:
        return Icons.horizontal_rule_rounded;
    }
  }
}
