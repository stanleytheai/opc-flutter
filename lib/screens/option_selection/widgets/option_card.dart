import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../../../theme/animations.dart';
import '../../../models/option.dart';

class OptionCard extends StatelessWidget {
  final Option option;
  final bool isSelected;
  final VoidCallback onTap;

  const OptionCard({
    super.key,
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Anim.fast,
          curve: Anim.snappy,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Selection indicator
              AnimatedContainer(
                duration: Anim.fast,
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.textMuted,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check_rounded, size: 16, color: AppColors.background)
                    : null,
              ),
              const SizedBox(width: 14),

              // Strike price
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\$${option.strike.toStringAsFixed(option.strike == option.strike.roundToDouble() ? 0 : 2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Strike',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(width: 20),

              // Bid / Ask
              Expanded(
                child: Row(
                  children: [
                    _metric('Bid', option.bid.toStringAsFixed(2)),
                    const SizedBox(width: 12),
                    _metric('Ask', option.ask.toStringAsFixed(2)),
                    const SizedBox(width: 12),
                    _metric('IV', '${option.impliedVolatility.toStringAsFixed(1)}%'),
                    const SizedBox(width: 12),
                    _metric('OI', option.openInterest.toString()),
                  ],
                ),
              ),

              // Greeks mini
              if (option.delta != null)
                Text(
                  'Δ${option.delta!.toStringAsFixed(2)}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w500),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500, fontSize: 13)),
        Text(label, style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
      ],
    );
  }
}
