import 'package:dartz_plus/dartz_plus.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
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

  const factory QuranReaderEvent.jumpToPage(int pageNumber) = _JumpToPage;

  const factory QuranReaderEvent.preloadAllPages() = _PreloadAllPages;
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

enum QuranReaderStatus { initial, loading, loaded, error }

@injectable
class QuranReaderBloc extends HydratedBloc<QuranReaderEvent, QuranReaderState> {
  QuranReaderBloc(
    this._getSurahContentUseCase,

    this._getQuranPageUseCase,

    this._loadReaderSettingsUseCase,

    this._saveReaderSettingsUseCase,

    this._saveLastReadPositionUseCase,

    this._searchAyahsUseCase,

    this._searchSurahsUseCase,
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

    on<_JumpToPage>(_onJumpToPage);

    on<_PreloadAllPages>(_onPreloadAllPages);
  }

  final GetSurahContentUseCase _getSurahContentUseCase;

  final GetQuranPageUseCase _getQuranPageUseCase;

  final LoadReaderSettingsUseCase _loadReaderSettingsUseCase;

  final SaveReaderSettingsUseCase _saveReaderSettingsUseCase;

  final SaveLastReadPositionUseCase _saveLastReadPositionUseCase;

  final SearchAyahsUseCase _searchAyahsUseCase;

  final SearchSurahsUseCase _searchSurahsUseCase;

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

      (surah) {
        emit(
          state.copyWith(status: QuranReaderStatus.loaded, currentSurah: surah),
        );

        // If we have a start page, trigger a jump

        final int? startPage = surah.startPage;

        if (startPage != null) {
          add(QuranReaderEvent.jumpToPage(startPage));
        }
      },
    );
  }

  Future<void> _onLoadPage(
    _LoadPage event,

    Emitter<QuranReaderState> emit,
  ) async {
    // If page is already cached WITH words, just update current page

    if (state.pages.containsKey(event.pageNumber)) {
      final QuranPageEntity page = state.pages[event.pageNumber]!;

      if (page.ayahs.isNotEmpty && page.ayahs.first.words != null) {
        emit(state.copyWith(currentPage: page));

        return;
      }
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

    final Future<Either<Failure, List<AyahEntity>>> searchAyahsFuture =
        _searchAyahsUseCase.call(query: event.query);

    final Future<Either<Failure, List<SurahContentEntity>>> searchSurahsFuture =
        _searchSurahsUseCase.call(query: event.query);

    final List<Either<Failure, List<Object>>> results = await Future.wait([
      searchAyahsFuture,

      searchSurahsFuture,
    ]);

    final ayahsResult = results[0] as Either<Failure, List<AyahEntity>>;

    final surahsResult =
        results[1] as Either<Failure, List<SurahContentEntity>>;

    List<AyahEntity> ayahs = [];

    List<SurahContentEntity> surahs = [];

    String? error;

    ayahsResult.fold(
      (failure) => error = failure.toString(),

      (data) => ayahs = data,
    );

    surahsResult.fold(
      (failure) => error = failure.toString(),

      (data) => surahs = data,
    );

    emit(
      state.copyWith(
        isSearching: false,

        searchResults: ayahs,

        surahSearchResults: surahs,

        errorMessage: error ?? '',
      ),
    );
  }

  void _onClearSearch(_ClearSearch event, Emitter<QuranReaderState> emit) {
    emit(
      state.copyWith(
        searchQuery: '',

        searchResults: [],

        surahSearchResults: [],

        isSearching: false,
      ),
    );
  }

  void _onJumpToPage(_JumpToPage event, Emitter<QuranReaderState> emit) {
    emit(state.copyWith(jumpToPage: event.pageNumber));

    // Immediately clear so the UI only sees the jump command once

    emit(state.copyWith(jumpToPage: null));
  }

  /// Preloads all 604 Quran pages in parallel batches.
  Future<void> _onPreloadAllPages(
    _PreloadAllPages event,
    Emitter<QuranReaderState> emit,
  ) async {
    // If already preloaded, skip
    if (state.pages.length >= 604) {
      return;
    }

    emit(
      state.copyWith(
        isPreloading: true,
        pagesLoaded: state.pages.length,
        totalPagesToLoad: 604,
      ),
    );

    const batchSize = 10;
    final Map<int, QuranPageEntity> allPages = Map.from(state.pages);

    for (var start = 1; start <= 604; start += batchSize) {
      if (isClosed) {
        return;
      }

      final int end = (start + batchSize - 1).clamp(1, 604);
      final List<Future<void>> batch = [];

      for (var pageNum = start; pageNum <= end; pageNum++) {
        // Skip already loaded pages
        if (allPages.containsKey(pageNum)) {
          continue;
        }

        batch.add(
          _getQuranPageUseCase.call(pageNumber: pageNum).then((result) {
            result.fold(
              (failure) {
                // Log error but continue loading other pages
              },
              (page) {
                allPages[page.pageNumber] = page;
              },
            );
          }),
        );
      }

      await Future.wait(batch);

      emit(
        state.copyWith(pages: Map.from(allPages), pagesLoaded: allPages.length),
      );
    }

    emit(
      state.copyWith(
        isPreloading: false,
        status: QuranReaderStatus.loaded,
        pages: allPages,
        pagesLoaded: allPages.length,
      ),
    );
  }

  @override
  QuranReaderState? fromJson(Map<String, dynamic> json) {
    try {
      // Restore pages from hydrated storage
      final Map<int, QuranPageEntity> pages = {};
      if (json['pages'] != null && json['pages'] is Map) {
        final pagesJson = json['pages'] as Map<String, dynamic>;
        for (final MapEntry<String, dynamic> entry in pagesJson.entries) {
          final int pageNum = int.parse(entry.key);
          final pageData = entry.value as Map<String, dynamic>;
          pages[pageNum] = QuranPageEntity.fromJson(pageData);
        }
      }

      if (pages.isNotEmpty) {
        return QuranReaderState(
          status: QuranReaderStatus.loaded,
          pages: pages,
          pagesLoaded: pages.length,
        );
      }
      return const QuranReaderState();
    } catch (e) {
      return const QuranReaderState();
    }
  }

  @override
  Map<String, dynamic>? toJson(QuranReaderState state) {
    // Only persist if pages are loaded
    if (state.pages.isEmpty) {
      return null;
    }

    try {
      // Serialize pages map to JSON
      final Map<String, dynamic> pagesJson = {};
      for (final MapEntry<int, QuranPageEntity> entry in state.pages.entries) {
        pagesJson[entry.key.toString()] = entry.value.toJson();
      }

      return {'pages': pagesJson};
    } catch (e) {
      return null;
    }
  }
}
