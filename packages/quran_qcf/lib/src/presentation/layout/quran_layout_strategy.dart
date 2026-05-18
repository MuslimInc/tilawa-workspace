import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../core/constants/quran_constants.dart';
import '../../core/constants/surah_header_banner_constants.dart';
import '../../domain/models/quran_page_models.dart';
import '../../domain/models/quran_special_line.dart';
import '../../domain/repositories/quran_mushaf_service.dart';

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
    QuranMushafService mushafService,
  );
}

/// The standard implementation of Quran layout logic.
///
/// - **Portrait**: Fits exactly 15 lines into the available vertical space (minus safe areas).
/// - **Landscape**: Uses a tight scrollable layout closer to printed mushaf apps.
class StandardQuranLayoutStrategy implements QuranLayoutStrategy {
  static const double _fontHeight = 1.85;
  static const double _ayahLineHeightReferencePixels = 174.0;
  static const double _ayahLineHeightReferenceWidth = 1080.0;
  // Width divisor to determine base font size relative to screen width.
  // Higher values produce a smaller font to prevent horizontal wrapping.
  // Set to 16.8 to match the Ayah app's larger text density.
  static const double _widthDivisor = 16.8;
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
    QuranMushafService mushafService,
  ) {
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
        pageNumber,
      );
    } else {
      metrics = _calculatePortraitMetrics(
        constraints,
        pageNumber,
        mushafService,
      );
    }

    return metrics;
  }

  QuranLayoutMetrics _calculateLandscapeMetrics(
    double fontSize,
    double verseHorizontalPadding,
    double bismillahHorizontalPadding,
    int pageNumber,
  ) {
    // In landscape, we use a much larger relative gap to create an "airy"
    // scrollable experience, matching the user's preference for ~40px spacing.
    final double lineSpacing = fontSize * 0.8;

    return QuranLayoutMetrics(
      fontSize: fontSize,
      fontHeight: _fontHeight,
      isScrollable: true,
      lineSpacing: lineSpacing,
      verseHorizontalPadding: verseHorizontalPadding,
      bismillahHorizontalPadding: bismillahHorizontalPadding,
    );
  }

  QuranLayoutMetrics _calculatePortraitMetrics(
    BoxConstraints constraints,
    int pageNumber,
    QuranMushafService mushafService,
  ) {
    final double verseHorizontalPadding =
        constraints.maxWidth * _verseHorizontalPaddingRatio;
    final double bismillahHorizontalPadding =
        constraints.maxWidth * _bismillahHorizontalPaddingRatio;

    // 1. Calculate max safe font size by width (prevent horizontal bleed)
    final double availableWidth =
        constraints.maxWidth - (verseHorizontalPadding * 2);
    final double maxFontSizeByWidth = availableWidth / _widthDivisor;

    final double availableHeight = constraints.maxHeight - _topPadding;
    final double idealFontSizeByHeight = availableHeight / 28.5;

    final double fontSize = math.min(idealFontSizeByHeight, maxFontSizeByWidth);

    // Match quran_image/Ayah vertical slot geometry while also respecting
    // the extra height cost of inline surah headers and standalone Bismillah.
    final QuranSpecialLineCounts specialCounts = mushafService
        .getSpecialLineCountSummary(pageNumber);
    final int headers = specialCounts.headers;
    final int bismillahs = specialCounts.bismillahs;
    final int normalLines = QuranConstants.linesPerPage - headers - bismillahs;
    final double lineSlotHeight =
        availableWidth *
        (_ayahLineHeightReferencePixels / _ayahLineHeightReferenceWidth);
    final double bannerHeight =
        availableWidth * SurahHeaderBannerConstants.heightToWidthRatio;
    final double bismillahHeight = fontSize * 0.8 * 1.8;

    final double lineSpacing = _computeDynamicPortraitLineSpacing(
      pageNumber: pageNumber,
      fontSize: fontSize,
      availableHeight: availableHeight,
      lineSlotHeight: lineSlotHeight,
      normalLines: normalLines,
      headers: headers,
      bismillahs: bismillahs,
      bannerHeight: bannerHeight,
      bismillahHeight: bismillahHeight,
    );

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

  double _computeDynamicPortraitLineSpacing({
    required int pageNumber,
    required double fontSize,
    required double availableHeight,
    required double lineSlotHeight,
    required int normalLines,
    required int headers,
    required int bismillahs,
    required double bannerHeight,
    required double bismillahHeight,
  }) {
    final double lineGlyphHeight = fontSize * _fontHeight;

    // Base spacing keeps dense pages visually close to printed Mushaf rhythm.
    final double baseSpacing = (fontSize * 0.108).clamp(0.8, 3.4);
    if (pageNumber <= 2) return baseSpacing;

    final double slotStep =
        (availableHeight - lineSlotHeight) / QuranConstants.lineGapCount;
    final double ayahReferenceSpacing = slotStep - lineGlyphHeight;

    final double fixedContentHeight =
        (normalLines * lineGlyphHeight) +
        (headers * bannerHeight) +
        (bismillahs * bismillahHeight);
    final double contentFitSpacing =
        (availableHeight - fixedContentHeight) / QuranConstants.lineGapCount;

    // Use the Ayah-style rhythm when it fits, but never exceed the spacing
    // budget required by pages that contain multiple headers/Bismillah blocks.
    final double idealSpacing = math.min(
      ayahReferenceSpacing,
      contentFitSpacing,
    );

    const minSpacing = 0.8;
    final double maxSpacing = (lineGlyphHeight * 0.42).clamp(6.0, 16.0);

    return idealSpacing.clamp(minSpacing, maxSpacing);
  }
}
