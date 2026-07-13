import 'package:quran_qcf/quran_qcf.dart';

import 'entities/khatma_plan.dart';

/// Resolves and validates explicit Khatma reading boundaries.
abstract final class KhatmaPlanBoundaries {
  static int? pageForSurahAyah(int surah, int ayah) {
    if (surah < 1 || surah > 114) return null;
    final int maxAyah = getVerseCount(surah);
    if (ayah < 1 || ayah > maxAyah) return null;
    return getPageNumber(surah, ayah);
  }

  static bool isOrderedSurahRange({
    required int startSurah,
    required int startAyah,
    required int endSurah,
    required int endAyah,
  }) {
    if (startSurah > endSurah) return false;
    if (startSurah == endSurah && startAyah > endAyah) return false;
    final int? startPage = pageForSurahAyah(startSurah, startAyah);
    final int? endPage = pageForSurahAyah(endSurah, endAyah);
    return startPage != null && endPage != null && startPage <= endPage;
  }

  static bool isValidPageRange(int startPage, int endPage) =>
      startPage >= KhatmaPlan.firstQuranPage &&
      endPage <= KhatmaPlan.lastQuranPage &&
      startPage <= endPage;

  static int durationDaysFromTargetDate({
    required DateTime startDate,
    required DateTime targetDate,
  }) {
    final DateTime start = _dateOnly(startDate);
    final DateTime target = _dateOnly(targetDate);
    return target.difference(start).inDays + 1;
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
