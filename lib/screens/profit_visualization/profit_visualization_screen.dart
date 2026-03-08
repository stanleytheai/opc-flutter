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
  ConsumerState<ProfitVisualizationScreen> createState() =>
      _ProfitVisualizationScreenState();
}

class _ProfitVisualizationScreenState
    extends ConsumerState<ProfitVisualizationScreen> {
  int? _selectedRow;
  int? _selectedCol;

  void _shareLink() {
    final ticker = ref.read(selectedTickerSymbolProvider);
    final entries = ref.read(selectedOptionsProvider);
    final settings = ref.read(settingsProvider);

    final legs = entries
        .map((e) => SelectedLegParams(
              strike: e.option.strike,
              expiry: e.option.expiry,
              callOrPut: e.option.callOrPut,
              action: e.action,
              quantity: e.quantity,
            ))
        .toList();

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
    final tickerAsync = ref.watch(selectedTickerProvider);
    final selectedEntries = ref.watch(selectedOptionsProvider);

    return profitTable.when(
      data: (table) {
        if (table == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.show_chart_rounded,
                    size: 48, color: AppColors.textMuted),
                const SizedBox(height: 12),
                Text('Select options to see profit visualization',
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          );
        }
        return Column(
          children: [
            // Header bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Profit & Loss',
                            style: Theme.of(context).textTheme.headlineMedium),
                        if (strategy != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _sentimentColor(strategy.sentiment),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  strategy.name,
                                  style: TextStyle(
                                    color: _sentimentColor(strategy.sentiment),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  _headerButton(Icons.tune_rounded, 'Settings',
                      () => SettingsSheet.show(context)),
                  _headerButton(
                      Icons.share_rounded, 'Share link', _shareLink),
                  _headerButton(
                      Icons.edit_rounded, 'Edit options', widget.onBack),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: Anim.medium)
                .slideY(begin: -0.1, end: 0),

            // Summary bar
            if (summary != null)
              ProfitSummaryBar(summary: summary)
                  .animate()
                  .fadeIn(duration: Anim.medium, delay: 80.ms)
                  .slideY(begin: -0.05, end: 0),

            // Legend
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  _legendDot(AppColors.loss, 'Loss'),
                  const SizedBox(width: 16),
                  _legendDot(const Color(0xFF455A64), 'Breakeven'),
                  const SizedBox(width: 16),
                  _legendDot(AppColors.profit, 'Profit'),
                  const Spacer(),
                  Text(
                    'X: Date  Y: Stock Price',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),

            // Heatmap (hero section)
            Expanded(
              child: HeatmapGrid(
                table: table,
                selectedRow: _selectedRow,
                selectedCol: _selectedCol,
                currentPrice: tickerAsync.valueOrNull?.lastPrice,
                onCellTap: (row, col) {
                  setState(() {
                    if (_selectedRow == row && _selectedCol == col) {
                      // Tapping same cell deselects
                      _selectedRow = null;
                      _selectedCol = null;
                    } else {
                      _selectedRow = row;
                      _selectedCol = col;
                    }
                  });
                },
              ),
            ),

            // Detail card (slides up when cell selected)
            AnimatedSize(
              duration: Anim.fast,
              curve: Anim.snappy,
              child: _selectedRow != null && _selectedCol != null
                  ? ProfitDetailCard(
                      table: table,
                      row: _selectedRow!,
                      col: _selectedCol!,
                      selectedOptions: selectedEntries,
                      onClose: () => setState(() {
                        _selectedRow = null;
                        _selectedCol = null;
                      }),
                    )
                      .animate()
                      .fadeIn(duration: Anim.fast)
                      .slideY(
                          begin: 0.15, end: 0, curve: Anim.snappy)
                  : const SizedBox.shrink(),
            ),
          ],
        );
      },
      loading: () => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text('Calculating P&L...',
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.loss, size: 48),
            const SizedBox(height: 12),
            Text('Error calculating profits',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('$e', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _headerButton(IconData icon, String tooltip, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: AppColors.textSecondary, size: 20),
      tooltip: tooltip,
      splashRadius: 20,
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
        ),
      ],
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
