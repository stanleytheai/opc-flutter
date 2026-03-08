import 'package:flutter/material.dart';
import '../../../theme/colors.dart';

/// Horizontal scrollable tab bar for expiration dates.
class ExpiryTabs extends StatefulWidget {
  final List<String> expirations;
  final String? selected;
  final ValueChanged<String> onSelected;

  const ExpiryTabs({
    super.key,
    required this.expirations,
    required this.selected,
    required this.onSelected,
  });

  @override
  State<ExpiryTabs> createState() => _ExpiryTabsState();
}

class _ExpiryTabsState extends State<ExpiryTabs> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _formatExpiry(String expiry) {
    // Format "2025-01-17" -> "Jan 17"
    try {
      final parts = expiry.split('-');
      if (parts.length != 3) return expiry;
      final months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);
      return '${months[month]} $day';
    } catch (_) {
      return expiry;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: widget.expirations.length,
        itemBuilder: (_, i) {
          final exp = widget.expirations[i];
          final isSelected = exp == widget.selected;
          return GestureDetector(
            onTap: () => widget.onSelected(exp),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                _formatExpiry(exp),
                style: TextStyle(
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
