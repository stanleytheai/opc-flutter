import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/colors.dart';
import '../../providers/settings_provider.dart';

/// Bottom sheet for calculation settings (interest rate, dividend yield, etc.).
class SettingsSheet extends ConsumerStatefulWidget {
  const SettingsSheet({super.key});

  @override
  ConsumerState<SettingsSheet> createState() => _SettingsSheetState();

  /// Show the settings bottom sheet.
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const SettingsSheet(),
    );
  }
}

class _SettingsSheetState extends ConsumerState<SettingsSheet> {
  late TextEditingController _irController;
  late TextEditingController _dyController;
  late TextEditingController _prController;
  late TextEditingController _psController;

  @override
  void initState() {
    super.initState();
    final s = ref.read(settingsProvider);
    _irController = TextEditingController(text: s.interestRate.toString());
    _dyController = TextEditingController(text: s.dividendYield.toString());
    _prController = TextEditingController(text: (s.priceRangePercent * 100).toStringAsFixed(0));
    _psController = TextEditingController(text: s.priceSteps.toString());
  }

  @override
  void dispose() {
    _irController.dispose();
    _dyController.dispose();
    _prController.dispose();
    _psController.dispose();
    super.dispose();
  }

  void _apply() {
    final notifier = ref.read(settingsProvider.notifier);
    final ir = double.tryParse(_irController.text);
    final dy = double.tryParse(_dyController.text);
    final pr = double.tryParse(_prController.text);
    final ps = int.tryParse(_psController.text);

    if (ir != null) notifier.updateInterestRate(ir);
    if (dy != null) notifier.updateDividendYield(dy);
    if (pr != null) notifier.updatePriceRangePercent(pr / 100);
    if (ps != null && ps > 0) notifier.updatePriceSteps(ps);

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Calculation Settings',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _field('Interest Rate (%)', _irController),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _field('Dividend Yield (%)', _dyController),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _field('Price Range (%)', _prController),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _field('Price Steps', _psController),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              TextButton(
                onPressed: () {
                  ref.read(settingsProvider.notifier).reset();
                  Navigator.of(context).pop();
                },
                child: const Text('Reset to Defaults',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _apply,
                child: const Text('Apply'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(fontSize: 14),
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }
}
