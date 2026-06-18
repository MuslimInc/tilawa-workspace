import 'package:quran_qcf/quran_qcf.dart';

/// Search helpers shared by the surah index sheet and Quran hub screen.
abstract final class SurahIndexFilter {
  static String normalizeSearchText(String value) {
    return value
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED\u0640]'), '')
        .replaceAll(RegExp(r'[^a-z0-9\u0600-\u06FF]+'), '');
  }

  /// Returns true if [surahNumber] matches [query].
  static bool matchesSearch(int surahNumber, String query) {
    if (query.isEmpty) {
      return true;
    }

    final String lowerQuery = query.toLowerCase();
    final String normalizedQuery = normalizeSearchText(query);
    final String name = getSurahName(surahNumber).toLowerCase();
    final String arabicName = getSurahNameArabic(surahNumber);
    final String englishName = getSurahNameEnglish(surahNumber);
    final String number = surahNumber.toString();

    return name.contains(lowerQuery) ||
        arabicName.contains(query) ||
        englishName.toLowerCase().contains(lowerQuery) ||
        normalizeSearchText(name).contains(normalizedQuery) ||
        normalizeSearchText(arabicName).contains(normalizedQuery) ||
        normalizeSearchText(englishName).contains(normalizedQuery) ||
        number == lowerQuery;
  }

  static List<int> filteredSurahs(String query) {
    return [
      for (int i = 1; i <= 114; i++)
        if (matchesSearch(i, query)) i,
    ];
  }
}
