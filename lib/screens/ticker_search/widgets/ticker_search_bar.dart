import 'package:flutter/material.dart';
import '../../../theme/colors.dart';

class TickerSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool loading;

  const TickerSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: Theme.of(context).textTheme.titleLarge,
      textCapitalization: TextCapitalization.characters,
      decoration: InputDecoration(
        hintText: 'AAPL, TSLA, SPY...',
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 16, right: 12),
          child: Icon(Icons.search_rounded, color: AppColors.textMuted, size: 28),
        ),
        suffixIcon: loading
            ? const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
              )
            : controller.text.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                    icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted),
                  )
                : null,
        contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      ),
    );
  }
}
