import 'dart:math' as math;

/// Ayah-style dual-page mushaf spread policy for wide viewports.
///
/// On a wide landscape window (e.g. 27″ desktop), outer start/end gutters sit
/// on the **viewport** (via [horizontalInset]) so facing pages stay flush in
/// the middle and padding does not flip during dual-page scroll. Measured
/// Ayah @ 27″: mushaf content band 1762px on a 2560px window
/// ([maxContentWidthFraction]).
abstract final class MushafSpreadLayout {
  static const double viewportFractionSingle = 1.0;
  static const double viewportFractionDual = 0.5;

  /// Minimum logical width for one readable mushaf page column.
  static const double minPageWidth = 480;

  /// Preferred single-page column width (phone/tablet mushaf).
  static const double preferredPageWidth = 515;

  /// Max fraction of viewport width occupied by mushaf **ink** across the
  /// spread. Ayah @ 27″: 1762 / 2560.
  static const double maxContentWidthFraction = 1762 / 2560;

  static bool shouldUseDualPage({
    required double viewportWidth,
    required double viewportHeight,
  }) {
    return viewportWidth > viewportHeight && viewportWidth >= minPageWidth * 2;
  }

  /// Target width of mushaf content across one or both pages (no side chrome).
  static double spreadContentWidth({
    required double viewportWidth,
    required double viewportHeight,
  }) {
    if (viewportWidth <= 0) {
      return 0;
    }
    final bool dual = shouldUseDualPage(
      viewportWidth: viewportWidth,
      viewportHeight: viewportHeight,
    );
    final double minContentWidth = preferredPageWidth * (dual ? 2.0 : 1.0);
    final double fractionCap = viewportWidth * maxContentWidthFraction;
    return math.max(minContentWidth, math.min(viewportWidth, fractionCap));
  }

  /// Leftover width inside one page column after [pageContentWidth].
  ///
  /// Prefer [horizontalInset] for dual-page chrome — per-column outer pads
  /// tied to `page.floor()` flip mid-swipe and cause jank.
  static double pageOuterPadding({
    required double pageColumnWidth,
    required double viewportWidth,
    required double viewportHeight,
  }) {
    if (pageColumnWidth <= 0) {
      return 0;
    }
    final double contentWidth = pageContentWidth(
      pageColumnWidth: pageColumnWidth,
      viewportWidth: viewportWidth,
      viewportHeight: viewportHeight,
    );
    return math.max(0.0, pageColumnWidth - contentWidth);
  }

  /// Mushaf content width for one page column.
  static double pageContentWidth({
    required double pageColumnWidth,
    required double viewportWidth,
    required double viewportHeight,
  }) {
    final double spread = spreadContentWidth(
      viewportWidth: viewportWidth,
      viewportHeight: viewportHeight,
    );
    if (shouldUseDualPage(
      viewportWidth: viewportWidth,
      viewportHeight: viewportHeight,
    )) {
      return math.min(pageColumnWidth, spread * viewportFractionDual);
    }
    return math.min(pageColumnWidth, spread);
  }

  /// Stable start/end gutter outside the mushaf spread band.
  ///
  /// Applied around the [PageView] so dual pages stay flush (no middle gap)
  /// and gutters do not rematerialize when the settled page index changes.
  static double horizontalInset({
    required double viewportWidth,
    required double viewportHeight,
  }) {
    final double spread = spreadContentWidth(
      viewportWidth: viewportWidth,
      viewportHeight: viewportHeight,
    );
    if (spread >= viewportWidth) {
      return 0;
    }
    return (viewportWidth - spread) / 2;
  }

  static double viewportFraction({
    required double viewportWidth,
    required double viewportHeight,
  }) {
    return shouldUseDualPage(
          viewportWidth: viewportWidth,
          viewportHeight: viewportHeight,
        )
        ? viewportFractionDual
        : viewportFractionSingle;
  }

  /// Width available to mushaf layout metrics / prep for one page.
  static double pageColumnWidth({
    required double viewportWidth,
    required double viewportHeight,
    required double singlePageMaxWidth,
  }) {
    final double content = pageContentWidth(
      pageColumnWidth:
          shouldUseDualPage(
            viewportWidth: viewportWidth,
            viewportHeight: viewportHeight,
          )
          ? viewportWidth * viewportFractionDual
          : viewportWidth,
      viewportWidth: viewportWidth,
      viewportHeight: viewportHeight,
    );
    if (shouldUseDualPage(
      viewportWidth: viewportWidth,
      viewportHeight: viewportHeight,
    )) {
      return content;
    }
    return content < singlePageMaxWidth ? content : singlePageMaxWidth;
  }
}
