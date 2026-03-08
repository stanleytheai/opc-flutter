import 'package:flutter/material.dart';
import '../theme/colors.dart';

class GradientCell extends StatelessWidget {
  final double profitPercent;
  final double value;
  final bool isSelected;
  final bool isCrosshair;
  final bool isCurrentPrice;

  const GradientCell({
    super.key,
    required this.profitPercent,
    required this.value,
    this.isSelected = false,
    this.isCrosshair = false,
    this.isCurrentPrice = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.profitColor(profitPercent);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: isCrosshair
            ? color.withValues(alpha: 0.55)
            : color.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(4),
        border: isSelected
            ? Border.all(color: Colors.white, width: 2)
            : isCurrentPrice
                ? Border.all(color: AppColors.primary.withValues(alpha: 0.6), width: 1)
                : null,
      ),
      alignment: Alignment.center,
      child: isSelected
          ? Text(
              value >= 0 ? '+${value.toStringAsFixed(0)}' : value.toStringAsFixed(0),
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            )
          : null,
    );
  }
}
