part of 'quran_reader_bloc.dart';

@freezed
class QuranReaderEvent with _$QuranReaderEvent {
  const factory QuranReaderEvent.loadSurah(int surahNumber) = _LoadSurah;

  const factory QuranReaderEvent.loadPage(int pageNumber) = _LoadPage;

  const factory QuranReaderEvent.loadSettings() = _LoadSettings;

  const factory QuranReaderEvent.updateSettings(ReaderSettingsEntity settings) =
      _UpdateSettings;

  const factory QuranReaderEvent.updateFontSize(double fontSize) =
      _UpdateFontSize;

  const factory QuranReaderEvent.toggleTranslation() = _ToggleTranslation;

  const factory QuranReaderEvent.scrollToAyah(int ayahNumber) = _ScrollToAyah;

  const factory QuranReaderEvent.saveLastRead({
    required int surahNumber,

    int? ayahNumber,
  }) = _SaveLastRead;

  const factory QuranReaderEvent.searchAyahs(String query) = _SearchAyahs;

  const factory QuranReaderEvent.clearSearch() = _ClearSearch;

  const factory QuranReaderEvent.jumpToPage(int pageNumber) = _JumpToPage;

  const factory QuranReaderEvent.preloadAllPages() = _PreloadAllPages;

  const factory QuranReaderEvent.prefetchPages(List<int> pageNumbers) =
      _PrefetchPages;

  const factory QuranReaderEvent.updateCurrentPage(QuranPageEntity page) =
      _UpdateCurrentPage;
}
