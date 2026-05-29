import 'package:flutter/material.dart';

/// Scrim + surface fade for the typed `/player` [CustomTransitionPage].
class QuranPlayerExpandedRouteTransition extends StatelessWidget {
  const QuranPlayerExpandedRouteTransition({
    required this.animation,
    required this.child,
    super.key,
  });

  final Animation<double> animation;
  final Widget child;

  static const Duration transitionDuration = Duration(milliseconds: 320);
  static const Duration reverseTransitionDuration = Duration(
    milliseconds: 280,
  );

  static Animation<double> curvedAnimation(Animation<double> parent) {
    return CurvedAnimation(
      parent: parent,
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.fastOutSlowIn.flipped,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Animation<double> curved = curvedAnimation(animation);

    return AnimatedBuilder(
      animation: curved,
      builder: (context, _) {
        final double t = curved.value;
        return Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: scheme.surface.withValues(
                alpha: (0.88 * t).clamp(0.0, 0.88),
              ),
            ),
            ColoredBox(
              color: scheme.scrim.withValues(
                alpha: (0.42 * t).clamp(0.0, 0.42),
              ),
            ),
            child,
          ],
        );
      },
    );
  }
}
