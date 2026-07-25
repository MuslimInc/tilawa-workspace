import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:quran_image/core/constants/surah_header_constants.dart';

/// Frozen layout values for a Quran page viewport.
///
/// Computed once when constraints change and reused across rebuilds to avoid
/// per-frame [List.generate] allocations in the page [LayoutBuilder].
@immutable
class QuranPageLayoutMetrics {
  const QuranPageLayoutMetrics({
    required this.pageWidth,
    required this.pageHeight,
    required this.layoutHeight,
    required this.lineHeight,
    required this.isLandscape,
    required this.yOffsets,
  });

  final double pageWidth;
  final double pageHeight;
  final double layoutHeight;
  final double lineHeight;
  final bool isLandscape;
  final List<double> yOffsets;

  /// Width-based Ayah line height: `pageWidth × 174/1080`.
  static double widthBasedLineHeight(double pageWidth) {
    return pageWidth *
        SurahHeaderConstants.lineHeightReferencePixels /
        SurahHeaderConstants.lineHeightReferenceWidth;
  }

  /// Inverse of [widthBasedLineHeight].
  static double widthForLineHeight(double lineHeight) {
    return lineHeight *
        SurahHeaderConstants.lineHeightReferenceWidth /
        SurahHeaderConstants.lineHeightReferencePixels;
  }

  /// On a wide portrait column (desktop dual-page), raw width-based
  /// [lineHeight] exceeds the Ayah stride `(H - L) / 14`. Adjacent line
  /// images then overlap so much that calligraphy collides and debug
  /// borders look like notebook rules.
  ///
  /// Cap so stride ≥ ½ lineHeight ⇒ `L ≤ H / 8` (same family as phone
  /// where stride ≈ 0.7×L). Content width shrinks to match and is centered
  /// by the caller.
  static double portraitLineHeight({
    required double layoutWidth,
    required double layoutHeight,
  }) {
    final double widthBased = widthBasedLineHeight(layoutWidth);
    if (layoutHeight <= 0) {
      return widthBased;
    }
    // stride = (H - L) / 14; require stride >= L/2 → L <= H/8.
    final double noCollisionCap = layoutHeight / 8;
    return math.min(widthBased, noCollisionCap);
  }

  factory QuranPageLayoutMetrics.compute({
    required double layoutWidth,
    required double layoutHeight,
    required double viewportHeight,
    required double lineHeight,
    required bool isLandscape,
    double? pageWidth,
  }) {
    final double resolvedPageWidth = pageWidth ?? layoutWidth;
    final stackHeight = isLandscape
        ? lineHeight * SurahHeaderConstants.lineCount
        : layoutHeight;
    final lastLineIndex = SurahHeaderConstants.lastLineIndex.toDouble();
    final yOffsets = List<double>.generate(
      SurahHeaderConstants.lineCount,
      (index) => (stackHeight - lineHeight) / lastLineIndex * index,
      growable: false,
    );
    return QuranPageLayoutMetrics(
      pageWidth: resolvedPageWidth,
      pageHeight: viewportHeight,
      layoutHeight: stackHeight,
      lineHeight: lineHeight,
      isLandscape: isLandscape,
      yOffsets: yOffsets,
    );
  }
}
