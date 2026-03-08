import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/colors.dart';
import '../../../models/profit_table.dart';

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
  final _priceLabelController = ScrollController();
  final _headerHorizontalController = ScrollController();
  final _gridHorizontalController = ScrollController();
  static const double _cellHeight = 38.0;
  static const double _cellWidth = 62.0;
  static const double _priceLabelWidth = 72.0;
  static const double _dateHeaderHeight = 32.0;
  static const double _cellGap = 1.5;
  static const double _cellRadius = 3.0;
  bool _syncingScroll = false;
  bool _didInitialScroll = false;

  @override
  void initState() {
    super.initState();
    _headerHorizontalController.addListener(_syncHeaderToGrid);
    _gridHorizontalController.addListener(_syncGridToHeader);
    _verticalController.addListener(_syncGridToPrice);
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

  void _syncGridToPrice() {
    if (_syncingScroll) return;
    _syncingScroll = true;
    if (_priceLabelController.hasClients) {
      _priceLabelController.jumpTo(_verticalController.offset);
    }
    _syncingScroll = false;
  }

  @override
  void dispose() {
    _verticalController.dispose();
    _priceLabelController.dispose();
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

  /// Scroll to center the current stock price row after initial build.
  void _scrollToCurrentPrice() {
    if (_didInitialScroll) return;
    _didInitialScroll = true;

    final priceRow = _currentPriceRow();
    if (priceRow == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_verticalController.hasClients) return;
      final viewHeight = _verticalController.position.viewportDimension;
      final targetOffset =
          (priceRow * _cellHeight - viewHeight / 2 + _cellHeight / 2)
              .clamp(0.0, _verticalController.position.maxScrollExtent);
      _verticalController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    });
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

    // Auto-scroll to current price on first build
    _scrollToCurrentPrice();

    return Padding(
      padding: const EdgeInsets.all(4),
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

          // Heatmap body
          Expanded(
            child: Row(
              children: [
                // Price labels column — synced vertically
                SizedBox(
                  width: _priceLabelWidth,
                  child: ListView.builder(
                    controller: _priceLabelController,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: rows,
                    itemExtent: _cellHeight,
                    itemBuilder: (_, r) {
                      final isCurrentPrice = r == currentPriceRow;
                      final isSelectedRow = r == widget.selectedRow;
                      return Container(
                        height: _cellHeight,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 6),
                        decoration: isCurrentPrice
                            ? BoxDecoration(
                                border: Border(
                                  right: BorderSide(
                                    color:
                                        AppColors.primary.withValues(alpha: 0.6),
                                    width: 2,
                                  ),
                                ),
                              )
                            : null,
                        child: Text(
                          '\$${widget.table.prices[r].toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isCurrentPrice
                                ? AppColors.primary
                                : isSelectedRow
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                            fontWeight: isCurrentPrice || isSelectedRow
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Grid cells — bi-directional scroll
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    controller: _gridHorizontalController,
                    child: SizedBox(
                      width: _cellWidth * cols,
                      child: ListView.builder(
                        controller: _verticalController,
                        itemCount: rows,
                        itemExtent: _cellHeight,
                        itemBuilder: (_, r) {
                          return SizedBox(
                            height: _cellHeight,
                            child: Row(
                              children: List.generate(cols, (c) {
                                final value = widget.table.values[r][c];
                                final pct =
                                    (value / maxAbs * 100).clamp(-100.0, 100.0);
                                final isSelected = r == widget.selectedRow &&
                                    c == widget.selectedCol;
                                final isCrosshair = !isSelected &&
                                    (r == widget.selectedRow ||
                                        c == widget.selectedCol);
                                final isCurrentPriceRow = r == currentPriceRow;

                                return GestureDetector(
                                  onTap: () => widget.onCellTap(r, c),
                                  child: _HeatmapCell(
                                    width: _cellWidth,
                                    height: _cellHeight,
                                    profitPercent: pct,
                                    value: value,
                                    isSelected: isSelected,
                                    isCrosshair: isCrosshair,
                                    isCurrentPrice:
                                        isCurrentPriceRow && !isSelected,
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
              ],
            ).animate().fadeIn(duration: const Duration(milliseconds: 400)),
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
}

/// Individual heatmap cell — lightweight widget with gradient color.
class _HeatmapCell extends StatelessWidget {
  final double width;
  final double height;
  final double profitPercent;
  final double value;
  final bool isSelected;
  final bool isCrosshair;
  final bool isCurrentPrice;

  const _HeatmapCell({
    required this.width,
    required this.height,
    required this.profitPercent,
    required this.value,
    this.isSelected = false,
    this.isCrosshair = false,
    this.isCurrentPrice = false,
  });

  @override
  Widget build(BuildContext context) {
    // Use the Angular-style gradient for a smooth red→white→green look
    final baseColor = AppColors.profitColor(profitPercent);
    final alpha = isSelected
        ? 1.0
        : isCrosshair
            ? 0.45
            : 0.82;

    return Container(
      width: width,
      height: height,
      margin: const EdgeInsets.all(0.75),
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: alpha),
        borderRadius: BorderRadius.circular(3),
        border: isSelected
            ? Border.all(color: Colors.white, width: 2)
            : isCurrentPrice
                ? Border.all(
                    color: AppColors.primary.withValues(alpha: 0.5), width: 1)
                : null,
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: baseColor.withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: isSelected
          ? Text(
              value >= 0
                  ? '+${value.toStringAsFixed(0)}'
                  : value.toStringAsFixed(0),
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
              ),
            )
          : null,
    );
  }
}
