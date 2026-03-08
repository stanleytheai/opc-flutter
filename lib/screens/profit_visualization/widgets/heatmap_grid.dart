import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/colors.dart';
import '../../../models/profit_table.dart';
import '../../../widgets/gradient_cell.dart';

class HeatmapGrid extends StatefulWidget {
  final ProfitTable table;
  final int? selectedRow;
  final int? selectedCol;
  final double? currentPrice;
  final void Function(int row, int col) onCellTap;

  const HeatmapGrid({
    super.key,
    required this.table,
    this.selectedRow,
    this.selectedCol,
    this.currentPrice,
    required this.onCellTap,
  });

  @override
  State<HeatmapGrid> createState() => _HeatmapGridState();
}

class _HeatmapGridState extends State<HeatmapGrid> {
  final _verticalController = ScrollController();
  final _headerHorizontalController = ScrollController();
  final _gridHorizontalController = ScrollController();
  static const double _cellHeight = 36.0;
  static const double _cellWidth = 64.0;
  static const double _priceLabelWidth = 68.0;
  static const double _dateHeaderHeight = 28.0;
  bool _syncingScroll = false;

  @override
  void initState() {
    super.initState();
    _headerHorizontalController.addListener(_syncHeaderToGrid);
    _gridHorizontalController.addListener(_syncGridToHeader);
  }

  void _syncHeaderToGrid() {
    if (_syncingScroll) return;
    _syncingScroll = true;
    if (_gridHorizontalController.hasClients) {
      _gridHorizontalController.jumpTo(_headerHorizontalController.offset);
    }
    _syncingScroll = false;
  }

  void _syncGridToHeader() {
    if (_syncingScroll) return;
    _syncingScroll = true;
    if (_headerHorizontalController.hasClients) {
      _headerHorizontalController.jumpTo(_gridHorizontalController.offset);
    }
    _syncingScroll = false;
  }

  @override
  void dispose() {
    _verticalController.dispose();
    _headerHorizontalController.dispose();
    _gridHorizontalController.dispose();
    super.dispose();
  }

  /// Find the row index closest to the current stock price.
  int? _currentPriceRow() {
    if (widget.currentPrice == null) return null;
    final prices = widget.table.prices;
    if (prices.isEmpty) return null;
    int closest = 0;
    double minDiff = (prices[0] - widget.currentPrice!).abs();
    for (int i = 1; i < prices.length; i++) {
      final diff = (prices[i] - widget.currentPrice!).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = i;
      }
    }
    return closest;
  }

  /// Find the column index for today's date.
  int? _todayCol() {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final dates = widget.table.dates;
    for (int i = 0; i < dates.length; i++) {
      if (dates[i] == today) return i;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final rows = widget.table.prices.length;
    final cols = widget.table.dates.length;

    if (rows == 0 || cols == 0) {
      return const Center(child: Text('No data'));
    }

    // Find max absolute profit for scaling
    double maxAbs = 1;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final v = widget.table.values[r][c].abs();
        if (v > maxAbs) maxAbs = v;
      }
    }

    final currentPriceRow = _currentPriceRow();
    final todayCol = _todayCol();

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          // Date header row
          SizedBox(
            height: _dateHeaderHeight,
            child: Row(
              children: [
                const SizedBox(width: _priceLabelWidth),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _headerHorizontalController,
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(cols, (c) {
                        final shortDate = _formatDate(widget.table.dates[c]);
                        final isToday = c == todayCol;
                        final isSelectedCol = c == widget.selectedCol;
                        return SizedBox(
                          width: _cellWidth,
                          child: Center(
                            child: Text(
                              shortDate,
                              style: TextStyle(
                                fontSize: 10,
                                color: isToday
                                    ? AppColors.primaryLight
                                    : isSelectedCol
                                        ? AppColors.textPrimary
                                        : AppColors.textMuted,
                                fontWeight: isToday || isSelectedCol
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Scrollable heatmap grid
          Expanded(
            child: Row(
              children: [
                // Price labels column — synced vertically with grid
                SizedBox(
                  width: _priceLabelWidth,
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (n) => true,
                    child: ListView.builder(
                      controller: _verticalController,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: rows,
                      itemExtent: _cellHeight,
                      itemBuilder: (_, r) {
                        final isBreakeven = _isBreakevenRow(r, cols);
                        final isCurrentPrice = r == currentPriceRow;
                        final isSelectedRow = r == widget.selectedRow;
                        return SizedBox(
                          height: _cellHeight,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Text(
                                '\$${widget.table.prices[r].toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isCurrentPrice
                                      ? AppColors.primary
                                      : isBreakeven
                                          ? AppColors.primaryLight
                                          : isSelectedRow
                                              ? AppColors.textPrimary
                                              : AppColors.textSecondary,
                                  fontWeight: isCurrentPrice || isBreakeven || isSelectedRow
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Grid cells — scrolls both directions
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    controller: _gridHorizontalController,
                    child: SizedBox(
                      width: _cellWidth * cols,
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (notification is ScrollUpdateNotification &&
                              _verticalController.hasClients) {
                            _verticalController.jumpTo(notification.metrics.pixels);
                          }
                          return false;
                        },
                        child: ListView.builder(
                          itemCount: rows,
                          itemExtent: _cellHeight,
                          itemBuilder: (_, r) {
                            final isCurrentPriceRow = r == currentPriceRow;
                            return SizedBox(
                              height: _cellHeight,
                              child: Row(
                                children: List.generate(cols, (c) {
                                  final value = widget.table.values[r][c];
                                  final pct = (value / maxAbs * 100).clamp(-100.0, 100.0);
                                  final isSelected =
                                      r == widget.selectedRow && c == widget.selectedCol;
                                  final isCrosshair = !isSelected &&
                                      (r == widget.selectedRow || c == widget.selectedCol);

                                  return SizedBox(
                                    width: _cellWidth,
                                    child: GestureDetector(
                                      onTap: () => widget.onCellTap(r, c),
                                      child: GradientCell(
                                        profitPercent: pct,
                                        value: value,
                                        isSelected: isSelected,
                                        isCrosshair: isCrosshair,
                                        isCurrentPrice: isCurrentPriceRow && !isSelected,
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(duration: const Duration(milliseconds: 300)),
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final parts = isoDate.split('-');
      if (parts.length >= 3) {
        return '${parts[1]}/${parts[2]}';
      }
    } catch (_) {}
    return isoDate;
  }

  bool _isBreakevenRow(int r, int cols) {
    if (r == 0) return false;
    for (int c = 0; c < cols; c++) {
      final prev = widget.table.values[r - 1][c];
      final curr = widget.table.values[r][c];
      if ((prev <= 0 && curr >= 0) || (prev >= 0 && curr <= 0)) return true;
    }
    return false;
  }
}
