import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/colors.dart';
import '../../theme/animations.dart';
import '../../providers/calculation_provider.dart';
import '../../providers/options_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/ticker_provider.dart';
import '../../services/url_state_service.dart';
import '../../screens/settings/settings_sheet.dart';
import 'widgets/heatmap_grid.dart';
import 'widgets/profit_detail_card.dart';
import 'widgets/profit_summary_bar.dart';

class ProfitVisualizationScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const ProfitVisualizationScreen({super.key, required this.onBack});

  @override
  ConsumerState<ProfitVisualizationScreen> createState() => _ProfitVisualizationScreenState();
}

class _ProfitVisualizationScreenState extends ConsumerState<ProfitVisualizationScreen> {
  int? _selectedRow;
  int? _selectedCol;

  void _shareLink() {
    final ticker = ref.read(selectedTickerSymbolProvider);
    final entries = ref.read(selectedOptionsProvider);
    final settings = ref.read(settingsProvider);

    final legs = entries.map((e) => SelectedLegParams(
      strike: e.option.strike,
      expiry: e.option.expiry,
      callOrPut: e.option.callOrPut,
      action: e.action,
      quantity: e.quantity,
    )).toList();

    final url = UrlStateService.buildShareUrl(
      baseUrl: Uri.base.origin + Uri.base.path,
      ticker: ticker,
      legs: legs,
      settings: settings,
    );

    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Link copied to clipboard'),
        backgroundColor: AppColors.surfaceLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profitTable = ref.watch(profitTableProvider);
    final strategy = ref.watch(detectedStrategyProvider);
    final summary = ref.watch(profitSummaryProvider);

    return profitTable.when(
      data: (table) {
        if (table == null) {
          return Center(
            child: Text('Select options to see profit visualization',
                style: Theme.of(context).textTheme.bodyMedium),
          );
        }
        return Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Profit & Loss', style: Theme.of(context).textTheme.headlineMedium),
                        if (strategy != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              strategy.name,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => SettingsSheet.show(context),
                    icon: const Icon(Icons.tune_rounded, color: AppColors.textSecondary, size: 20),
                    tooltip: 'Settings',
                  ),
                  IconButton(
                    onPressed: _shareLink,
                    icon: const Icon(Icons.share_rounded, color: AppColors.textSecondary, size: 20),
                    tooltip: 'Share link',
                  ),
                  IconButton(
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.edit_rounded, color: AppColors.textSecondary, size: 20),
                    tooltip: 'Edit options',
                  ),
                ],
              ),
            ).animate().fadeIn(duration: Anim.medium),

            // Profit summary bar
            if (summary != null)
              ProfitSummaryBar(summary: summary)
                  .animate()
                  .fadeIn(duration: Anim.medium, delay: 100.ms),

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
