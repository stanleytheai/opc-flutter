import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/colors.dart';
import '../../../theme/animations.dart';
import '../../../models/option.dart';
import '../../../providers/options_provider.dart';
import '../../../providers/calculation_provider.dart';

/// Professional selected options panel showing grouped legs with strategy detection.
class SelectedOptionsPanel extends ConsumerWidget {
  final VoidCallback onCalculate;

  const SelectedOptionsPanel({super.key, required this.onCalculate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(selectedOptionsProvider);
    final strategy = ref.watch(detectedStrategyProvider);

    if (entries.isEmpty) return const SizedBox.shrink();

    final netCost = entries.fold<double>(0.0, (sum, e) {
      final sign = e.action == BuyOrSell.buy ? -1 : 1;
      return sum + sign * e.option.premium * e.quantity;
    });
    final isDebit = netCost < 0;
    final costLabel = isDebit ? 'Net Debit' : 'Net Credit';
    final costColor = isDebit ? AppColors.loss : AppColors.profit;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Strategy header + net cost
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(
              children: [
                if (strategy != null) ...[
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _sentimentColor(strategy.sentiment),
                    ),
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
                  const SizedBox(width: 8),
                ],
                Text(
                  '${entries.length} leg${entries.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                Text(
                  '$costLabel: \$${netCost.abs().toStringAsFixed(0)}',
                  style: TextStyle(
                    color: costColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // Leg rows
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
            child: Column(
              children: List.generate(entries.length, (i) {
                final e = entries[i];
                return _LegRow(entry: e, index: i);
              }),
            ),
          ),

          // Calculate button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                onPressed: onCalculate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.show_chart_rounded, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Calculate P&L',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().slideY(begin: 0.3, end: 0, duration: Anim.fast, curve: Anim.snappy);
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
}

class _LegRow extends ConsumerWidget {
  final SelectedOptionEntry entry;
  final int index;

  const _LegRow({required this.entry, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opt = entry.option;
    final isBuy = entry.action == BuyOrSell.buy;
    final typeStr = opt.callOrPut == OptionType.call ? 'C' : 'P';

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          // Buy/Sell badge
          GestureDetector(
            onTap: () =>
                ref.read(selectedOptionsProvider.notifier).toggleAction(index),
            child: Container(
              width: 36,
              padding: const EdgeInsets.symmetric(vertical: 3),
              decoration: BoxDecoration(
                color: isBuy
                    ? AppColors.profit.withValues(alpha: 0.12)
                    : AppColors.loss.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.center,
              child: Text(
                isBuy ? 'BUY' : 'SELL',
                style: TextStyle(
                  color: isBuy ? AppColors.profit : AppColors.loss,
                  fontWeight: FontWeight.w700,
                  fontSize: 9,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Expiry
          SizedBox(
            width: 52,
            child: Text(
              _shortExpiry(opt.expiry),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ),

          // Strike + Type
          SizedBox(
            width: 64,
            child: Text(
              '\$${opt.strike.toStringAsFixed(opt.strike == opt.strike.roundToDouble() ? 0 : 2)} $typeStr',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),

          // Quantity controls
          GestureDetector(
            onTap: () {
              if (entry.quantity > 1) {
                ref
                    .read(selectedOptionsProvider.notifier)
                    .updateQuantity(index, entry.quantity - 1);
              }
            },
            child: const Icon(Icons.remove, size: 14, color: AppColors.textMuted),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              '×${entry.quantity}',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => ref
                .read(selectedOptionsProvider.notifier)
                .updateQuantity(index, entry.quantity + 1),
            child: const Icon(Icons.add, size: 14, color: AppColors.textMuted),
          ),
          const Spacer(),

          // Remove (X icon)
          GestureDetector(
            onTap: () =>
                ref.read(selectedOptionsProvider.notifier).remove(index),
            child: const Icon(Icons.close_rounded,
                size: 16, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  String _shortExpiry(String expiry) {
    try {
      final parts = expiry.split('-');
      if (parts.length != 3) return expiry;
      final months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[int.parse(parts[1])]} ${int.parse(parts[2])}';
    } catch (_) {
      return expiry;
    }
  }
}
