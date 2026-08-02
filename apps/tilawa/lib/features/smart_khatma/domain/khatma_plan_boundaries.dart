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

  /// First Mushaf page of [juz] (1–30), or null when invalid.
  static int? pageForJuz(int juz) {
    final Juz? part = getJuz(juz);
    if (part == null) return null;
    return pageForSurahAyah(part.start.surah, part.start.verse);
  }

  /// First surah/ayah pair that opens [page], or null when invalid.
  static ({int surah, int ayah})? firstVerseOnPage(int page) {
    if (page < KhatmaPlan.firstQuranPage || page > KhatmaPlan.lastQuranPage) {
      return null;
    }
    try {
      final List<PageSurahEntry> entries = getPageData(page);
      if (entries.isEmpty) return null;
      final PageSurahEntry first = entries.first;
      return (surah: first.surah, ayah: first.start);
    } on Object {
      return null;
    }
  }

  /// Last surah/ayah pair that closes [page], or null when invalid.
  static ({int surah, int ayah})? lastVerseOnPage(int page) {
    if (page < KhatmaPlan.firstQuranPage || page > KhatmaPlan.lastQuranPage) {
      return null;
    }
    try {
      final List<PageSurahEntry> entries = getPageData(page);
      if (entries.isEmpty) return null;
      final PageSurahEntry last = entries.last;
      return (surah: last.surah, ayah: last.end);
    } on Object {
      return null;
    }
  }

  static int? juzForPage(int page) {
    final ({int surah, int ayah})? verse = firstVerseOnPage(page);
    if (verse == null) return null;
    final int juz = getJuzNumber(verse.surah, verse.ayah);
    return juz >= 1 && juz <= 30 ? juz : null;
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
