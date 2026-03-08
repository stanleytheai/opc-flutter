import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/colors.dart';
import '../theme/animations.dart';
import '../providers/ticker_provider.dart';

/// Persistent ticker header shown across all wizard steps after ticker selection.
class TickerHeader extends ConsumerStatefulWidget {
  const TickerHeader({super.key});

  @override
  ConsumerState<TickerHeader> createState() => _TickerHeaderState();
}

class _TickerHeaderState extends ConsumerState<TickerHeader> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final symbol = ref.watch(selectedTickerSymbolProvider);
    final tickerAsync = ref.watch(selectedTickerProvider);

    if (symbol == null) return const SizedBox.shrink();

    return tickerAsync.when(
      data: (ticker) {
        if (ticker == null) return const SizedBox.shrink();
        final isPositive = ticker.change >= 0;
        final changeColor = isPositive ? AppColors.profit : AppColors.loss;
        final sign = isPositive ? '+' : '';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(
              bottom: BorderSide(color: AppColors.border, width: 0.5),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    Text(
                      ticker.symbol,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '\$${ticker.lastPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: changeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$sign${ticker.changePercent.toStringAsFixed(2)}%',
                        style: TextStyle(
                          color: changeColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                  ],
                ),
              ),
              AnimatedCrossFade(
                duration: Anim.fast,
                crossFadeState: _expanded
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                firstChild: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      _detail('Change',
                          '$sign${ticker.change.toStringAsFixed(2)}',
                          changeColor),
                      const SizedBox(width: 20),
                      _detail('Change %',
                          '$sign${ticker.changePercent.toStringAsFixed(2)}%',
                          changeColor),
                      const SizedBox(width: 20),
                      _detail('Last',
                          '\$${ticker.lastPrice.toStringAsFixed(2)}',
                          AppColors.textPrimary),
                      const Spacer(),
                      Expanded(
                        child: Text(
                          ticker.description,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                secondChild: const SizedBox.shrink(),
              ),
            ],
          ),
        ).animate().fadeIn(duration: Anim.fast);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _detail(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
        Text(value,
            style: TextStyle(
                color: valueColor, fontWeight: FontWeight.w600, fontSize: 12)),
      ],
    );
  }
}
