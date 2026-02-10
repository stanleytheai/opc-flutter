import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../../../models/profit_table.dart';

class ProfitDetailCard extends StatelessWidget {
  final ProfitTable table;
  final int row;
  final int col;
  final VoidCallback onClose;

  const ProfitDetailCard({
    super.key,
    required this.table,
    required this.row,
    required this.col,
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
        ],
      ),
    );
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
