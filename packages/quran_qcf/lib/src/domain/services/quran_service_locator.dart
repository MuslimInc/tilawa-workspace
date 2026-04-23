import '../../data/repositories/quran_data_service_impl.dart';
import '../../data/repositories/search_service_impl.dart';
import '../../data/repositories/surah_service_impl.dart';
import '../../data/repositories/text_normalization_service_impl.dart';
import '../../data/repositories/verse_service_impl.dart';
import '../repositories/quran_data_service.dart';
import '../repositories/search_service.dart';
import '../repositories/surah_service.dart';
import '../repositories/text_normalization_service.dart';
import '../repositories/verse_service.dart';

/// Provides global access to Quran service instances.
///
/// This class implements the Service Locator pattern, providing
/// singleton instances of all services for convenience functions.
///
/// **Deprecated**: For new code, prefer injecting the interfaces directly
/// via dependency injection rather than using global instances.
/// This class exists for backward compatibility with convenience functions.
class QuranServiceLocator {
  QuranServiceLocator._();

  /// Singleton instance of the [QuranDataService].
  static QuranDataService get quranDataService => const QuranDataServiceImpl();

  /// Singleton instance of the [SurahService].
  static SurahService get surahService => const SurahServiceImpl();

  /// Singleton instance of the [VerseService].
  static VerseService get verseService => const VerseServiceImpl();

  /// Singleton instance of the [SearchService].
  static SearchService get searchService => const SearchServiceImpl();

  /// Singleton instance of the [TextNormalizationService].
  static TextNormalizationService get textNormalizationService =>
      const TextNormalizationServiceImpl();
}
