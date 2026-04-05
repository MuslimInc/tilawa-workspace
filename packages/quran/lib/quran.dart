/// Quran Reader Library
///
/// A comprehensive Dart library for accessing Quran data including verses,
/// surahs, pages, and juz information.
///
/// ## Architecture
/// This library follows Clean Architecture and SOLID principles:
/// - **Interfaces**: Define contracts in `src/services/interfaces/`
/// - **Implementations**: Concrete implementations in `src/services/`
/// - **Data**: Raw data sources in `src/data/`
/// - **Constants**: Quran-related constants in `src/constants/`
/// - **Functions**: Convenience functions in `src/services/functions/`
///
/// ## Usage
/// You can use the global convenience functions for simple access:
/// ```dart
/// final verse = getVerse(1, 1);
/// final surahName = getSurahName(1);
/// ```
///
/// Or inject the service interfaces for better testability:
/// ```dart
/// final verseService = VerseServiceImpl();
/// final verse = verseService.getVerse(1, 1);
/// ```
///
/// Or use the service locator for quick access to service instances:
/// ```dart
/// final verse = QuranServiceLocator.verseService.getVerse(1, 1);
/// ```
library;

// =============================================================================
// CONSTANTS
// =============================================================================
export 'src/constants/quran_constants.dart';
// =============================================================================
// DATA (for advanced usage)
// =============================================================================
export 'src/data/juzs.dart'
    show Juz, getAllJuz, getJuz, getJuzForVerse, juzData;
export 'src/data/quarters.dart'
    show
        Quarter,
        getAllQuarters,
        getHizbForVerse,
        getQuarter,
        getQuarterForVerse,
        quartersData,
        totalQuarters;
// =============================================================================
// WIDGETS
// =============================================================================
export 'src/header_widget.dart';
// =============================================================================
// HELPERS
// =============================================================================
export 'src/helpers/convert_to_arabic_number.dart';
export 'src/layout/quran_layout_strategy.dart'
    show QuranLayoutMetrics, StandardQuranLayoutStrategy;
export 'src/page_content.dart';
export 'src/qcf_verse.dart';
// =============================================================================
// EXCEPTIONS
// =============================================================================
export 'src/quran_exception.dart';
export 'src/quran_page_view.dart';
// =============================================================================
// CONVENIENCE FUNCTIONS (backward compatible global functions)
// =============================================================================
export 'src/services/functions/page_functions.dart';
export 'src/services/functions/search_functions.dart';
export 'src/services/functions/surah_functions.dart';
export 'src/services/functions/verse_functions.dart';
export 'src/services/idle_scheduler.dart';
// =============================================================================
// SERVICE INTERFACES (for dependency injection)
// =============================================================================
export 'src/services/interfaces/quran_data_service.dart';
export 'src/services/interfaces/search_service.dart';
export 'src/services/interfaces/surah_service.dart';
export 'src/services/interfaces/text_normalization_service.dart';
export 'src/services/interfaces/verse_service.dart';
export 'src/services/page_snapshot_service.dart';
// =============================================================================
// SERVICE IMPLEMENTATIONS
// =============================================================================
export 'src/services/quran_data_service_impl.dart';
export 'src/services/quran_font_service.dart';
export 'src/services/quran_page_preparation_service.dart';
export 'src/services/quran_service_locator.dart';
export 'src/services/search_service_impl.dart';
export 'src/services/surah_service_impl.dart';
export 'src/services/text_normalization_service_impl.dart';
export 'src/services/verse_service_impl.dart';
