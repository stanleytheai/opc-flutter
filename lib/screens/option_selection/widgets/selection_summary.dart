import 'package:flutter/material.dart';
import '../../../theme/colors.dart';

class SelectionSummary extends StatelessWidget {
  final int selectedCount;
  final double netCost;
  final String? strategyName;
  final VoidCallback onNext;

  const SelectionSummary({
    super.key,
    required this.selectedCount,
    required this.netCost,
    this.strategyName,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final isDebit = netCost < 0;
    final costLabel = isDebit ? 'Net Debit' : 'Net Credit';
    final costColor = isDebit ? AppColors.loss : AppColors.profit;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$selectedCount leg${selectedCount == 1 ? '' : 's'}',
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$costLabel: \$${netCost.abs().toStringAsFixed(0)}',
                      style: TextStyle(color: costColor, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ),
                if (strategyName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    strategyName!,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: onNext,
            icon: const Icon(Icons.show_chart_rounded, size: 20),
            label: const Text('Visualize'),
          ),
        ],
      ),
    );
  }
}
