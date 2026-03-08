import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../theme/colors.dart';
import '../../../models/option.dart';

/// A single row in the unified option chain: call data | strike | put data.
class OptionChainRow extends StatelessWidget {
  final Option? call;
  final Option? put;
  final double strike;
  final bool isCallSelected;
  final bool isPutSelected;
  final bool isITMCall;
  final bool isITMPut;
  final VoidCallback? onCallTap;
  final VoidCallback? onPutTap;
  final void Function(Option option, BuyOrSell action)? onAddToPosition;

  const OptionChainRow({
    super.key,
    this.call,
    this.put,
    required this.strike,
    this.isCallSelected = false,
    this.isPutSelected = false,
    this.isITMCall = false,
    this.isITMPut = false,
    this.onCallTap,
    this.onPutTap,
    this.onAddToPosition,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Call side
          Expanded(
            child: _buildSide(
              option: call,
              isSelected: isCallSelected,
              isITM: isITMCall,
              onTap: onCallTap,
              isCall: true,
            ),
          ),
          // Strike price center column
          Container(
            width: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight.withValues(alpha: 0.5),
              border: Border.symmetric(
                vertical: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.4),
                  width: 0.5,
                ),
              ),
            ),
            child: Text(
              strike == strike.roundToDouble()
                  ? strike.toStringAsFixed(0)
                  : strike.toStringAsFixed(2),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          // Put side
          Expanded(
            child: _buildSide(
              option: put,
              isSelected: isPutSelected,
              isITM: isITMPut,
              onTap: onPutTap,
              isCall: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSide({
    required Option? option,
    required bool isSelected,
    required bool isITM,
    required VoidCallback? onTap,
    required bool isCall,
  }) {
    if (option == null) {
      return const SizedBox.expand();
    }

    final content = GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.08)
            : isITM
                ? AppColors.primary.withValues(alpha: 0.03)
                : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          children: [
            if (isSelected)
              Container(
                width: 3,
                height: 20,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            _cell(option.bid.toStringAsFixed(2), flex: 2),
            _cell(option.ask.toStringAsFixed(2), flex: 2),
            _cell(option.last.toStringAsFixed(2), flex: 2),
            _cell(_formatVolume(option.openInterest), flex: 2),
            _cell(
              option.delta != null
                  ? option.delta!.toStringAsFixed(2)
                  : '-',
              flex: 2,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );

    // Wrap with slidable for swipe actions
    if (onAddToPosition != null) {
      return Slidable(
        key: ValueKey('${option.optionMapKey}_slidable'),
        startActionPane: ActionPane(
          motion: const BehindMotion(),
          extentRatio: 0.45,
          children: [
            CustomSlidableAction(
              onPressed: (_) => onAddToPosition!(option, BuyOrSell.buy),
              backgroundColor: AppColors.profit.withValues(alpha: 0.9),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, size: 16),
                  Text('Buy', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            CustomSlidableAction(
              onPressed: (_) => onAddToPosition!(option, BuyOrSell.sell),
              backgroundColor: AppColors.loss.withValues(alpha: 0.9),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.remove_rounded, size: 16),
                  Text('Sell', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
        child: content,
      );
    }

    return content;
  }

  Widget _cell(String text, {int flex = 1, Color? color}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color ?? AppColors.textPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w400,
          fontFamily: 'monospace',
        ),
        maxLines: 1,
        overflow: TextOverflow.clip,
      ),
    );
  }

  String _formatVolume(int vol) {
    if (vol >= 1000) return '${(vol / 1000).toStringAsFixed(1)}K';
    return vol.toString();
  }
}

/// Header row for the option chain columns.
class OptionChainHeader extends StatelessWidget {
  const OptionChainHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Call headers
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                children: const [
                  _HeaderCell('Bid'),
                  _HeaderCell('Ask'),
                  _HeaderCell('Last'),
                  _HeaderCell('OI'),
                  _HeaderCell('Δ'),
                ],
              ),
            ),
          ),
          // Center label
          Container(
            width: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight.withValues(alpha: 0.5),
              border: Border.symmetric(
                vertical: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.4),
                  width: 0.5,
                ),
              ),
            ),
            child: const Text(
              'STRIKE',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          // Put headers
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                children: const [
                  _HeaderCell('Bid'),
                  _HeaderCell('Ask'),
                  _HeaderCell('Last'),
                  _HeaderCell('OI'),
                  _HeaderCell('Δ'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 2,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Price marker line showing current stock price position.
class PriceMarkerLine extends StatelessWidget {
  final double price;

  const PriceMarkerLine({super.key, required this.price});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        border: Border.symmetric(
          horizontal: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.arrow_right_rounded,
              size: 14, color: AppColors.primary.withValues(alpha: 0.6)),
          Text(
            '\$${price.toStringAsFixed(2)}',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          Icon(Icons.arrow_left_rounded,
              size: 14, color: AppColors.primary.withValues(alpha: 0.6)),
        ],
      ),
    );
  }
}
