import 'package:flutter/material.dart';
import '../../../theme/colors.dart';

class SelectionSummary extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onNext;

  const SelectionSummary({super.key, required this.selectedCount, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$selectedCount option${selectedCount == 1 ? '' : 's'} selected',
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: onNext,
            icon: const Icon(Icons.show_chart_rounded, size: 20),
            label: const Text('Visualize'),
          ),
        ],
      ),
    );
  }
}
