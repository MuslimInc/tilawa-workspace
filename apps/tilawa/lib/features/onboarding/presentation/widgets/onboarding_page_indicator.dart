import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Page dots for onboarding — token-backed sizes and colors.
///
/// Active pill expands/contracts over [MeMuslimDesignTokens.durationFast].
/// Instant under reduced motion.
class OnboardingPageIndicator extends StatelessWidget {
  const OnboardingPageIndicator({
    super.key,
    required this.count,
    required this.currentIndex,
  });

  final int count;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;
    final ColorScheme colorScheme = theme.colorScheme;
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
    final Duration duration = reduceMotion
        ? Duration.zero
        : tokens.durationFast;
    final double dotHeight = tokens.spaceSmall;
    final double activeWidth = tokens.spaceExtraLarge;
    final double inactiveWidth = tokens.spaceSmall;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(count, (int index) {
        final bool active = index == currentIndex;
        return AnimatedContainer(
          duration: duration,
          curve: tokens.curveEmphasized,
          margin: EdgeInsets.symmetric(horizontal: tokens.spaceExtraSmall),
          height: dotHeight,
          width: active ? activeWidth : inactiveWidth,
          decoration: BoxDecoration(
            color: active ? colorScheme.primary : colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(tokens.radiusSmall),
          ),
        );
      }),
    );
  }
}
