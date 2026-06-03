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
      animation: Listenable.merge(<Listenable>[curved, animation]),
      builder: (context, _) {
        final double t = curved.value.clamp(0.0, 1.0);
        final bool reversing =
            animation.status == AnimationStatus.reverse;
        final double scrimAlpha = (0.45 * t).clamp(0.0, 0.45);

        // YouTube Music: underlying feed stays visible; only a scrim dims it.
        // Never paint an opaque surface fill (reads as a white flash in light
        // theme during collapse — see quran_player_ex_col.webm).
        final Widget scrim = ColoredBox(
          color: scheme.scrim.withValues(alpha: scrimAlpha),
        );

        if (reversing) {
          final double slideY =
              (1 - Curves.easeInCubic.transform(t)) *
              MediaQuery.sizeOf(context).height *
              0.08;
          return Stack(
            fit: StackFit.expand,
            children: [
              scrim,
              Transform.translate(
                offset: Offset(0, slideY),
                child: Opacity(
                  opacity: Curves.easeOut.transform(t),
                  child: IgnorePointer(child: child),
                ),
              ),
            ],
          );
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            scrim,
            Opacity(
              opacity: Curves.easeOut.transform(t),
              child: child,
            ),
          ],
        );
      },
    );
  }
}
