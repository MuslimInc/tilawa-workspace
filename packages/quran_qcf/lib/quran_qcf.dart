/// Quran Reader Library
///
/// A comprehensive Dart library for accessing Quran data including verses,
/// surahs, pages, and juz information.
///
/// ## Architecture
/// This library follows Clean Architecture and SOLID principles:
/// - **Interfaces**: Define contracts in `src/domain/repositories/`
/// - **Implementations**: Concrete implementations in `src/data/repositories/`
/// - **Data**: Raw data sources in `src/data/sources/`
/// - **Constants**: Quran-related constants in `src/constants/`
/// - **Functions**: Convenience functions in `src/domain/services/functions/`
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
export 'src/core/constants/quran_constants.dart';
export 'src/core/constants/surah_header_banner_constants.dart';
// =============================================================================
// SERVICE LOCATORS
// =============================================================================
export 'src/core/qcf_locator.dart';
// =============================================================================
// SERVICE INTERFACES & IMPLEMENTATIONS
// =============================================================================
export 'src/data/repositories/mushaf_service.dart';
export 'src/data/repositories/quran_data_service_impl.dart';
export 'src/data/repositories/search_service_impl.dart';
export 'src/data/repositories/surah_service_impl.dart';
export 'src/data/repositories/text_normalization_service_impl.dart';
export 'src/data/repositories/verse_service_impl.dart';
// =============================================================================
// DATA (for advanced usage)
// =============================================================================
export 'src/data/sources/juzs.dart'
    show Juz, getAllJuz, getJuz, getJuzForVerse, juzData;
export 'src/data/sources/quarters.dart'
    show
        Quarter,
        getAllQuarters,
        getHizbForVerse,
        getQuarter,
        getQuarterForVerse,
        quartersData,
        totalQuarters;
// =============================================================================
// HELPERS & MODELS
// =============================================================================
export 'src/domain/models/page_meta_info.dart';
export 'src/domain/models/quran_models.dart';
export 'src/domain/models/quran_page_models.dart';
export 'src/domain/models/quran_special_line.dart';
export 'src/domain/models/quran_word_metadata.dart';
export 'src/domain/models/search_models.dart';
export 'src/domain/repositories/quran_data_service.dart';
export 'src/domain/repositories/quran_mushaf_service.dart';
export 'src/domain/repositories/search_service.dart';
export 'src/domain/repositories/surah_service.dart';
export 'src/domain/repositories/text_normalization_service.dart';
export 'src/domain/repositories/verse_service.dart';
// =============================================================================
// CONVENIENCE FUNCTIONS
// =============================================================================
export 'src/domain/services/functions/page_functions.dart';
export 'src/domain/services/functions/search_functions.dart';
export 'src/domain/services/functions/surah_functions.dart';
export 'src/domain/services/functions/verse_functions.dart';
export 'src/domain/services/quran_service_locator.dart';
export 'src/helpers/convert_to_arabic_number.dart';
export 'src/presentation/layout/quran_layout_strategy.dart'
    show StandardQuranLayoutStrategy;
export 'src/presentation/layout/quran_line_layout.dart';
export 'src/presentation/layout/surah_header_banner_layout.dart';
// =============================================================================
// PRESENTATION SERVICES
// =============================================================================
export 'src/presentation/services/idle_scheduler.dart';
export 'src/presentation/services/page_snapshot_service.dart';
export 'src/presentation/services/quran_font_service.dart';
export 'src/presentation/services/quran_page_preparation_service.dart';
// =============================================================================
// WIDGETS
// =============================================================================
export 'src/presentation/widgets/header_widget.dart';
export 'src/presentation/widgets/page_content.dart';
export 'src/presentation/widgets/qcf_verse.dart';
export 'src/presentation/widgets/quran_page_view.dart';
export 'src/presentation/widgets/surah_header_banner.dart';
export 'src/presentation/widgets/surah_header_glyph_provider.dart';
// =============================================================================
// EXCEPTIONS
// =============================================================================
export 'src/quran_exception.dart';
