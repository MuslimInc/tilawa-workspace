import 'package:flutter/widgets.dart';

import 'content_bounds.dart';

/// Material 3 aligned window-size breakpoints for the Tilawa UI Kit.
///
/// These thresholds classify the current window width into a discrete
/// [TilawaWindowSize]. Layout code should branch on the size class, not on
/// raw pixel widths.
class TilawaBreakpoints {
  const TilawaBreakpoints._();

  /// Upper bound for the narrow window class (typical phones in portrait).
  static const double narrowUpperBound = 600;

  /// Upper bound for medium (small tablets, foldable inner displays in
  /// portrait, phones in landscape).
  static const double medium = 840;

  /// Upper bound for expanded (tablets, foldables in landscape).
  static const double expanded = 1200;
}

/// Discrete window-size class, aligned with Material 3 window size classes.
enum TilawaWindowSize {
  /// width < 600
  narrow,

  /// 600 ≤ width < 840
  medium,

  /// 840 ≤ width < 1200
  expanded,

  /// 1200 ≤ width (reserved; not actively targeted today).
  large,
}

/// Ergonomic access to the current window-size class and common predicates.
extension TilawaWindowSizeX on BuildContext {
  /// Full logical viewport size from [MediaQuery.sizeOf].
  ///
  /// Use for **proportional** layout (e.g. sheet `maxHeight` as a fraction of
  /// the viewport). For **width-class** branching, prefer [windowSize].
  Size get viewportSize => MediaQuery.sizeOf(this);

  /// Shorthand for [viewportSize.height].
  double get viewportHeight => viewportSize.height;

  /// Shorthand for [viewportSize.width].
  double get viewportWidth => viewportSize.width;

  /// Resolves the current [TilawaWindowSize] from [viewportSize].
  ///
  /// Uses [MediaQuery.sizeOf] (narrow dependency) so callers do not rebuild on
  /// unrelated MediaQuery changes (e.g. keyboard open, textScaler change).
  TilawaWindowSize get windowSize {
    final width = viewportWidth;
    if (width >= TilawaBreakpoints.expanded) return TilawaWindowSize.large;
    if (width >= TilawaBreakpoints.medium) return TilawaWindowSize.expanded;
    if (width >= TilawaBreakpoints.narrowUpperBound) {
      return TilawaWindowSize.medium;
    }
    return TilawaWindowSize.narrow;
  }

  bool get isNarrow => windowSize == TilawaWindowSize.narrow;

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
    final screenWidth = viewportWidth;
    final maxWidth = TilawaContentBounds.resolveMaxWidth(this, kind);
    return screenWidth < maxWidth ? screenWidth : maxWidth;
  }
}
