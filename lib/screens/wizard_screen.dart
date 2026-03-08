import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/colors.dart';
import '../theme/animations.dart';
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
      // Note: legs can't be fully restored without fetching option chain data.
      // The ticker will be set, and user can proceed from step 2.
      if (decoded.legs.isNotEmpty) {
        // Jump to step 1 (option selection) after a tick
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _goToStep(1);
        });
      }
    } catch (_) {
      // Silently ignore URL parse errors
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
