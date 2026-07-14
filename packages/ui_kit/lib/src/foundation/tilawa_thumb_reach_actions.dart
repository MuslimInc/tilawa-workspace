import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// Primary-first action stack for [TilawaThumbReachLayout].
///
/// Keeps [primary] at a stable Y. When [secondary] is non-null, its footprint
/// is always reserved via [Visibility.maintainSize] so toggling
/// [showSecondary] cannot shift the primary control.
class TilawaThumbReachActions extends StatelessWidget {
  /// Creates a thumb-reach action column.
  const TilawaThumbReachActions({
    super.key,
    required this.primary,
    this.secondary,
    this.showSecondary = true,
    this.spacing,
  });

  /// Primary CTA (typically a full-width [TilawaButton]).
  final Widget primary;

  /// Optional secondary control under [primary] (Back / Skip / ghost).
  final Widget? secondary;

  /// When false and [secondary] is set, paints an invisible reserved slot.
  final bool showSecondary;

  /// Gap between primary and secondary; defaults to [MeMuslimDesignTokens.spaceLarge].
  final double? spacing;

  @override
  Widget build(BuildContext context) {
    final MeMuslimDesignTokens tokens = Theme.of(context).tokens;
    final double gap = spacing ?? tokens.spaceLarge;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: gap,
      children: <Widget>[
        primary,
        if (secondary != null)
          Visibility(
            visible: showSecondary,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            maintainInteractivity: false,
            child: secondary!,
          ),
      ],
    );
  }
}
