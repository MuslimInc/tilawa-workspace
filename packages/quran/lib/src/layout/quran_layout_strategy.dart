import 'package:flutter/widgets.dart';

import '../helpers/app_logger.dart';

/// Strategy interface for calculating Quran page layout metrics.
///
/// Adheres to the Strategy pattern to allow for different layout algorithms
/// (e.g., standard, large text, experimental) without modifying the widget code.
abstract class QuranLayoutStrategy {
  /// Calculates font size and line height based on widget constraints.
  QuranLayoutMetrics calculateMetrics(
    BuildContext context,
    BoxConstraints constraints,
    int pageNumber,
  );
}

/// The result of a layout calculation.
class QuranLayoutMetrics {
  const QuranLayoutMetrics({
    required this.fontSize,
    required this.fontHeight,
    required this.isScrollable,
    this.padding = EdgeInsets.zero,
    this.lineSpacing = 0.0,
    this.letterSpacing = 0.0,
    this.bismillahHeight = 2.5,
    this.verseHorizontalPadding = 0.0,
    this.bismillahHorizontalPadding = 0.0,
  });
  final double fontSize;
  final double fontHeight;
  final bool isScrollable;
  final EdgeInsets padding;
  final double lineSpacing;
  final double letterSpacing;
  final double bismillahHeight;
  final double verseHorizontalPadding;
  final double bismillahHorizontalPadding;
}

/// The standard implementation of Quran layout logic.
///
/// - **Portrait**: Fits exactly 15 lines into the available vertical space (minus safe areas).
/// - **Landscape**: Uses a compact scrollable layout closer to printed mushaf apps.
class StandardQuranLayoutStrategy implements QuranLayoutStrategy {
  static const double _fontHeight = 1.75;
  // Width divisor to determine base font size relative to screen width.
  // Higher values produce a smaller font to prevent horizontal wrapping.
  static const double _widthDivisor = 16.0;
  // Explicit line inset measured from the Ayah reference on a 720px capture.
  static const double _verseHorizontalPaddingRatio = 25 / 720;
  // Explicit bismillah inset measured from the Ayah reference on a 720px capture.
  static const double _bismillahHorizontalPaddingRatio = 14 / 720;
  // Small top padding to prevent the first line's diacritical marks from
  // being clipped by the viewport boundary.
  static const double _topPadding = 4.0;

  @override
  QuranLayoutMetrics calculateMetrics(
    BuildContext context,
    BoxConstraints constraints,
    int pageNumber,
  ) {
    final startTime = DateTime.now();
    final Orientation orientation = MediaQuery.orientationOf(context);

    QuranLayoutMetrics metrics;
    if (orientation == Orientation.landscape) {
      final double verseHorizontalPadding =
          constraints.maxWidth * _verseHorizontalPaddingRatio;
      final double bismillahHorizontalPadding =
          constraints.maxWidth * _bismillahHorizontalPaddingRatio;
      final double availableWidth =
          constraints.maxWidth - (verseHorizontalPadding * 2);
      final double adaptiveFontSize = availableWidth / _widthDivisor;
      metrics = _calculateLandscapeMetrics(
        adaptiveFontSize,
        verseHorizontalPadding,
        bismillahHorizontalPadding,
      );
    } else {
      metrics = _calculatePortraitMetrics(constraints);
    }

    final Duration duration = DateTime.now().difference(startTime);
    if (duration.inMilliseconds > 2) {
      logger.d(
        '[PageContent] StandardQuranLayoutStrategy: Metrics calculated in ${duration.inMilliseconds}ms',
      );
    }

    return metrics;
  }

  QuranLayoutMetrics _calculateLandscapeMetrics(
    double fontSize,
    double verseHorizontalPadding,
    double bismillahHorizontalPadding,
  ) {
    return QuranLayoutMetrics(
      fontSize: fontSize,
      fontHeight: _fontHeight,
      isScrollable: true,
      lineSpacing: (fontSize * 0.108).clamp(0.8, 3.4),
      verseHorizontalPadding: verseHorizontalPadding,
      bismillahHorizontalPadding: bismillahHorizontalPadding,
    );
  }

  QuranLayoutMetrics _calculatePortraitMetrics(BoxConstraints constraints) {
    final double verseHorizontalPadding =
        constraints.maxWidth * _verseHorizontalPaddingRatio;
    final double bismillahHorizontalPadding =
        constraints.maxWidth * _bismillahHorizontalPaddingRatio;
    final double availableWidth =
        constraints.maxWidth - (verseHorizontalPadding * 2);
    final double fontSize = availableWidth / _widthDivisor;
    final double lineSpacing = (fontSize * 0.108).clamp(0.8, 3.4);

    return QuranLayoutMetrics(
      fontSize: fontSize,
      fontHeight: _fontHeight,
      isScrollable: false,
      padding: const EdgeInsets.only(top: _topPadding),
      lineSpacing: lineSpacing,
      verseHorizontalPadding: verseHorizontalPadding,
      bismillahHorizontalPadding: bismillahHorizontalPadding,
    );
  }
}
