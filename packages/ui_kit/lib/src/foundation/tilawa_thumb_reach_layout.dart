import 'package:flutter/material.dart';

import 'content_bounds.dart';
import 'design_tokens.dart';

/// Vertical split for one-handed primary actions (~72% content / ~28% chrome).
///
/// Primary controls sit at the top of the lower band so they land near 72% of
/// the viewport. A trailing [Spacer] keeps [actions] at intrinsic height — never
/// stretched to fill the band (see [TilawaContentBounds] pitfall in action
/// slots).
class TilawaThumbReachLayout extends StatelessWidget {
  /// Creates a thumb-reach layout.
  const TilawaThumbReachLayout({
    super.key,
    required this.content,
    required this.actions,
    this.contentFlex = defaultContentFlex,
    this.actionFlex = defaultActionFlex,
    this.useSafeArea = false,
    this.actionMaxWidthKind = TilawaContentKind.form,
  });

  /// Flex weight for the scrollable / hero content band.
  static const int defaultContentFlex = 72;

  /// Flex weight for the lower action band (chrome only — not button height).
  static const int defaultActionFlex = 28;

  /// Upper content (slides, hero copy, illustrations).
  final Widget content;

  /// Controls rendered at the top of the lower band (buttons, footer chrome).
  ///
  /// Use a [Column] with [MainAxisSize.min]; do not wrap in [Expanded].
  final Widget actions;

  /// Flex for [content]; defaults to [defaultContentFlex].
  final int contentFlex;

  /// Flex for the action band; defaults to [defaultActionFlex].
  final int actionFlex;

  /// When true, wraps the layout in [SafeArea].
  final bool useSafeArea;

  /// Max width applied to [actions] via [TilawaContentBounds.resolveMaxWidth].
  final TilawaContentKind actionMaxWidthKind;

  /// Fraction from the top of the layout where the action band begins (0–1).
  static double actionBandStartFraction({
    int contentFlex = defaultContentFlex,
    int actionFlex = defaultActionFlex,
  }) {
    return contentFlex / (contentFlex + actionFlex);
  }

  @override
  Widget build(BuildContext context) {
    final TilawaDesignTokens tokens = Theme.of(context).tokens;
    final double maxActionWidth = TilawaContentBounds.resolveMaxWidth(
      context,
      actionMaxWidthKind,
    );

    final Widget column = Column(
      children: <Widget>[
        Expanded(flex: contentFlex, child: content),
        Expanded(
          flex: actionFlex,
          child: Column(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: tokens.spaceLarge),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxActionWidth),
                    child: actions,
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ],
    );

    if (useSafeArea) {
      return SafeArea(child: column);
    }
    return column;
  }
}
