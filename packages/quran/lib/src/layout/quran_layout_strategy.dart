import 'package:flutter/widgets.dart';

/// Strategy interface for calculating Quran page layout metrics.
///
/// Adheres to the Strategy pattern to allow for different layout algorithms
/// (e.g., standard, large text, experimental) without modifying the widget code.
abstract class QuranLayoutStrategy {
  /// Calculates font size and line height based on widget constraints.
  QuranLayoutMetrics calculateMetrics(
    BuildContext context,
    BoxConstraints constraints,
  );
}

/// The result of a layout calculation.
class QuranLayoutMetrics {
  const QuranLayoutMetrics({
    required this.fontSize,
    required this.fontHeight,
    required this.isScrollable,
    this.padding = EdgeInsets.zero,
    this.letterSpacing = 0.0,
  });
  final double fontSize;
  final double fontHeight;
  final bool isScrollable;
  final EdgeInsets padding;
  final double letterSpacing;
}

/// The standard implementation of Quran layout logic.
///
/// - **Portrait**: Fits exactly 15 lines into the available vertical space (minus safe areas).
/// - **Landscape**: Uses a natural proportional line height and enables scrolling.
class StandardQuranLayoutStrategy implements QuranLayoutStrategy {
  // Tuning factor for height calculation to ensure perfect fit.
  // Proportional factor for natural Arabic text spacing.
  static const double _naturalLineHeightRatio = 0.40;
  // Width divisor to determine base font size relative to screen width.
  // Higher values produce a smaller font to prevent horizontal wrapping.
  static const double _widthDivisor = 16.35;
  // Standard horizontal padding for the Mushaf lines.
  static const double _horizontalPaddingRatio = 0.025;

  @override
  QuranLayoutMetrics calculateMetrics(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    // Use narrow MediaQuery accessors to avoid rebuilds on unrelated changes
    // (e.g., keyboard appearance, text scale factor).
    final Orientation orientation = MediaQuery.orientationOf(context);

    if (orientation == Orientation.landscape) {
      final EdgeInsets padding = MediaQuery.paddingOf(context);
      // Common Base Font Size based on AVAILABLE width (after padding)
      final double availableWidth =
          constraints.maxWidth * (1.0 - (_horizontalPaddingRatio * 2));
      final double adaptiveFontSize = availableWidth / _widthDivisor;
      return _calculateLandscapeMetrics(adaptiveFontSize, padding);
    } else {
      // Use actual constraints provided by the parent (e.g. SafeArea)
      return _calculatePortraitMetrics(constraints);
    }
  }

  QuranLayoutMetrics _calculateLandscapeMetrics(
    double fontSize,
    EdgeInsets padding,
  ) {
    // In landscape, prioritize readability with natural spacing.
    // Height ~= 2.12x font size
    const double fontHeight = 1 / _naturalLineHeightRatio;

    return QuranLayoutMetrics(
      fontSize: fontSize,
      fontHeight: fontHeight,
      isScrollable: true,
      padding: EdgeInsets.only(
        top: padding.top + 16,
        bottom: padding.bottom + 16,
      ),
    );
  }

  QuranLayoutMetrics _calculatePortraitMetrics(BoxConstraints constraints) {
    final double availableWidth =
        constraints.maxWidth * (1.0 - (_horizontalPaddingRatio * 2));
    final double fontSize = availableWidth / _widthDivisor;

    // constraints.maxHeight already excludes header/footer since the
    // LayoutBuilder sits inside an Expanded sibling of header and footer.
    final double fontHeight = (constraints.maxHeight / 15.0) / fontSize;

    return QuranLayoutMetrics(
      fontSize: fontSize,
      fontHeight: fontHeight,
      isScrollable: false,
    );
  }
}
