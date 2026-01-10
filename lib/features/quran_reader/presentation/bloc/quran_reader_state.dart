part of 'quran_reader_bloc.dart';

enum QuranReaderStatus { initial, loading, loaded, error }

@freezed
abstract class QuranReaderState with _$QuranReaderState {
  const factory QuranReaderState({
    @Default(QuranReaderStatus.initial) QuranReaderStatus status,

    SurahContentEntity? currentSurah,

    QuranPageEntity? currentPage,

    @Default({}) Map<int, QuranPageEntity> pages,

    @Default(ReaderSettingsEntity()) ReaderSettingsEntity settings,

    @Default([]) List<AyahEntity> searchResults,

    @Default([]) List<SurahContentEntity> surahSearchResults,

    @Default('') String searchQuery,

    @Default(false) bool isSearching,

    int? scrollToAyah,

    int? jumpToPage,

    @Default('') String errorMessage,

    @Default(false) bool isPreloading,

    @Default(0) int pagesLoaded,

    @Default(604) int totalPagesToLoad,
  }) = _QuranReaderState;
}
