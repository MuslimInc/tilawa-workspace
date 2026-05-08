import 'package:flutter/foundation.dart';
import 'package:quran_qcf/quran_qcf.dart';

const double kDefaultSelectionCropDiacriticInset = 4.0;

@immutable
class SelectionCropWindow {
  const SelectionCropWindow({
    required this.top,
    required this.bottom,
    required this.height,
  });

  final double top;
  final double bottom;
  final double height;
}

SelectionCropWindow? selectedCropWindow(
  List<PreparedPageBlock> blocks, {
  required QuranLayoutMetrics metrics,
  required int surahNumber,
  required int fromAyah,
  required int toAyah,
  double diacriticSafetyInset = kDefaultSelectionCropDiacriticInset,
}) {
  double yOffset = 0;
  double? top;
  double? bottom;
  var previousWasTextBlock = false;

  for (final block in blocks) {
    if (block is PreparedHeaderBlock || block is PreparedBismillahBlock) {
      previousWasTextBlock = false;
      continue;
    }

    if (block is PreparedSpacerBlock) {
      yOffset += block.height;
      previousWasTextBlock = false;
      continue;
    }

    if (block is! PreparedTextBlock) {
      continue;
    }

    if (previousWasTextBlock) {
      yOffset += metrics.lineSpacing;
    }

    final blockTop = yOffset;
    final blockBottom = blockTop + block.painter.height;
    final hasSelectedVerse = textBlockHasSelectedVerse(
      block,
      surahNumber: surahNumber,
      fromAyah: fromAyah,
      toAyah: toAyah,
    );

    if (hasSelectedVerse) {
      top ??= blockTop;
      bottom = blockBottom;
    }

    yOffset = blockBottom;
    previousWasTextBlock = true;
  }

  if (top == null || bottom == null || bottom <= top) {
    return null;
  }

  final safeTop = (top - diacriticSafetyInset).clamp(0.0, double.infinity);
  return SelectionCropWindow(
    top: safeTop,
    bottom: bottom,
    height: bottom - safeTop,
  );
}

bool textBlockHasSelectedVerse(
  PreparedTextBlock block, {
  required int surahNumber,
  required int fromAyah,
  required int toAyah,
}) {
  return block.metadata.any(
    (word) =>
        word.surah == surahNumber &&
        word.verse >= fromAyah &&
        word.verse <= toAyah,
  );
}
