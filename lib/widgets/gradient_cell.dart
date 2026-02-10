import 'package:flutter/material.dart';
import '../theme/colors.dart';

class GradientCell extends StatelessWidget {
  final double profitPercent;
  final double value;
  final bool isSelected;

  const GradientCell({
    super.key,
    required this.profitPercent,
    required this.value,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.profitColor(profitPercent);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(4),
        border: isSelected
            ? Border.all(color: Colors.white, width: 2)
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
