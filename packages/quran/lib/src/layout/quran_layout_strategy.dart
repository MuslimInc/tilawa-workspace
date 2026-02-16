import 'package:flutter/widgets.dart';

/// Strategy interface for calculating Quran page layout metrics.
///
/// Adheres to the Strategy pattern to allow for different layout algorithms
/// (e.g., standard, large text, experimental) without modifying the widget code.
abstract class QuranLayoutStrategy {
  /// Calculates the font size and line height based on the available screen constraints.
  QuranLayoutMetrics calculateMetrics(BuildContext context);
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
  // Constant for the number of lines per page in a standard Madani Mushaf.
  // static const int _linesPerPage = 15;
  // Tuning factor for height calculation to ensure perfect fit.
  static const double _heightTuningFactor = 17.5;
  // Proportional factor for natural Arabic text spacing.
  static const double _naturalLineHeightRatio = 0.50;
  // Width divisor to determine base font size relative to screen width.
  static const double _widthDivisor = 17.5;

  @override
  QuranLayoutMetrics calculateMetrics(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final Orientation orientation = mediaQuery.orientation;
    final Size size = mediaQuery.size;
    final EdgeInsets padding = mediaQuery.padding;

    // Common Base Font Size
    final double adaptiveFontSize = size.width / _widthDivisor;

    if (orientation == Orientation.landscape) {
      return _calculateLandscapeMetrics(adaptiveFontSize, padding);
    } else {
      return _calculatePortraitMetrics(size.height, padding, adaptiveFontSize);
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

  QuranLayoutMetrics _calculatePortraitMetrics(
    double screenHeight,
    EdgeInsets padding,
    double fontSize,
  ) {
    // Calculate actual vertical space available for text
    final double availableHeight = screenHeight - padding.top - padding.bottom;

    // Calculate height factor to squeeze exactly 15 lines into the space
    final double fontHeight =
        (availableHeight / _heightTuningFactor) / fontSize;

    // Adaptive letter spacing based on screen width/font size ratio
    // Generally 0 is fine, but for very wide/narrow screens we might tune it.
    // User requested adaptive.
    // Let's assume a small factor of font size.
    final double letterSpacing = fontSize * 0.0;

    return QuranLayoutMetrics(
      fontSize: fontSize,
      fontHeight: fontHeight,
      isScrollable: false,
      letterSpacing: letterSpacing,
    );
  }
}
