import '../../domain/repositories/surah_service.dart';
import '../../quran_exception.dart';
import '../sources/suwar.dart';

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
    return surah[surahNumber]!.name;
  }

  @override
  String getNameArabic(int surahNumber) {
    _validateSurahNumber(surahNumber);
    return surah[surahNumber]!.arabicName;
  }

  @override
  String getPlaceOfRevelation(int surahNumber) {
    _validateSurahNumber(surahNumber);
    return surah[surahNumber]!.placeOfRevelation;
  }

  @override
  int getVerseCount(int surahNumber) {
    _validateSurahNumber(surahNumber);
    return surah[surahNumber]!.ayahCount;
  }

  @override
  String getSurahInfo(int surahNumber) {
    _validateSurahNumber(surahNumber);
    return surah[surahNumber]!.surahInfo;
  }

  @override
  String getSurahInfoFromBook(int surahNumber) {
    _validateSurahNumber(surahNumber);
    return surah[surahNumber]!.surahInfoFromBook;
  }

  @override
  String getSurahNames(int surahNumber) {
    _validateSurahNumber(surahNumber);
    return surah[surahNumber]!.surahNames;
  }

  @override
  String getSurahNamesFromBook(int surahNumber) {
    _validateSurahNumber(surahNumber);
    return surah[surahNumber]!.surahNamesFromBook;
  }
}
