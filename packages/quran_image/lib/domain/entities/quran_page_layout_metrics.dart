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

  factory QuranPageLayoutMetrics.compute({
    required double layoutWidth,
    required double layoutHeight,
    required double viewportHeight,
    required double lineHeight,
    required bool isLandscape,
  }) {
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
      pageWidth: layoutWidth,
      pageHeight: viewportHeight,
      layoutHeight: stackHeight,
      lineHeight: lineHeight,
      isLandscape: isLandscape,
      yOffsets: yOffsets,
    );
  }
}
