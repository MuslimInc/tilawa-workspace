import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';

/// A standardized loading indicator for consistent appearance.
///
/// Wraps [CircularProgressIndicator] with token-driven defaults.
/// Use [centered] to control whether the indicator is wrapped in a
/// [Center] widget (the most common usage pattern).
class TilawaLoadingIndicator extends StatelessWidget {
  /// Creates a loading indicator.
  ///
  /// When [centered] is `true` (default), the indicator is wrapped
  /// in a [Center] widget. Set to `false` when placing the indicator
  /// in a layout that already handles positioning.
  const TilawaLoadingIndicator({
    super.key,
    this.centered = true,
    this.strokeWidth,
    this.color,
    this.semanticsLabel,
  });

  /// Whether to wrap the indicator in a [Center] widget.
  final bool centered;

  /// Stroke width override. Defaults to the token value.
  final double? strokeWidth;

  /// Color override. Defaults to `colorScheme.primary`.
  final Color? color;

  /// Optional semantic label for accessibility.
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.componentTokens.loadingIndicator;

    final Widget indicator = CircularProgressIndicator(
      strokeWidth: strokeWidth ?? tokens.defaultStrokeWidth,
      color: color,
      semanticsLabel: semanticsLabel,
    );

    if (!centered) return indicator;
    return Center(child: indicator);
  }
}
