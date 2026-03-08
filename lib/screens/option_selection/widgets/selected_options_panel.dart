import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/colors.dart';
import '../../../theme/animations.dart';
import '../../../models/option.dart';
import '../../../providers/options_provider.dart';
import '../../../providers/calculation_provider.dart';
import '../../../services/strategy_detector.dart';

/// Draggable bottom panel for selected options.
/// Collapsed: shows strategy name / leg count + net cost + drag handle.
/// Expanded: full strategy breakdown, leg details, greeks summary, P&L button.
class SelectedOptionsPanel extends ConsumerStatefulWidget {
  final VoidCallback onCalculate;

  const SelectedOptionsPanel({super.key, required this.onCalculate});

  @override
  ConsumerState<SelectedOptionsPanel> createState() =>
      _SelectedOptionsPanelState();
}

class _SelectedOptionsPanelState extends ConsumerState<SelectedOptionsPanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
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

    return GestureDetector(
      onVerticalDragUpdate: (details) {
        // Drag up to expand, drag down to collapse
        if (details.primaryDelta != null) {
          if (details.primaryDelta! < -8 && !_expanded) {
            setState(() => _expanded = true);
          } else if (details.primaryDelta! > 8 && _expanded) {
            setState(() => _expanded = false);
          }
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(
            top: BorderSide(color: AppColors.border, width: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 8, bottom: 4),
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Collapsed header — always visible
            _CollapsedHeader(
              strategy: strategy,
              legCount: entries.length,
              costLabel: costLabel,
              netCost: netCost,
              costColor: costColor,
              expanded: _expanded,
              onTap: () => setState(() => _expanded = !_expanded),
            ),

            // Expanded content
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox(width: double.infinity, height: 0),
              secondChild: _ExpandedContent(
                entries: entries,
                strategy: strategy,
                netCost: netCost,
              ),
            ),

            // Calculate P&L button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: widget.onCalculate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                    padding: EdgeInsets.zero,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.show_chart_rounded, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Calculate P&L',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().slideY(
        begin: 0.3, end: 0, duration: Anim.fast, curve: Anim.snappy);
  }
}

/// Always-visible collapsed header showing strategy + cost.
class _CollapsedHeader extends StatelessWidget {
  final DetectedStrategy? strategy;
  final int legCount;
  final String costLabel;
  final double netCost;
  final Color costColor;
  final bool expanded;
  final VoidCallback onTap;

  const _CollapsedHeader({
    required this.strategy,
    required this.legCount,
    required this.costLabel,
    required this.netCost,
    required this.costColor,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Row(
          children: [
            // Strategy indicator
            if (strategy != null) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _sentimentColor(strategy!.sentiment)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _sentimentColor(strategy!.sentiment),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      strategy!.name,
                      style: TextStyle(
                        color: _sentimentColor(strategy!.sentiment),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              '$legCount leg${legCount == 1 ? '' : 's'}',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
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
            const SizedBox(width: 8),
            AnimatedRotation(
              turns: expanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(Icons.keyboard_arrow_up_rounded,
                  size: 20, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
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
}

/// Expanded view with strategy description, individual legs, and greeks.
class _ExpandedContent extends ConsumerWidget {
  final List<SelectedOptionEntry> entries;
  final DetectedStrategy? strategy;
  final double netCost;

  const _ExpandedContent({
    required this.entries,
    required this.strategy,
    required this.netCost,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Compute aggregate greeks
    double totalDelta = 0, totalTheta = 0, totalGamma = 0;
    for (final e in entries) {
      final sign = e.action == BuyOrSell.buy ? 1.0 : -1.0;
      final mult = sign * e.quantity;
      totalDelta += (e.option.delta ?? 0) * mult * 100;
      totalTheta += (e.option.theta ?? 0) * mult * 100;
      totalGamma += (e.option.gamma ?? 0) * mult * 100;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Strategy description
          if (strategy != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _strategyDescription(strategy!),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _InfoChip(
                        label: 'Outlook',
                        value: strategy!.sentiment.toUpperCase(),
                        color: _sentimentColor(strategy!.sentiment),
                      ),
                      const SizedBox(width: 8),
                      _InfoChip(
                        label: 'Risk',
                        value: _riskLevel(strategy!),
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Aggregate Greeks row
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _GreekValue(label: 'Δ Delta', value: totalDelta),
                _GreekValue(label: 'Θ Theta', value: totalTheta),
                _GreekValue(label: 'Γ Gamma', value: totalGamma),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Individual legs
          ...List.generate(entries.length, (i) {
            return _DetailedLegRow(entry: entries[i], index: i);
          }),
        ],
      ),
    );
  }

  String _strategyDescription(DetectedStrategy strategy) {
    switch (strategy.name) {
      case 'Long Call':
        return 'Bullish bet. Profit if stock rises above strike + premium paid. Max loss is the premium.';
      case 'Short Call':
        return 'Neutral/bearish. Collect premium; max profit if stock stays below strike. Unlimited risk above strike.';
      case 'Long Put':
        return 'Bearish bet. Profit if stock drops below strike − premium. Max loss is the premium.';
      case 'Short Put':
        return 'Neutral/bullish. Collect premium; risk assignment if stock drops below strike.';
      case 'Long Straddle':
        return 'Volatility play. Profit from large move in either direction. Lose both premiums if stock stays flat.';
      case 'Short Straddle':
        return 'Betting on low volatility. Collect premiums; risk large moves in either direction.';
      case 'Long Strangle':
        return 'Cheaper volatility play. Needs a bigger move than a straddle to profit.';
      case 'Bull Call Spread':
        return 'Moderately bullish. Capped profit and capped loss. Lower cost than a naked long call.';
      case 'Bear Put Spread':
        return 'Moderately bearish. Capped profit and capped loss. Lower cost than a naked long put.';
      case 'Bear Call Spread':
        return 'Moderately bearish. Collect net credit; max risk is the spread width minus credit.';
      case 'Bull Put Spread':
        return 'Moderately bullish. Collect net credit; max risk is the spread width minus credit.';
      case 'Iron Condor':
        return 'Range-bound strategy. Profit if stock stays between short strikes. Limited risk on both sides.';
      case 'Iron Butterfly':
        return 'Like an iron condor but with same short strikes. Higher max profit, narrower profit zone.';
      case 'Calendar Spread':
        return 'Time decay play. Profit from near-term theta decay while holding longer-dated protection.';
      case 'Long Call Butterfly':
        return 'Precise target strategy. Max profit at the middle strike at expiry. Limited risk.';
      default:
        return 'Custom ${entries.length}-leg position.';
    }
  }

  String _riskLevel(DetectedStrategy strategy) {
    switch (strategy.name) {
      case 'Short Call':
      case 'Short Straddle':
        return 'HIGH';
      case 'Long Call':
      case 'Long Put':
      case 'Long Straddle':
      case 'Long Strangle':
        return 'MEDIUM';
      default:
        return 'DEFINED';
    }
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

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
        ),
        Text(
          value,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w700, fontSize: 10),
        ),
      ],
    );
  }
}

class _GreekValue extends StatelessWidget {
  final String label;
  final double value;

  const _GreekValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final color = value > 0
        ? AppColors.profit
        : value < 0
            ? AppColors.loss
            : AppColors.textMuted;
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 9,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(
          value.toStringAsFixed(2),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _DetailedLegRow extends ConsumerWidget {
  final SelectedOptionEntry entry;
  final int index;

  const _DetailedLegRow({required this.entry, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opt = entry.option;
    final isBuy = entry.action == BuyOrSell.buy;
    final typeStr = opt.callOrPut == OptionType.call ? 'Call' : 'Put';
    final premium = opt.premium;
    final legCost = (isBuy ? -1 : 1) * premium * entry.quantity;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: (isBuy ? AppColors.profit : AppColors.loss)
              .withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Buy/Sell badge
          GestureDetector(
            onTap: () => ref
                .read(selectedOptionsProvider.notifier)
                .toggleAction(index),
            child: Container(
              width: 38,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: isBuy
                    ? AppColors.profit.withValues(alpha: 0.15)
                    : AppColors.loss.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.center,
              child: Text(
                isBuy ? 'BUY' : 'SELL',
                style: TextStyle(
                  color: isBuy ? AppColors.profit : AppColors.loss,
                  fontWeight: FontWeight.w800,
                  fontSize: 9,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Option details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '\$${opt.strike.toStringAsFixed(opt.strike == opt.strike.roundToDouble() ? 0 : 2)} $typeStr',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _shortExpiry(opt.expiry),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      'Bid ${opt.bid.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 10),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Ask ${opt.ask.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 10),
                    ),
                    if (opt.delta != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        'Δ ${opt.delta!.toStringAsFixed(3)}',
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 10),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Quantity controls
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _QtyButton(
                icon: Icons.remove,
                onTap: entry.quantity > 1
                    ? () => ref
                        .read(selectedOptionsProvider.notifier)
                        .updateQuantity(index, entry.quantity - 1)
                    : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '×${entry.quantity}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              _QtyButton(
                icon: Icons.add,
                onTap: () => ref
                    .read(selectedOptionsProvider.notifier)
                    .updateQuantity(index, entry.quantity + 1),
              ),
            ],
          ),
          const SizedBox(width: 8),

          // Cost for this leg
          SizedBox(
            width: 56,
            child: Text(
              '${legCost >= 0 ? '+' : ''}\$${legCost.abs().toStringAsFixed(0)}',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: legCost >= 0 ? AppColors.profit : AppColors.loss,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),

          const SizedBox(width: 6),

          // Remove
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
      const months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[int.parse(parts[1])]} ${int.parse(parts[2])}';
    } catch (_) {
      return expiry;
    }
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _QtyButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          icon,
          size: 14,
          color: onTap != null ? AppColors.textSecondary : AppColors.textMuted,
        ),
      ),
    );
  }
}
