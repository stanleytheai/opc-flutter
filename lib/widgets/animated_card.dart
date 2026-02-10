import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/animations.dart';

class AnimatedCard extends StatelessWidget {
  final Widget child;
  final int index;
  final EdgeInsetsGeometry? padding;

  const AnimatedCard({
    super.key,
    required this.child,
    this.index = 0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    )
        .animate()
        .fadeIn(duration: Anim.medium, delay: Anim.staggerDelay(index))
        .slideY(begin: 0.1, end: 0, duration: Anim.medium, curve: Anim.snappy);
  }
}
