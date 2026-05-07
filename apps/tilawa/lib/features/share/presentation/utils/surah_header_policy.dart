import 'package:flutter/foundation.dart';

const int kAlFatihahSurahNumber = 1;
const int kAtTawbahSurahNumber = 9;

enum SurahHeaderReason { openingAyah, initialSelection, omitted }

@immutable
class SurahHeaderDecision {
  const SurahHeaderDecision({
    required this.includeBanner,
    required this.includeBismillah,
    required this.surahNumber,
    required this.reason,
  });

  final bool includeBanner;
  final bool includeBismillah;
  final int surahNumber;
  final SurahHeaderReason reason;
}

SurahHeaderDecision decideSurahHeader({
  required int surahNumber,
  required bool selectionTouchesOpeningAyah,
  required bool isInitialSelection,
}) {
  final reason = selectionTouchesOpeningAyah
      ? SurahHeaderReason.openingAyah
      : isInitialSelection
      ? SurahHeaderReason.initialSelection
      : SurahHeaderReason.omitted;
  final includeBanner = reason != SurahHeaderReason.omitted;

  return SurahHeaderDecision(
    includeBanner: includeBanner,
    includeBismillah:
        includeBanner &&
        surahNumber != kAlFatihahSurahNumber &&
        surahNumber != kAtTawbahSurahNumber,
    surahNumber: surahNumber,
    reason: reason,
  );
}
