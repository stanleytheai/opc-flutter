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

class _WizardScreenState extends ConsumerState<WizardScreen>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  int _previousStep = 0;
  bool _isTransitioning = false;

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

      if (decoded.legs.isNotEmpty) {
        // Restore legs by fetching option chain data and matching
        _restoreLegs(decoded.ticker, decoded.legs);
      }
    } catch (_) {
      // Silently ignore URL parse errors
    }
  }

  /// Fetch option chain data and restore legs from URL parameters.
  Future<void> _restoreLegs(
      String ticker, List<SelectedLegParams> legParams) async {
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
    if (step < 0 || step > 2 || step == _currentStep) return;
    if (_isTransitioning) return;

    setState(() {
      _previousStep = _currentStep;
      _currentStep = step;
      _isTransitioning = true;
    });

    // Reset transition lock after animation completes
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _isTransitioning = false);
    });
  }

  Widget _buildStep() {
    switch (_currentStep) {
      case 0:
        return TickerSearchScreen(
          key: const ValueKey(0),
          onNext: () => _goToStep(1),
        );
      case 1:
        return OptionSelectionScreen(
          key: const ValueKey(1),
          onNext: () => _goToStep(2),
          onBack: () => _goToStep(0),
        );
      case 2:
        return ProfitVisualizationScreen(
          key: const ValueKey(2),
          onBack: () => _goToStep(1),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildStepIndicator(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 450),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  // Determine if this is the entering or exiting widget
                  final isForward = _currentStep > _previousStep;
                  final isEntering =
                      (child.key as ValueKey).value == _currentStep;

                  // Slide direction based on navigation direction
                  final slideOffset = isEntering
                      ? Tween<Offset>(
                          begin: Offset(isForward ? 0.05 : -0.05, 0),
                          end: Offset.zero,
                        )
                      : Tween<Offset>(
                          begin: Offset.zero,
                          end: Offset(isForward ? -0.05 : 0.05, 0),
                        );

                  return SlideTransition(
                    position: slideOffset.animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    )),
                    child: FadeTransition(
                      opacity: CurvedAnimation(
                        parent: animation,
                        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
                      ),
                      child: child,
                    ),
                  );
                },
                child: _buildStep(),
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
          AnimatedOpacity(
            duration: Anim.fast,
            opacity: _currentStep > 0 ? 1.0 : 0.0,
            child: IconButton(
              onPressed:
                  _currentStep > 0 ? () => _goToStep(_currentStep - 1) : null,
              icon: const Icon(Icons.arrow_back_rounded,
                  color: AppColors.textSecondary),
            ),
          ),
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
                      AnimatedSize(
                        duration: Anim.fast,
                        curve: Anim.snappy,
                        child: isActive
                            ? Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: Text(
                                  labels[i],
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
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
