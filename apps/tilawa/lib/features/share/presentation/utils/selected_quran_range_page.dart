import 'package:flutter/widgets.dart';
import 'package:quran_qcf/quran_qcf.dart';

import 'selection_crop_window.dart';
import 'surah_header_policy.dart';

const double _headerToBismillahGapFactor = 0.08;
const double _headerToBismillahMinGap = 3;
const double _headerToBismillahMaxGap = 6;
const double _bismillahToTextGapFactor = 0.05;
const double _bismillahToTextMinGap = 2;
const double _bismillahToTextMaxGap = 4;
const double _headerToTextGapFactor = 0.12;
const double _headerToTextMinGap = 6;
const double _headerToTextMaxGap = 10;
const double _compositionVerticalPaddingFactor = 0.28;
const double _compositionMinVerticalPadding = 8;
const double _compositionMaxVerticalPadding = 18;
const double _compositionHeightSafetyInset = 16;

@immutable
class SelectedQuranRangeComposition {
  const SelectedQuranRangeComposition({
    required this.page,
    required this.estimatedHeight,
  });

  final PreparedQuranPage page;
  final double estimatedHeight;
}

/// Builds the screenshot-only selected ayah composition.
///
/// Phase S1 is intentionally line/block granular: if a selected ayah shares a
/// prepared QCF line with unselected ayahs, the full line is preserved to avoid
/// corrupting QCF glyph positioning. Precise mid-line filtering is deferred.
SelectedQuranRangeComposition? buildSelectedQuranRangeComposition({
  required PreparedQuranPage sourcePage,
  required int surahNumber,
  required int fromAyah,
  required int toAyah,
  required Size viewportSize,
  double headerFontSizeMultiplier = 0.57,
}) {
  final List<PreparedTextBlock> selectedTextBlocks = sourcePage.blocks
      .whereType<PreparedTextBlock>()
      .where(
        (block) => textBlockHasSelectedVerse(
          block,
          surahNumber: surahNumber,
          fromAyah: fromAyah,
          toAyah: toAyah,
        ),
      )
      .toList(growable: false);

  if (selectedTextBlocks.isEmpty) {
    return null;
  }

  final QuranLayoutMetrics metrics = _compositionMetrics(sourcePage.metrics);
  final double lineHeight = metrics.fontSize * metrics.fontHeight;
  final bool includeBismillah =
      surahNumber != kAlFatihahSurahNumber &&
      surahNumber != kAtTawbahSurahNumber;

  final List<PreparedPageBlock> blocks = <PreparedPageBlock>[
    PreparedHeaderBlock(surahNumber: surahNumber),
  ];

  if (includeBismillah) {
    blocks.add(
      PreparedSpacerBlock(
        height: _scaledGap(
          lineHeight,
          factor: _headerToBismillahGapFactor,
          min: _headerToBismillahMinGap,
          max: _headerToBismillahMaxGap,
        ),
      ),
    );
    blocks.add(const PreparedBismillahBlock());
    blocks.add(
      PreparedSpacerBlock(
        height: _scaledGap(
          lineHeight,
          factor: _bismillahToTextGapFactor,
          min: _bismillahToTextMinGap,
          max: _bismillahToTextMaxGap,
        ),
      ),
    );
  } else {
    blocks.add(
      PreparedSpacerBlock(
        height: _scaledGap(
          lineHeight,
          factor: _headerToTextGapFactor,
          min: _headerToTextMinGap,
          max: _headerToTextMaxGap,
        ),
      ),
    );
  }

  blocks.addAll(selectedTextBlocks);

  final PreparedQuranPage page = PreparedQuranPage(
    metrics: metrics,
    blocks: blocks,
  );

  return SelectedQuranRangeComposition(
    page: page,
    estimatedHeight: _estimatedCompositionHeight(
      page,
      viewportSize: viewportSize,
      headerFontSizeMultiplier: headerFontSizeMultiplier,
    ),
  );
}

QuranLayoutMetrics _compositionMetrics(QuranLayoutMetrics source) {
  final double verticalPadding = _scaledGap(
    source.fontSize * source.fontHeight,
    factor: _compositionVerticalPaddingFactor,
    min: _compositionMinVerticalPadding,
    max: _compositionMaxVerticalPadding,
  );

  return QuranLayoutMetrics(
    fontSize: source.fontSize,
    fontHeight: source.fontHeight,
    isScrollable: source.isScrollable,
    padding: EdgeInsets.only(
      left: source.padding.left,
      top: verticalPadding,
      right: source.padding.right,
      bottom: verticalPadding,
    ),
    lineSpacing: source.lineSpacing,
    letterSpacing: source.letterSpacing,
    bismillahHeight: source.bismillahHeight,
    verseHorizontalPadding: source.verseHorizontalPadding,
    bismillahHorizontalPadding: source.bismillahHorizontalPadding,
  );
}

double _estimatedCompositionHeight(
  PreparedQuranPage page, {
  required Size viewportSize,
  required double headerFontSizeMultiplier,
}) {
  final QuranLayoutMetrics metrics = page.metrics;
  var height = metrics.padding.vertical;
  var previousWasTextBlock = false;

  for (final PreparedPageBlock block in page.blocks) {
    if (block is PreparedHeaderBlock) {
      height += const CalibratedSurahHeaderBannerLayoutPolicy()
          .calculate(
            SurahHeaderBannerLayoutInput(
              viewportWidth: viewportSize.width,
              viewportHeight: viewportSize.height,
              isLandscape: viewportSize.width > viewportSize.height,
              fontSizeMultiplier: headerFontSizeMultiplier,
            ),
          )
          .height;
      previousWasTextBlock = false;
      continue;
    }

    if (block is PreparedBismillahBlock) {
      height += metrics.bismillahHeight;
      previousWasTextBlock = false;
      continue;
    }

    if (block is PreparedSpacerBlock) {
      height += block.height;
      previousWasTextBlock = false;
      continue;
    }

    if (block is PreparedTextBlock) {
      if (previousWasTextBlock) {
        height += metrics.lineSpacing;
      }
      height += block.painter.height;
      previousWasTextBlock = true;
    }
  }

  return height + _compositionHeightSafetyInset;
}

double _scaledGap(
  double lineHeight, {
  required double factor,
  required double min,
  required double max,
}) {
  return (lineHeight * factor).clamp(min, max).toDouble();
}
