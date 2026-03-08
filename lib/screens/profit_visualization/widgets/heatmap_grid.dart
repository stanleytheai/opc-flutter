import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/colors.dart';
import '../../../models/profit_table.dart';
import '../../../widgets/gradient_cell.dart';

class HeatmapGrid extends StatelessWidget {
  final ProfitTable table;
  final int? selectedRow;
  final int? selectedCol;
  final void Function(int row, int col) onCellTap;

  const HeatmapGrid({
    super.key,
    required this.table,
    this.selectedRow,
    this.selectedCol,
    required this.onCellTap,
  });

  @override
  Widget build(BuildContext context) {
    final rows = table.prices.length;
    final cols = table.dates.length;

    if (rows == 0 || cols == 0) {
      return const Center(child: Text('No data'));
    }

    // Find max absolute profit for scaling
    double maxAbs = 1;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final v = table.values[r][c].abs();
        if (v > maxAbs) maxAbs = v;
      }
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Date headers
          Row(
            children: [
              const SizedBox(width: 64), // price label space
              ...List.generate(cols, (c) {
                return Expanded(
                  child: Center(
                    child: Text(
                      table.dates[c],
                      style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 4),

          // Grid — fade in as one unit (avoids per-cell stagger jank on large grids)
          Expanded(
            child: ListView.builder(
              itemCount: rows,
              itemBuilder: (_, r) {
                final isBreakeven = _isBreakevenRow(r, cols);
                return SizedBox(
                  height: 36,
                  child: Row(
                    children: [
                      // Price label
                      SizedBox(
                        width: 64,
                        child: Text(
                          '\$${table.prices[r].toStringAsFixed(0)}',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 11,
                            color: isBreakeven ? AppColors.primaryLight : AppColors.textSecondary,
                            fontWeight: isBreakeven ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      ...List.generate(cols, (c) {
                        final value = table.values[r][c];
                        final pct = (value / maxAbs * 100).clamp(-100.0, 100.0);
                        final isSelected = r == selectedRow && c == selectedCol;

                        return Expanded(
                          child: GestureDetector(
                            onTap: () => onCellTap(r, c),
                            child: GradientCell(
                              profitPercent: pct,
                              value: value,
                              isSelected: isSelected,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ).animate().fadeIn(duration: const Duration(milliseconds: 300)),
          ),
        ],
      ),
    );
  }

  /// Check if this row contains a sign change (breakeven)
  bool _isBreakevenRow(int r, int cols) {
    if (r == 0) return false;
    for (int c = 0; c < cols; c++) {
      final prev = table.values[r - 1][c];
      final curr = table.values[r][c];
      if ((prev <= 0 && curr >= 0) || (prev >= 0 && curr <= 0)) return true;
    }
    return false;
  }
}
