import 'package:flutter/widgets.dart';

import '../helpers/app_logger.dart';
import '../services/quran_data_service.dart';

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
  });
  final double fontSize;
  final double fontHeight;
  final bool isScrollable;
  final EdgeInsets padding;
  final double lineSpacing;
  final double letterSpacing;
  final double bismillahHeight;
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
  // Bismillah targeted line height (responsive multiplier)
  static const double _bismillahTargetHeight = 2.5;

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
      final double availableWidth =
          constraints.maxWidth * (1.0 - (_horizontalPaddingRatio * 2));
      final double adaptiveFontSize = availableWidth / _widthDivisor;
      metrics = _calculateLandscapeMetrics(adaptiveFontSize);
    } else {
      // Analyze page to count special lines for precise vertical distribution.
      final Map<String, int> counts = QuranDataService.instance
          .getSpecialLineCounts(pageNumber);
      metrics = _calculatePortraitMetrics(
        constraints,
        counts['headers'] ?? 0,
        counts['bismillahs'] ?? 0,
      );
    }

    final Duration duration = DateTime.now().difference(startTime);
    if (duration.inMilliseconds > 2) {
      logger.d(
        '[PageContent] StandardQuranLayoutStrategy: Metrics calculated in ${duration.inMilliseconds}ms',
      );
    }

    return metrics;
  }

  QuranLayoutMetrics _calculateLandscapeMetrics(double fontSize) {
    return QuranLayoutMetrics(
      fontSize: fontSize,
      fontHeight: _landscapeFontHeight,
      isScrollable: true,
      lineSpacing: (fontSize * 0.2).clamp(2.0, 6.0),
    );
  }

  QuranLayoutMetrics _calculatePortraitMetrics(
    BoxConstraints constraints,
    int headerCount,
    int bismillahCount,
  ) {
    // 15 total lines per page in Mushaf standard.
    const totalLines = 15;
    final int standardLines = totalLines - headerCount - bismillahCount;

    final double availableWidth =
        constraints.maxWidth * (1.0 - (_horizontalPaddingRatio * 2));
    final double fontSize = availableWidth / _widthDivisor;

    // Reserve a small top margin.
    final double availableHeight = constraints.maxHeight - _topPadding;

    // Use adaptive spacing based on font size (approx 20% of font size).
    final double lineSpacing = (fontSize * 0.2).clamp(2.0, 6.0);
    final double totalSpacing = (totalLines - 1) * lineSpacing;

    // Equation:
    // (standardLines + headerCount) * (fontHeight * fontSize) + bismillahCount * (_bismillahTargetHeight * fontSize) + totalSpacing = availableHeight

    final double bismillahTotalHeight =
        bismillahCount * _bismillahTargetHeight * fontSize;
    final double remainingHeightForLines =
        (availableHeight - totalSpacing - bismillahTotalHeight).clamp(
          0.0,
          double.infinity,
        );

    // Divisor is (standardLines + headerCount) + some safety margin (e.g. 1.0) for vertical padding
    final double lineFactor = (standardLines + headerCount + 1.25).clamp(
      1.0,
      16.0,
    );
    final double fontHeight = (remainingHeightForLines / lineFactor) / fontSize;

    return QuranLayoutMetrics(
      fontSize: fontSize,
      fontHeight: fontHeight,
      isScrollable: false,
      padding: const EdgeInsets.only(top: _topPadding),
      lineSpacing: lineSpacing,
    );
  }
}
