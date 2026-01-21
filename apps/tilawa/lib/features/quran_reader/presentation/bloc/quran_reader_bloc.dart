import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

import 'package:tilawa_core/errors/failures.dart';
import '../../domain/entities/entities.dart';
import '../../domain/usecases/usecases.dart';

part 'quran_reader_bloc.freezed.dart';

// Events
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
}

// States
@freezed
abstract class QuranReaderState with _$QuranReaderState {
  const factory QuranReaderState({
    @Default(QuranReaderStatus.initial) QuranReaderStatus status,
    SurahContentEntity? currentSurah,
    QuranPageEntity? currentPage,
    @Default({}) Map<int, QuranPageEntity> pages,
    @Default(ReaderSettingsEntity()) ReaderSettingsEntity settings,
    @Default([]) List<AyahEntity> searchResults,
    @Default('') String searchQuery,
    @Default(false) bool isSearching,
    int? scrollToAyah,
    @Default('') String errorMessage,
  }) = _QuranReaderState;
}

enum QuranReaderStatus { initial, loading, loaded, error }

@injectable
class QuranReaderBloc extends Bloc<QuranReaderEvent, QuranReaderState> {
  QuranReaderBloc(
    this._getSurahContentUseCase,
    this._getQuranPageUseCase,
    this._loadReaderSettingsUseCase,
    this._saveReaderSettingsUseCase,
    this._saveLastReadPositionUseCase,
    this._searchAyahsUseCase,
  ) : super(const QuranReaderState()) {
    on<_LoadSurah>(_onLoadSurah);
    on<_LoadPage>(_onLoadPage);
    on<_LoadSettings>(_onLoadSettings);
    on<_UpdateSettings>(_onUpdateSettings);
    on<_UpdateFontSize>(_onUpdateFontSize);
    on<_ToggleTranslation>(_onToggleTranslation);
    on<_ScrollToAyah>(_onScrollToAyah);
    on<_SaveLastRead>(_onSaveLastRead);
    on<_SearchAyahs>(_onSearchAyahs);
    on<_ClearSearch>(_onClearSearch);
  }

  final GetSurahContentUseCase _getSurahContentUseCase;
  final GetQuranPageUseCase _getQuranPageUseCase;
  final LoadReaderSettingsUseCase _loadReaderSettingsUseCase;
  final SaveReaderSettingsUseCase _saveReaderSettingsUseCase;
  final SaveLastReadPositionUseCase _saveLastReadPositionUseCase;
  final SearchAyahsUseCase _searchAyahsUseCase;

  Future<void> _onLoadSurah(
    _LoadSurah event,
    Emitter<QuranReaderState> emit,
  ) async {
    emit(state.copyWith(status: QuranReaderStatus.loading));

    final Either<Failure, SurahContentEntity> result =
        await _getSurahContentUseCase.call(surahNumber: event.surahNumber);

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: QuranReaderStatus.error,
          errorMessage: failure.toString(),
        ),
      ),
      (surah) => emit(
        state.copyWith(status: QuranReaderStatus.loaded, currentSurah: surah),
      ),
    );
  }

  Future<void> _onLoadPage(
    _LoadPage event,
    Emitter<QuranReaderState> emit,
  ) async {
    // If page is already cached, just update current page
    if (state.pages.containsKey(event.pageNumber)) {
      emit(state.copyWith(currentPage: state.pages[event.pageNumber]));
      return;
    }

    // Only set loading if we don't have any pages yet (initial load)
    if (state.pages.isEmpty) {
      emit(state.copyWith(status: QuranReaderStatus.loading));
    }

    final Either<Failure, QuranPageEntity> result = await _getQuranPageUseCase
        .call(pageNumber: event.pageNumber);

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: QuranReaderStatus.error,
          errorMessage: failure.toString(),
        ),
      ),
      (page) {
        final newPages = Map<int, QuranPageEntity>.from(state.pages);
        newPages[page.pageNumber] = page;
        emit(
          state.copyWith(
            status: QuranReaderStatus.loaded,
            currentPage: page,
            pages: newPages,
          ),
        );
      },
    );
  }

  Future<void> _onLoadSettings(
    _LoadSettings event,
    Emitter<QuranReaderState> emit,
  ) async {
    final Either<Failure, ReaderSettingsEntity> result =
        await _loadReaderSettingsUseCase.call();

    result.fold((failure) {
      // Use default settings on error
    }, (settings) => emit(state.copyWith(settings: settings)));
  }

  Future<void> _onUpdateSettings(
    _UpdateSettings event,
    Emitter<QuranReaderState> emit,
  ) async {
    await _saveReaderSettingsUseCase.call(settings: event.settings);
    emit(state.copyWith(settings: event.settings));
  }

  Future<void> _onUpdateFontSize(
    _UpdateFontSize event,
    Emitter<QuranReaderState> emit,
  ) async {
    final ReaderSettingsEntity newSettings = state.settings.copyWith(
      fontSize: event.fontSize,
    );
    await _saveReaderSettingsUseCase.call(settings: newSettings);
    emit(state.copyWith(settings: newSettings));
  }

  Future<void> _onToggleTranslation(
    _ToggleTranslation event,
    Emitter<QuranReaderState> emit,
  ) async {
    final ReaderSettingsEntity newSettings = state.settings.copyWith(
      showTranslation: !state.settings.showTranslation,
    );
    await _saveReaderSettingsUseCase.call(settings: newSettings);
    emit(state.copyWith(settings: newSettings));
  }

  void _onScrollToAyah(_ScrollToAyah event, Emitter<QuranReaderState> emit) {
    emit(state.copyWith(scrollToAyah: event.ayahNumber));
    // Clear after setting to allow re-scrolling to same ayah
    emit(state.copyWith(scrollToAyah: null));
  }

  Future<void> _onSaveLastRead(
    _SaveLastRead event,
    Emitter<QuranReaderState> emit,
  ) async {
    await _saveLastReadPositionUseCase.call(
      surahNumber: event.surahNumber,
      ayahNumber: event.ayahNumber,
    );
  }

  Future<void> _onSearchAyahs(
    _SearchAyahs event,
    Emitter<QuranReaderState> emit,
  ) async {
    if (event.query.isEmpty) {
      add(const QuranReaderEvent.clearSearch());
      return;
    }

    emit(state.copyWith(isSearching: true, searchQuery: event.query));

    final Either<Failure, List<AyahEntity>> result = await _searchAyahsUseCase
        .call(query: event.query);

    result.fold(
      (failure) => emit(
        state.copyWith(isSearching: false, errorMessage: failure.toString()),
      ),
      (ayahs) => emit(state.copyWith(isSearching: false, searchResults: ayahs)),
    );
  }

  void _onClearSearch(_ClearSearch event, Emitter<QuranReaderState> emit) {
    emit(
      state.copyWith(searchQuery: '', searchResults: [], isSearching: false),
    );
  }
}
