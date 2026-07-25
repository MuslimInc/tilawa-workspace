import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Soft fade + slight drift while a [PageView] page leaves or enters.
///
/// Complements the native page slide. Collapses to a plain [child] under
/// reduced motion ([MediaQuery.disableAnimationsOf]).
class OnboardingPageScrollFade extends StatelessWidget {
  const OnboardingPageScrollFade({
    super.key,
    required this.controller,
    required this.index,
    required this.child,
  });

  final PageController controller;
  final int index;
  final Widget child;

  /// How far opacity falls at a full page of scroll offset.
  static const double _fadeStrength = 0.45;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return child;
    }

    final MeMuslimDesignTokens tokens = Theme.of(context).tokens;

    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? child) {
        final double page = _resolvedPage();
        final double delta = (page - index).clamp(-1.0, 1.0);
        final double abs = delta.abs();
        final double opacity = (1.0 - abs * _fadeStrength).clamp(0.0, 1.0);
        // Gentle lateral drift with the scroll; vertical settle as it leaves.
        final Offset offset = Offset(
          -delta * tokens.spaceSmall,
          abs * tokens.spaceExtraSmall,
        );

        return Opacity(
          opacity: opacity,
          child: Transform.translate(offset: offset, child: child),
        );
      },
      child: child,
    );
  }

  double _resolvedPage() {
    if (!controller.hasClients || !controller.position.hasContentDimensions) {
      return index.toDouble();
    }
    return controller.page ?? index.toDouble();
  }
}
