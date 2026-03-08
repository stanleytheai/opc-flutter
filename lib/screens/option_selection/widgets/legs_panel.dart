import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/colors.dart';
import '../../../models/option.dart';
import '../../../providers/options_provider.dart';

/// Panel showing all selected option legs with edit controls.
class LegsPanel extends ConsumerWidget {
  const LegsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(selectedOptionsProvider);
    if (entries.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text(
                'Selected Legs',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => ref.read(selectedOptionsProvider.notifier).clear(),
                child: const Text(
                  'Clear All',
                  style: TextStyle(color: AppColors.loss, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...List.generate(entries.length, (i) {
            final entry = entries[i];
            return _LegRow(
              entry: entry,
              index: i,
            );
          }),
        ],
      ),
    );
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
    final typeStr = opt.callOrPut == OptionType.call ? 'Call' : 'Put';

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          // Buy/Sell toggle
          GestureDetector(
            onTap: () => ref.read(selectedOptionsProvider.notifier).toggleAction(index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isBuy
                    ? AppColors.profit.withValues(alpha: 0.15)
                    : AppColors.loss.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isBuy ? 'BUY' : 'SELL',
                style: TextStyle(
                  color: isBuy ? AppColors.profit : AppColors.loss,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Type + Strike
          Expanded(
            child: Text(
              '\$${opt.strike.toStringAsFixed(opt.strike == opt.strike.roundToDouble() ? 0 : 2)} $typeStr',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Expiry
          Text(
            opt.expiry,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
          const SizedBox(width: 8),

          // Quantity controls
          GestureDetector(
            onTap: () {
              if (entry.quantity > 1) {
                ref.read(selectedOptionsProvider.notifier).updateQuantity(index, entry.quantity - 1);
              }
            },
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.remove, size: 14, color: AppColors.textSecondary),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '${entry.quantity}',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              ref.read(selectedOptionsProvider.notifier).updateQuantity(index, entry.quantity + 1);
            },
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.add, size: 14, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 8),

          // Remove button
          GestureDetector(
            onTap: () => ref.read(selectedOptionsProvider.notifier).remove(index),
            child: const Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
