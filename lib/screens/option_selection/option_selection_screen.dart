import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/colors.dart';
import '../../theme/animations.dart';
import '../../models/option.dart';
import '../../providers/ticker_provider.dart';
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
  String? _selectedExpiry;
  final Set<String> _selectedKeys = {};

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
    setState(() {
      final key = option.optionMapKey;
      if (_selectedKeys.contains(key)) {
        _selectedKeys.remove(key);
      } else {
        _selectedKeys.add(key);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final expirations = ref.watch(expirationsProvider);
    final optionChain = _selectedExpiry != null ? ref.watch(optionChainProvider(_selectedExpiry!)) : null;

    return Column(
      children: [
        // Expiry chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: expirations.when(
            data: (dates) => ExpiryChips(
              expirations: dates,
              selected: _selectedExpiry,
              onSelected: (d) => setState(() => _selectedExpiry = d),
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
          child: optionChain == null
              ? Center(
                  child: Text(
                    'Select an expiration date',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ).animate().fadeIn(duration: Anim.medium),
                )
              : optionChain.when(
                  data: (chain) {
                    return TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOptionList(chain.where((o) => o.callOrPut == OptionType.call).toList()),
                        _buildOptionList(chain.where((o) => o.callOrPut == OptionType.put).toList()),
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
        if (_selectedKeys.isNotEmpty)
          SelectionSummary(
            selectedCount: _selectedKeys.length,
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
          isSelected: _selectedKeys.contains(o.optionMapKey),
          onTap: () => _toggleOption(o),
        ).animate().fadeIn(
          duration: Anim.fast,
          delay: Anim.staggerDelay(i, interval: const Duration(milliseconds: 30)),
        ).slideY(begin: 0.05, end: 0);
      },
    );
  }
}
