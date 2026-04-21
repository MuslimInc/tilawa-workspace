import 'quran_data_service_impl.dart';
import 'search_service_impl.dart';
import 'surah_service_impl.dart';
import 'text_normalization_service_impl.dart';
import 'verse_service_impl.dart';

/// Provides global access to Quran service instances.
///
/// This class implements the Service Locator pattern, providing
/// singleton instances of all services for convenience functions.
///
/// For dependency injection in production code, prefer injecting
/// the interfaces directly rather than using these global instances.
class QuranServiceLocator {
  QuranServiceLocator._();

  /// Singleton instance of [QuranDataServiceImpl].
  static const quranDataService = QuranDataServiceImpl();

  /// Singleton instance of [SurahServiceImpl].
  static const surahService = SurahServiceImpl();

  /// Singleton instance of [VerseServiceImpl].
  static const verseService = VerseServiceImpl();

  /// Singleton instance of [SearchServiceImpl].
  static const searchService = SearchServiceImpl();

  /// Singleton instance of [TextNormalizationServiceImpl].
  static const textNormalizationService = TextNormalizationServiceImpl();
}
