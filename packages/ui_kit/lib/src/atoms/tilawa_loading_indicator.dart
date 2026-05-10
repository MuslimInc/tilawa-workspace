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
    this.value,
    this.backgroundColor,
    this.valueColor,
    this.strokeCap,
  });

  /// Whether to wrap the indicator in a [Center] widget.
  final bool centered;

  /// Stroke width override. Defaults to the token value.
  final double? strokeWidth;

  /// Color override when [valueColor] is null.
  ///
  /// Defaults to theme primary when both this and [valueColor] are null.
  final Color? color;

  /// Optional semantic label for accessibility.
  final String? semanticsLabel;

  /// Progress from 0–1 for determinate indicators; null for indeterminate.
  final double? value;

  /// Track color behind the active arc.
  final Color? backgroundColor;

  /// Animated color for the active arc (e.g. [AlwaysStoppedAnimation]).
  final Animation<Color?>? valueColor;

  /// Stroke cap style; null uses the Material default.
  final StrokeCap? strokeCap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.componentTokens.loadingIndicator;

    final Widget indicator = CircularProgressIndicator(
      value: value,
      strokeWidth: strokeWidth ?? tokens.defaultStrokeWidth,
      backgroundColor: backgroundColor,
      color: valueColor != null ? null : color,
      valueColor: valueColor,
      semanticsLabel: semanticsLabel,
      strokeCap: strokeCap,
    );

    if (!centered) return indicator;
    return Center(child: indicator);
  }
}
