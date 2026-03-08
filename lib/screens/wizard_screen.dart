import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/colors.dart';
import '../theme/animations.dart';
import '../models/option.dart';
import '../services/url_state_service.dart';
import '../providers/ticker_provider.dart';
import '../providers/options_provider.dart';
import '../providers/settings_provider.dart';
import 'ticker_search/ticker_search_screen.dart';
import 'option_selection/option_selection_screen.dart';
import 'profit_visualization/profit_visualization_screen.dart';

class WizardScreen extends ConsumerStatefulWidget {
  const WizardScreen({super.key});

  @override
  ConsumerState<WizardScreen> createState() => _WizardScreenState();
}

class _WizardScreenState extends ConsumerState<WizardScreen> {
  final _pageController = PageController();
  int _currentStep = 0;
  bool _restoredFromUrl = false;

  @override
  void initState() {
    super.initState();
    _tryRestoreFromUrl();
  }

  /// Try to restore state from URL query parameters (web only).
  void _tryRestoreFromUrl() {
    if (!kIsWeb) return;

    try {
      final uri = Uri.base;
      if (uri.queryParameters.isEmpty) return;

      final decoded = UrlStateService.decode(uri.queryParameters);
      if (decoded == null) return;

      // Restore ticker
      ref.read(selectedTickerSymbolProvider.notifier).state = decoded.ticker;

      // Restore settings
      ref.read(settingsProvider.notifier).setAll(decoded.settings);

      _restoredFromUrl = true;

      if (decoded.legs.isNotEmpty) {
        // Restore legs by fetching option chain data and matching
        _restoreLegs(decoded.ticker, decoded.legs);
      }
    } catch (_) {
      // Silently ignore URL parse errors
    }
  }

  /// Fetch option chain data and restore legs from URL parameters.
  Future<void> _restoreLegs(String ticker, List<SelectedLegParams> legParams) async {
    try {
      final service = ref.read(marketDataServiceProvider);
      final notifier = ref.read(selectedOptionsProvider.notifier);

      // Group legs by expiry to minimize API calls
      final expiries = legParams.map((l) => l.expiry).toSet();

      for (final expiry in expiries) {
        final options = await service.getOptionChain(ticker, expiry);
        final optionMap = <String, Option>{};
        for (final opt in options) {
          optionMap[opt.optionMapKey] = opt;
        }

        // Match each leg for this expiry
        for (final leg in legParams.where((l) => l.expiry == expiry)) {
          final key = '${leg.expiry}:${leg.strike}:${leg.callOrPut.code}';
          final option = optionMap[key];
          if (option != null) {
            notifier.add(option, leg.action, quantity: leg.quantity);
          }
        }
      }

      // Set the first expiry as selected
      if (expiries.isNotEmpty) {
        ref.read(selectedExpirationProvider.notifier).state = expiries.first;
      }

      // Jump to visualization if legs were restored
      if (ref.read(selectedOptionsProvider).isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _goToStep(2);
        });
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _goToStep(1);
        });
      }
    } catch (_) {
      // If restoration fails, go to option selection
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _goToStep(1);
      });
    }
  }

  void _goToStep(int step) {
    if (step < 0 || step > 2) return;
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: Anim.medium,
      curve: Anim.smooth,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildStepIndicator(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentStep = i),
                children: [
                  TickerSearchScreen(onNext: () => _goToStep(1)),
                  OptionSelectionScreen(
                    onNext: () => _goToStep(2),
                    onBack: () => _goToStep(0),
                  ),
                  ProfitVisualizationScreen(
                    onBack: () => _goToStep(1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    final labels = ['Search', 'Select', 'Visualize'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      child: Row(
        children: [
          if (_currentStep > 0)
            IconButton(
              onPressed: () => _goToStep(_currentStep - 1),
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textSecondary),
            )
          else
            const SizedBox(width: 48),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                final isActive = i == _currentStep;
                final isDone = i < _currentStep;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: Anim.fast,
                        curve: Anim.snappy,
                        width: isActive ? 40 : 12,
                        height: 12,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: isActive
                              ? AppColors.primary
                              : isDone
                                  ? AppColors.primary.withValues(alpha: 0.5)
                                  : AppColors.surfaceLight,
                        ),
                      ),
                      if (isActive) ...[
                        const SizedBox(width: 6),
                        Text(
                          labels[i],
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    ).animate().fadeIn(duration: Anim.medium);
  }
}
