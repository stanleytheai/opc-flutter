import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../../../models/ticker.dart';

class TickerResultTile extends StatelessWidget {
  final TickerSearchResult result;
  final VoidCallback onTap;

  const TickerResultTile({super.key, required this.result, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          result.symbol.substring(0, result.symbol.length.clamp(0, 2)),
          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
      title: Text(result.symbol, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      subtitle: Text(
        result.description,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
    );
  }
}
