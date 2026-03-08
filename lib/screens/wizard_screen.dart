import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/colors.dart';
import '../theme/animations.dart';
import '../models/option.dart';
import '../services/url_state_service.dart';
import '../providers/ticker_provider.dart';
import '../providers/options_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/ticker_header.dart';
import '../screens/settings/settings_sheet.dart';
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

  void _tryRestoreFromUrl() {
    if (!kIsWeb) return;
    try {
      final uri = Uri.base;
      if (uri.queryParameters.isEmpty) return;
      final decoded = UrlStateService.decode(uri.queryParameters);
      if (decoded == null) return;
      ref.read(selectedTickerSymbolProvider.notifier).state = decoded.ticker;
      ref.read(settingsProvider.notifier).setAll(decoded.settings);
      if (decoded.legs.isNotEmpty) {
        _restoreLegs(decoded.ticker, decoded.legs);
      }
    } catch (_) {}
  }

  Future<void> _restoreLegs(
      String ticker, List<SelectedLegParams> legParams) async {
    try {
      final service = ref.read(marketDataServiceProvider);
      final notifier = ref.read(selectedOptionsProvider.notifier);
      final expiries = legParams.map((l) => l.expiry).toSet();
      for (final expiry in expiries) {
        final options = await service.getOptionChain(ticker, expiry);
        final optionMap = <String, Option>{};
        for (final opt in options) {
          optionMap[opt.optionMapKey] = opt;
        }
        for (final leg in legParams.where((l) => l.expiry == expiry)) {
          final key = '${leg.expiry}:${leg.strike}:${leg.callOrPut.code}';
          final option = optionMap[key];
          if (option != null) {
            notifier.add(option, leg.action, quantity: leg.quantity);
          }
        }
      }
      if (expiries.isNotEmpty) {
        ref.read(selectedExpirationProvider.notifier).state = expiries.first;
      }
      if (ref.read(selectedOptionsProvider).isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _goToStep(2));
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) => _goToStep(1));
      }
    } catch (_) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _goToStep(1));
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
    final hasSymbol = ref.watch(selectedTickerSymbolProvider) != null;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar: back arrow + progress + settings gear
            _buildTopBar(),
            // Persistent ticker header (visible after selection)
            if (hasSymbol && _currentStep > 0) const TickerHeader(),
            // Screen content
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 450),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final isForward = _currentStep > _previousStep;
                  final isEntering =
                      (child.key as ValueKey).value == _currentStep;
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
                        curve:
                            const Interval(0.0, 0.8, curve: Curves.easeOut),
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

  Widget _buildTopBar() {
    final labels = ['Search', 'Options', 'P&L'];
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          // Back arrow
          AnimatedOpacity(
            duration: Anim.fast,
            opacity: _currentStep > 0 ? 1.0 : 0.0,
            child: IconButton(
              onPressed:
                  _currentStep > 0 ? () => _goToStep(_currentStep - 1) : null,
              icon: const Icon(Icons.arrow_back_rounded, size: 20),
              color: AppColors.textSecondary,
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ),
          const SizedBox(width: 4),
          // Breadcrumb navigation
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                final isActive = i == _currentStep;
                final isDone = i < _currentStep;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (i > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: 14,
                          color: isDone
                              ? AppColors.primary.withValues(alpha: 0.5)
                              : AppColors.textMuted.withValues(alpha: 0.5),
                        ),
                      ),
                    GestureDetector(
                      onTap: isDone ? () => _goToStep(i) : null,
                      child: Text(
                        labels[i],
                        style: TextStyle(
                          color: isActive
                              ? AppColors.primary
                              : isDone
                                  ? AppColors.textSecondary
                                  : AppColors.textMuted,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w400,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
          // Thin progress bar
          const SizedBox(width: 4),
          // Settings gear
          IconButton(
            onPressed: () => SettingsSheet.show(context),
            icon: const Icon(Icons.settings_rounded, size: 18),
            color: AppColors.textMuted,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }
}
