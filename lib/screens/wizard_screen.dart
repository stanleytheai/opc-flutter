import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/colors.dart';
import '../theme/animations.dart';
import 'ticker_search/ticker_search_screen.dart';
import 'option_selection/option_selection_screen.dart';
import 'profit_visualization/profit_visualization_screen.dart';

class WizardScreen extends StatefulWidget {
  const WizardScreen({super.key});

  @override
  State<WizardScreen> createState() => _WizardScreenState();
}

class _WizardScreenState extends State<WizardScreen> {
  final _pageController = PageController();
  int _currentStep = 0;

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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
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
                  child: AnimatedContainer(
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
