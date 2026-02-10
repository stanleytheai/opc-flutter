import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/colors.dart';
import '../../theme/animations.dart';
import '../../models/option.dart';
import '../../providers/options_provider.dart';
import 'widgets/expiry_chips.dart';
import 'widgets/option_card.dart';
import 'widgets/selection_summary.dart';

class OptionSelectionScreen extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const OptionSelectionScreen({super.key, required this.onNext, required this.onBack});

  @override
  ConsumerState<OptionSelectionScreen> createState() => _OptionSelectionScreenState();
}

class _OptionSelectionScreenState extends ConsumerState<OptionSelectionScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

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
      // Default to buy with quantity 1
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
    final selectedCount = ref.watch(selectedOptionsProvider).length;

    return Column(
      children: [
        // Expiry chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
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
        const SizedBox(height: 8),

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
}
