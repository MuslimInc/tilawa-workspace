import 'package:flutter/material.dart';

import '../foundation/design_tokens.dart';

/// A wrapper around [RefreshIndicator] that enforces the global UI kit elevation multiplier.
///
/// It uses the global theme's progress indicator colors and applies the global elevation scaling
/// to ensure the refresh indicator depth matches the rest of the app's components.
class TilawaRefreshIndicator extends StatelessWidget {
  const TilawaRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.displacement = 40.0,
    this.edgeOffset = 0.0,
    this.color,
    this.backgroundColor,
    this.semanticsLabel,
    this.semanticsValue,
    this.strokeWidth = RefreshProgressIndicator.defaultStrokeWidth,
    this.triggerMode = RefreshIndicatorTriggerMode.onEdge,
  }) : _adaptive = false;

  /// Creates a [TilawaRefreshIndicator] that uses a [RefreshIndicator.adaptive]
  /// to switch between Android and iOS styles.
  const TilawaRefreshIndicator.adaptive({
    super.key,
    required this.child,
    required this.onRefresh,
    this.displacement = 40.0,
    this.edgeOffset = 0.0,
    this.color,
    this.backgroundColor,
    this.semanticsLabel,
    this.semanticsValue,
    this.strokeWidth = RefreshProgressIndicator.defaultStrokeWidth,
    this.triggerMode = RefreshIndicatorTriggerMode.onEdge,
  }) : _adaptive = true;

  final bool _adaptive;

  /// The widget below this widget in the tree.
  final Widget child;

  /// A function that's called when the user has dragged the refresh indicator
  /// far enough to demonstrate that they want the app to refresh.
  final RefreshCallback onRefresh;

  /// The distance from the child's top or bottom edge to where the refresh
  /// indicator will settle.
  final double displacement;

  /// The offset where [RefreshProgressIndicator] starts to appear on drag start.
  final double edgeOffset;

  /// The progress indicator's foreground color.
  final Color? color;

  /// The progress indicator's background color.
  final Color? backgroundColor;

  /// {@macro flutter.progress_indicator.ProgressIndicator.semanticsLabel}
  final String? semanticsLabel;

  /// {@macro flutter.progress_indicator.ProgressIndicator.semanticsValue}
  final String? semanticsValue;

  /// Defines `strokeWidth` for `RefreshIndicator`.
  final double strokeWidth;

  /// Defines how this [RefreshIndicator] can be triggered when users overscroll.
  final RefreshIndicatorTriggerMode triggerMode;

  @override
  Widget build(BuildContext context) {
    if (_adaptive) {
      return RefreshIndicator.adaptive(
        onRefresh: onRefresh,
        displacement: displacement,
        edgeOffset: edgeOffset,
        color: color,
        backgroundColor: backgroundColor,
        semanticsLabel: semanticsLabel,
        semanticsValue: semanticsValue,
        strokeWidth: strokeWidth,
        triggerMode: triggerMode,
        elevation: 2.0 * kElevationMultiplier,
        child: child,
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      displacement: displacement,
      edgeOffset: edgeOffset,
      color: color,
      backgroundColor: backgroundColor,
      semanticsLabel: semanticsLabel,
      semanticsValue: semanticsValue,
      strokeWidth: strokeWidth,
      triggerMode: triggerMode,
      elevation: 2.0 * kElevationMultiplier,
      child: child,
    );
  }
}
