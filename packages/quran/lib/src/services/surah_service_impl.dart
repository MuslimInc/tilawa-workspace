import '../data/suwar.dart';
import '../quran_exception.dart';
import 'interfaces/surah_service.dart';

/// Implementation of [SurahService] using local data sources.
///
/// Follows Single Responsibility Principle - only handles surah metadata.
class SurahServiceImpl implements SurahService {
  const SurahServiceImpl();

  /// Validates surah number is in valid range (1-114).
  void _validateSurahNumber(int surahNumber) {
    if (surahNumber > 114 || surahNumber <= 0) {
      throw const QuranException('No Surah found with given surahNumber');
    }
  }

  @override
  String getName(int surahNumber) {
    _validateSurahNumber(surahNumber);
    return surah[surahNumber - 1]['name'] as String;
  }

  @override
  String getNameEnglish(int surahNumber) {
    _validateSurahNumber(surahNumber);
    return surah[surahNumber - 1]['english'] as String;
  }

  @override
  String getNameArabic(int surahNumber) {
    _validateSurahNumber(surahNumber);
    return surah[surahNumber - 1]['arabic'] as String;
  }

  @override
  String getPlaceOfRevelation(int surahNumber) {
    _validateSurahNumber(surahNumber);
    return surah[surahNumber - 1]['place'] as String;
  }

  @override
  int getVerseCount(int surahNumber) {
    _validateSurahNumber(surahNumber);
    return surah[surahNumber - 1]['aya'] as int;
  }
}
