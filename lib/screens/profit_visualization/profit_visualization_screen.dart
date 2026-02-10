import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/colors.dart';
import '../../theme/animations.dart';
import '../../providers/ticker_provider.dart';
import '../../providers/calculation_provider.dart';
import 'widgets/heatmap_grid.dart';
import 'widgets/profit_detail_card.dart';

class ProfitVisualizationScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const ProfitVisualizationScreen({super.key, required this.onBack});

  @override
  ConsumerState<ProfitVisualizationScreen> createState() => _ProfitVisualizationScreenState();
}

class _ProfitVisualizationScreenState extends ConsumerState<ProfitVisualizationScreen> {
  int? _selectedRow;
  int? _selectedCol;

  @override
  Widget build(BuildContext context) {
    final profitTable = ref.watch(profitTableProvider);

    return profitTable.when(
      data: (table) {
        return Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Text('Profit & Loss', style: Theme.of(context).textTheme.headlineMedium),
                  const Spacer(),
                  IconButton(
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.edit_rounded, color: AppColors.textSecondary, size: 20),
                    tooltip: 'Edit options',
                  ),
                ],
              ),
            ).animate().fadeIn(duration: Anim.medium),

            // Heatmap
            Expanded(
              child: HeatmapGrid(
                table: table,
                selectedRow: _selectedRow,
                selectedCol: _selectedCol,
                onCellTap: (row, col) {
                  setState(() {
                    _selectedRow = row;
                    _selectedCol = col;
                  });
                },
              ),
            ),

            // Detail card
            if (_selectedRow != null && _selectedCol != null)
              ProfitDetailCard(
                table: table,
                row: _selectedRow!,
                col: _selectedCol!,
                onClose: () => setState(() {
                  _selectedRow = null;
                  _selectedCol = null;
                }),
              )
                  .animate()
                  .fadeIn(duration: Anim.fast)
                  .slideY(begin: 0.2, end: 0, curve: Anim.snappy),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.loss, size: 48),
            const SizedBox(height: 12),
            Text('Error calculating profits', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('$e', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
