import 'package:dartz_plus/dartz_plus.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/entities.dart';
import '../../domain/usecases/get_all_pages_use_case.dart';
import '../../domain/usecases/usecases.dart';

part 'quran_reader_bloc.freezed.dart';
part 'quran_reader_event.dart';
part 'quran_reader_state.dart';

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
    this._getAllPagesUseCase,
  ) : super(QuranReaderState(pages: _getInitialPages())) {
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

    on<_PrefetchPages>(_onPrefetchPages);

    on<_UpdateCurrentPage>(_onUpdateCurrentPage);

    // // Initialize pages map with placeholders if empty
    // if (state.pages.isEmpty) {
    //   add(const QuranReaderEvent.preloadAllPages());
    // }
  }

  // Pre-seed 604 pages to avoid loading states
  static Map<int, QuranPageEntity> _getInitialPages() {
    return {
      for (int i = 1; i <= 604; i++)
        i: QuranPageEntity(
          pageNumber: i,
          ayahs: [],
          juz: ((i - 1) ~/ 20) + 1,
          hizb: ((i - 1) ~/ 10) + 1,
        ),
    };
  }

  final GetSurahContentUseCase _getSurahContentUseCase;

  final GetQuranPageUseCase _getQuranPageUseCase;

  final LoadReaderSettingsUseCase _loadReaderSettingsUseCase;

  final SaveReaderSettingsUseCase _saveReaderSettingsUseCase;

  final SaveLastReadPositionUseCase _saveLastReadPositionUseCase;

  final SearchAyahsUseCase _searchAyahsUseCase;

  final SearchSurahsUseCase _searchSurahsUseCase;

  final GetAllPagesUseCase _getAllPagesUseCase;

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

      // If page has content, just update current page
      if (page.ayahs.isNotEmpty) {
        emit(
          state.copyWith(currentPage: page, status: QuranReaderStatus.loaded),
        );
        // Check if we need to hydrate words, but don't block
        if (page.ayahs.first.words == null) {
          // Proceed to fetch implementation below...
        } else {
          return;
        }
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

  Future<void> _onPrefetchPages(
    _PrefetchPages event,
    Emitter<QuranReaderState> emit,
  ) async {
    final Map<int, QuranPageEntity> newPages = Map.from(state.pages);
    var stateChanged = false;

    // Use a list of futures to fetch pages in parallel
    final List<Future<void>> fetchTasks = [];

    for (final int pageNumber in event.pageNumbers) {
      if (pageNumber < 1 || pageNumber > 604) {
        continue;
      }
      // Check if page is already loaded with content
      if (state.pages.containsKey(pageNumber) &&
          state.pages[pageNumber]!.ayahs.isNotEmpty) {
        continue;
      }

      fetchTasks.add(
        _getQuranPageUseCase.call(pageNumber: pageNumber).then((result) {
          result.fold(
            (failure) {
              // Ignore failures for prefetching
            },
            (page) {
              newPages[page.pageNumber] = page;
              stateChanged = true;
            },
          );
        }),
      );
    }

    if (fetchTasks.isEmpty) {
      return;
    }

    await Future.wait(fetchTasks);

    if (stateChanged) {
      emit(state.copyWith(pages: newPages));
    }
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

  /// Preloads all 604 Quran pages in one go.
  /// This loads the entire Quran text into memory for smooth scrolling.
  Future<void> _onPreloadAllPages(
    _PreloadAllPages event,
    Emitter<QuranReaderState> emit,
  ) async {
    // If we already have full content (checked by a sample, e.g., page 1), skip
    // Or we could check if pages.length == 604 AND checking content...
    // But safely, let's just check if we are already loading.
    if (state.isPreloading) return;

    emit(state.copyWith(isPreloading: true));

    final Either<Failure, Map<int, QuranPageEntity>> result =
        await _getAllPagesUseCase.call();

    result.fold(
      (failure) {
        // Log error but keep existing state (likely placeholders)
        emit(
          state.copyWith(isPreloading: false, errorMessage: failure.toString()),
        );
      },
      (pages) {
        emit(
          state.copyWith(
            isPreloading: false,
            pages: pages,
            pagesLoaded: pages.length,
          ),
        );
      },
    );
  }

  Future<void> _onUpdateCurrentPage(
    _UpdateCurrentPage event,
    Emitter<QuranReaderState> emit,
  ) async {
    emit(state.copyWith(currentPage: event.page));
  }

  @override
  QuranReaderState? fromJson(Map<String, dynamic> json) {
    try {
      if (json['settings'] != null) {
        return QuranReaderState(
          settings: ReaderSettingsEntity.fromJson(
            Map<String, dynamic>.from(json['settings'] as Map),
          ),
        );
      }
      return const QuranReaderState();
    } catch (e) {
      return const QuranReaderState();
    }
  }

  @override
  Map<String, dynamic>? toJson(QuranReaderState state) {
    try {
      return {'settings': state.settings.toJson()};
    } catch (e) {
      return null;
    }
  }
}
