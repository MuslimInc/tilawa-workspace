import 'package:freezed_annotation/freezed_annotation.dart';

part 'quran_page_data.freezed.dart';

/// Immutable data class representing a fully-rendered Quran page.
///
/// This entity is designed for pure presentation - it contains all data
/// needed to render a page without any async loading or bloc access.
@freezed
abstract class QuranPageData with _$QuranPageData {
  const factory QuranPageData({
    required int pageNumber,
    required int juzNumber,
    required int hizbNumber,
    required List<SurahSection> surahSections,
  }) = _QuranPageData;
  const QuranPageData._();

  /// Empty page for initialization
  static QuranPageData empty(int pageNumber) => QuranPageData(
    pageNumber: pageNumber,
    juzNumber: ((pageNumber - 1) ~/ 20) + 1,
    hizbNumber: ((pageNumber - 1) ~/ 10) + 1,
    surahSections: const [],
  );
}

/// A section of a surah that appears on a page.
///
/// A page may contain multiple surah sections (e.g., when one surah ends
/// and another begins on the same page).
@freezed
abstract class SurahSection with _$SurahSection {
  const factory SurahSection({
    required int surahNumber,
    required String surahNameArabic,
    required String surahNameEnglish,
    required bool isStartOfSurah,
    required List<AyahData> ayahs,
  }) = _SurahSection;
}

/// Immutable ayah data for display.
@freezed
abstract class AyahData with _$AyahData {
  const factory AyahData({required int ayahNumber, required String text}) =
      _AyahData;
}
