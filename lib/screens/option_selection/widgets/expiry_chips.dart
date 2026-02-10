import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/colors.dart';
import '../../../theme/animations.dart';

class ExpiryChips extends StatelessWidget {
  final List<String> expirations;
  final String? selected;
  final ValueChanged<String> onSelected;

  const ExpiryChips({
    super.key,
    required this.expirations,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: expirations.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final exp = expirations[i];
          final isSelected = exp == selected;
          return ChoiceChip(
            label: Text(exp),
            selected: isSelected,
            onSelected: (_) => onSelected(exp),
            selectedColor: AppColors.primary.withValues(alpha: 0.2),
            labelStyle: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
            side: BorderSide(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ).animate().fadeIn(
            duration: Anim.fast,
            delay: Anim.staggerDelay(i),
          ).slideX(begin: 0.1, end: 0);
        },
      ),
    );
  }
}
