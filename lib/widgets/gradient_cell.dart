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
    final alpha = isSelected
        ? 1.0
        : isCrosshair
            ? 0.45
            : 0.82;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.all(0.75),
      decoration: BoxDecoration(
        color: color.withValues(alpha: alpha),
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
                  color: color.withValues(alpha: 0.4),
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
