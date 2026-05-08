import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:quran_qcf/quran_qcf.dart';

import 'share_ayah_range_utils.dart';

const double reelCanvasWidth = 1080;
const double reelCanvasHeight = 1920;
const double reelSafeZoneTopFraction = 0.08;
const double reelSafeZoneBottomFraction = 0.14;

@immutable
class VideoPageSpec {
  const VideoPageSpec({
    required this.pageNumber,
    required this.fromAyah,
    required this.toAyah,
    this.isInitialSelection = false,
  });

  final int pageNumber;
  final int fromAyah;
  final int toAyah;
  final bool isInitialSelection;
}

List<VideoPageSpec> buildVideoPageSpecs({
  required int surahNumber,
  required int fromAyah,
  required int toAyah,
  bool isInitialSelection = false,
}) {
  final ayahRange = normalizeShareAyahRange(
    surahNumber: surahNumber,
    fromAyah: fromAyah,
    toAyah: toAyah,
  );
  final int startPage = getPageNumber(surahNumber, ayahRange.fromAyah);
  final int endPage = getPageNumber(surahNumber, ayahRange.toAyah);
  final List<VideoPageSpec> specs = <VideoPageSpec>[];

  for (int pageNumber = startPage; pageNumber <= endPage; pageNumber++) {
    final List<PageSurahEntry> pageEntries = getPageData(pageNumber);

    for (final PageSurahEntry entry in pageEntries) {
      if (entry.surah != surahNumber) {
        continue;
      }

      final int pageStartAyah = entry.start;
      final int pageEndAyah = entry.end;
      final int pageFromAyah = math.max(ayahRange.fromAyah, pageStartAyah);
      final int pageToAyah = math.min(ayahRange.toAyah, pageEndAyah);

      if (pageFromAyah <= pageToAyah) {
        specs.add(
          VideoPageSpec(
            pageNumber: pageNumber,
            fromAyah: pageFromAyah,
            toAyah: pageToAyah,
            isInitialSelection: isInitialSelection,
          ),
        );
      }
    }
  }

  return specs;
}
