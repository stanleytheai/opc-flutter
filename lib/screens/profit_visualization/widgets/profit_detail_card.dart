import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../../../models/option.dart';
import '../../../models/profit_table.dart';
import '../../../providers/options_provider.dart';
import '../../../services/black_scholes.dart';

class ProfitDetailCard extends StatelessWidget {
  final ProfitTable table;
  final int row;
  final int col;
  final List<SelectedOptionEntry> selectedOptions;
  final VoidCallback onClose;

  const ProfitDetailCard({
    super.key,
    required this.table,
    required this.row,
    required this.col,
    this.selectedOptions = const [],
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final price = table.prices[row];
    final date = table.dates[col];
    final pnl = table.values[row][col];
    final isProfit = pnl >= 0;
    final color = isProfit ? AppColors.profit : AppColors.loss;
    final sign = isProfit ? '+' : '';

    // Compute per-leg P&L
    final legPnLs = _computePerLegPnL(price, date);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text('Position Detail', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              GestureDetector(
                onTap: onClose,
                child: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _item(context, 'Date', date),
              _item(context, 'Stock Price', '\$${price.toStringAsFixed(2)}'),
              _item(context, 'Total P&L', '$sign\$${pnl.toStringAsFixed(2)}', valueColor: color),
            ],
          ),
          // Per-leg breakdown
          if (legPnLs.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 12),
            ...legPnLs.map((leg) {
              final legSign = leg.pnl >= 0 ? '+' : '';
              final legColor = leg.pnl >= 0 ? AppColors.profit : AppColors.loss;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: leg.isBuy
                            ? AppColors.profit.withValues(alpha: 0.12)
                            : AppColors.loss.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        leg.isBuy ? 'BUY' : 'SELL',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: leg.isBuy ? AppColors.profit : AppColors.loss,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '\$${leg.strike.toStringAsFixed(0)} ${leg.type}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (leg.quantity > 1) ...[
                      const SizedBox(width: 4),
                      Text(
                        '×${leg.quantity}',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      '$legSign\$${leg.pnl.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: legColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  List<_LegPnL> _computePerLegPnL(double stockPrice, String date) {
    if (selectedOptions.isEmpty) return [];

    final evalDate = DateTime.parse(date);
    final results = <_LegPnL>[];

    for (final sel in selectedOptions) {
      final opt = sel.option;
      final expiryDate = DateTime.parse(opt.expiry);
      final daysToExpiry = expiryDate.difference(evalDate).inDays.toDouble();

      double hypotheticalPremium;
      if (daysToExpiry <= 0) {
        if (opt.callOrPut == OptionType.call) {
          hypotheticalPremium = (stockPrice - opt.strike).clamp(0, double.infinity) * 100;
        } else {
          hypotheticalPremium = (opt.strike - stockPrice).clamp(0, double.infinity) * 100;
        }
      } else {
        final perShare = opt.callOrPut == OptionType.call
            ? calculateCallPremium(stockPrice, 4.0, opt.strike, daysToExpiry, opt.impliedVolatility, 0.0)
            : calculatePutPremium(stockPrice, 4.0, opt.strike, daysToExpiry, opt.impliedVolatility, 0.0);
        hypotheticalPremium = perShare * 100;
      }

      final entryCost = opt.premium;
      double legPnL;
      if (sel.action == BuyOrSell.buy) {
        legPnL = hypotheticalPremium - entryCost;
      } else {
        legPnL = entryCost - hypotheticalPremium;
      }
      legPnL *= sel.quantity;

      results.add(_LegPnL(
        strike: opt.strike,
        type: opt.callOrPut == OptionType.call ? 'Call' : 'Put',
        isBuy: sel.action == BuyOrSell.buy,
        quantity: sel.quantity,
        pnl: legPnL,
      ));
    }

    return results;
  }

  Widget _item(BuildContext context, String label, String value, {Color? valueColor}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegPnL {
  final double strike;
  final String type;
  final bool isBuy;
  final int quantity;
  final double pnl;

  const _LegPnL({
    required this.strike,
    required this.type,
    required this.isBuy,
    required this.quantity,
    required this.pnl,
  });
}
