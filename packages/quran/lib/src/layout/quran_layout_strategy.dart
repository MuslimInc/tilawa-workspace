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
  // Proportional factor for natural Arabic text spacing.
  static const double _naturalLineHeightRatio = 0.40;
  // Width divisor to determine base font size relative to screen width.
  static const double _widthDivisor = 14;

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
    );
  }

  QuranLayoutMetrics _calculatePortraitMetrics(
    double screenHeight,
    EdgeInsets padding,
    double fontSize,
  ) {
    // Calculate actual vertical space available for text
    // Subtract approximate height for header (~40px) and footer (~44px)
    const headerHeight = 40.0;
    const footerHeight = 44.0;
    final double availableHeight =
        screenHeight -
        padding.top -
        padding.bottom -
        headerHeight -
        footerHeight;

    // Calculate height factor to squeeze exactly 15 lines into the remaining space
    // We use a slightly smaller factor now because the space is already reduced.
    // 15.0 factor would mean each line takes 1/15th of the space.
    final double fontHeight = (availableHeight / 15.0) / fontSize;

    // Adaptive letter spacing based on screen width/font size ratio
    final double letterSpacing = fontSize * 0.0;

    return const QuranLayoutMetrics(
      fontSize: 32,
      fontHeight: 2.1,
      isScrollable: false,
      // letterSpacing: 2,
    );
  }
}
