import 'package:flutter/material.dart';

/// Route transition for [RecitersSearchRoute] — calm expand into search.
class RecitersSearchRouteTransition extends StatelessWidget {
  const RecitersSearchRouteTransition({
    required this.animation,
    required this.child,
    super.key,
  });

  final Animation<double> animation;
  final Widget child;

  static const Duration transitionDuration = Duration(milliseconds: 280);
  static const Duration reverseTransitionDuration = Duration(
    milliseconds: 240,
  );

  static Animation<double> curvedAnimation(Animation<double> parent) {
    return CurvedAnimation(
      parent: parent,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Animation<double> curved = curvedAnimation(animation);

    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.015),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
