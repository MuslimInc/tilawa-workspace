import 'package:flutter/widgets.dart';

import 'content_bounds.dart';

/// Material 3 aligned window-size breakpoints for the Tilawa UI Kit.
///
/// These thresholds classify the current window width into a discrete
/// [TilawaWindowSize]. Layout code should branch on the size class, not on
/// raw pixel widths.
class TilawaBreakpoints {
  const TilawaBreakpoints._();

  /// Upper bound for compact (phones in portrait).
  static const double compact = 600;

  /// Upper bound for medium (small tablets, foldable inner displays in
  /// portrait, phones in landscape).
  static const double medium = 840;

  /// Upper bound for expanded (tablets, foldables in landscape).
  static const double expanded = 1200;
}

/// Discrete window-size class, aligned with Material 3 window size classes.
enum TilawaWindowSize {
  /// width < 600
  compact,

  /// 600 ≤ width < 840
  medium,

  /// 840 ≤ width < 1200
  expanded,

  /// 1200 ≤ width (reserved; not actively targeted today).
  large,
}

/// Ergonomic access to the current window-size class and common predicates.
extension TilawaWindowSizeX on BuildContext {
  /// Resolves the current [TilawaWindowSize] from `MediaQuery.sizeOf(this)`.
  ///
  /// Uses [MediaQuery.sizeOf] (narrow dependency) so callers do not rebuild on
  /// unrelated MediaQuery changes (e.g. keyboard open, textScaler change).
  TilawaWindowSize get windowSize {
    final width = MediaQuery.sizeOf(this).width;
    if (width >= TilawaBreakpoints.expanded) return TilawaWindowSize.large;
    if (width >= TilawaBreakpoints.medium) return TilawaWindowSize.expanded;
    if (width >= TilawaBreakpoints.compact) return TilawaWindowSize.medium;
    return TilawaWindowSize.compact;
  }

  bool get isCompact => windowSize == TilawaWindowSize.compact;

  bool get isAtLeastMedium => windowSize.index >= TilawaWindowSize.medium.index;

  bool get isAtLeastExpanded =>
      windowSize.index >= TilawaWindowSize.expanded.index;

  bool get isAtLeastLarge => windowSize.index >= TilawaWindowSize.large.index;

  /// Resolves the actual width available for content of a specific [kind].
  ///
  /// This respects [TilawaContentBounds] logic by returning the minimum of
  /// the current screen width and the canonical max-width for that [kind].
  /// Use this for layout math (like scroll-to-index offsets) that must
  /// remain accurate on wide screens.
  double resolveContentWidth(TilawaContentKind kind) {
    final screenWidth = MediaQuery.sizeOf(this).width;
    final maxWidth = TilawaContentBounds.resolveMaxWidth(this, kind);
    return screenWidth < maxWidth ? screenWidth : maxWidth;
  }
}
