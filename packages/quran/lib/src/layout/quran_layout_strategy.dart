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
/// - **Landscape**: Uses a compact scrollable layout closer to printed mushaf apps.
class StandardQuranLayoutStrategy implements QuranLayoutStrategy {
  // Compact line height for landscape scrolling pages.
  static const double _landscapeFontHeight = 1.75;
  // Width divisor to determine base font size relative to screen width.
  // Higher values produce a smaller font to prevent horizontal wrapping.
  static const double _widthDivisor = 16.50;
  // Standard horizontal padding for the Mushaf lines.
  static const double _horizontalPaddingRatio = 0.025;
  // Small top padding to prevent the first line's diacritical marks from
  // being clipped by the viewport boundary.
  static const double _topPadding = 4.0;

  @override
  QuranLayoutMetrics calculateMetrics(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    // Use narrow MediaQuery accessors to avoid rebuilds on unrelated changes
    // (e.g., keyboard appearance, text scale factor).
    final Orientation orientation = MediaQuery.orientationOf(context);

    if (orientation == Orientation.landscape) {
      // Common Base Font Size based on AVAILABLE width (after padding)
      final double availableWidth =
          constraints.maxWidth * (1.0 - (_horizontalPaddingRatio * 2));
      final double adaptiveFontSize = availableWidth / _widthDivisor;
      return _calculateLandscapeMetrics(adaptiveFontSize);
    } else {
      // Use actual constraints provided by the parent (e.g. SafeArea)
      return _calculatePortraitMetrics(constraints);
    }
  }

  QuranLayoutMetrics _calculateLandscapeMetrics(double fontSize) {
    return QuranLayoutMetrics(
      fontSize: fontSize,
      fontHeight: _landscapeFontHeight,
      isScrollable: true,
    );
  }

  QuranLayoutMetrics _calculatePortraitMetrics(BoxConstraints constraints) {
    final double availableWidth =
        constraints.maxWidth * (1.0 - (_horizontalPaddingRatio * 2));
    final double fontSize = availableWidth / _widthDivisor;

    // Reserve a small top margin so diacritical marks on the first line
    // are not clipped by the viewport boundary.
    final double availableHeight = constraints.maxHeight - _topPadding;
    final double fontHeight = (availableHeight / 17.0) / fontSize;

    return QuranLayoutMetrics(
      fontSize: fontSize,
      fontHeight: fontHeight,
      isScrollable: false,
      padding: const EdgeInsets.only(top: _topPadding),
    );
  }
}
