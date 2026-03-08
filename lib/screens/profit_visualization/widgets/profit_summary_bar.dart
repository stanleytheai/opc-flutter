import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../../../providers/calculation_provider.dart';

class ProfitSummaryBar extends StatelessWidget {
  final ProfitSummary summary;

  const ProfitSummaryBar({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _stat(
            'Max Profit',
            summary.maxProfit >= 0
                ? '+\$${summary.maxProfit.toStringAsFixed(0)}'
                : '-\$${summary.maxProfit.abs().toStringAsFixed(0)}',
            AppColors.profit,
          ),
          _divider(),
          _stat(
            'Max Loss',
            summary.maxLoss >= 0
                ? '+\$${summary.maxLoss.toStringAsFixed(0)}'
                : '-\$${summary.maxLoss.abs().toStringAsFixed(0)}',
            AppColors.loss,
          ),
          _divider(),
          _stat(
            'Breakeven',
            summary.breakevenPrices.isEmpty
                ? 'N/A'
                : summary.breakevenPrices
                    .map((p) => '\$${p.toStringAsFixed(2)}')
                    .join(', '),
            AppColors.primaryLight,
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, Color valueColor) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: AppColors.border,
    );
  }
}
