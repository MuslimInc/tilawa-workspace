import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../domain/entities/entities.dart';
import '../../domain/usecases/usecases.dart';

part 'quran_reader_bloc.freezed.dart';

// Events
@freezed
class QuranReaderEvent with _$QuranReaderEvent {
  const factory QuranReaderEvent.loadSurah(
    int surahNumber, {
    @Default(true) bool loadStartPage,
  }) = _LoadSurah;
  const factory QuranReaderEvent.loadPage(int pageNumber) = _LoadPage;
  const factory QuranReaderEvent.scrollToAyah(int ayahNumber) = _ScrollToAyah;
  const factory QuranReaderEvent.saveLastRead({
    required int surahNumber,
    int? ayahNumber,
    int? page,
  }) = _SaveLastRead;
  const factory QuranReaderEvent.saveLastReadImmediate({
    required int surahNumber,
    int? ayahNumber,
    int? page,
  }) = _SaveLastReadImmediate;
  const factory QuranReaderEvent.loadLastRead() = _LoadLastRead;
  const factory QuranReaderEvent.searchAyahs(String query) = _SearchAyahs;
  const factory QuranReaderEvent.clearSearch() = _ClearSearch;
}

// States
@freezed
sealed class QuranReaderState with _$QuranReaderState {
  const factory QuranReaderState.initial() = QuranReaderInitial;
  const factory QuranReaderState.loading() = QuranReaderLoading;
  const factory QuranReaderState.pageLoaded({
    required QuranPageEntity currentPage,
    SurahContentEntity? currentSurah,
    int? initialPageHint,
    int? scrollToAyah,
  }) = QuranReaderPageLoaded;
  const factory QuranReaderState.searchSuccess({
    required List<AyahEntity> searchResults,
    required String searchQuery,
    @Default(false) bool isSearching,
  }) = QuranReaderSearchSuccess;
  const factory QuranReaderState.error(Failure failure) = QuranReaderError;
}

extension QuranReaderStateX on QuranReaderState {
  QuranPageEntity? get currentPage => switch (this) {
    QuranReaderPageLoaded(:final currentPage) => currentPage,
    _ => null,
  };

  SurahContentEntity? get currentSurah => switch (this) {
    QuranReaderPageLoaded(:final currentSurah) => currentSurah,
    _ => null,
  };

  int? get initialPageHint => switch (this) {
    QuranReaderPageLoaded(:final initialPageHint) => initialPageHint,
    _ => null,
  };

  int? get scrollToAyah => switch (this) {
    QuranReaderPageLoaded(:final scrollToAyah) => scrollToAyah,
    _ => null,
  };

  List<AyahEntity> get searchResults => switch (this) {
    QuranReaderSearchSuccess(:final searchResults) => searchResults,
    _ => [],
  };

  String get searchQuery => switch (this) {
    QuranReaderSearchSuccess(:final searchQuery) => searchQuery,
    _ => '',
  };

  bool get isSearching => switch (this) {
    QuranReaderSearchSuccess(:final isSearching) => isSearching,
    _ => false,
  };
}

@injectable
class QuranReaderBloc extends Bloc<QuranReaderEvent, QuranReaderState> {
  QuranReaderBloc(
    this._getSurahContentUseCase,
    this._getQuranPageUseCase,
    this._saveLastReadPositionUseCase,
    this._getLastReadPositionUseCase,
    this._searchAyahsUseCase,
    this._getStartPageForSurahUseCase,
  ) : super(const QuranReaderState.initial()) {
    on<_LoadSurah>(_onLoadSurah, transformer: restartable());
    on<_LoadPage>(
      _onLoadPage,
      transformer: (events, mapper) =>
          events.debounce(const Duration(milliseconds: 100)).switchMap(mapper),
    );
    on<_ScrollToAyah>(_onScrollToAyah);
    on<_SaveLastRead>(
      _onSaveLastRead,
      transformer: (events, mapper) =>
          events.debounce(const Duration(milliseconds: 500)).switchMap(mapper),
    );
    on<_SaveLastReadImmediate>(_onSaveLastReadImmediate);
    on<_LoadLastRead>(_onLoadLastRead, transformer: restartable());
    on<_SearchAyahs>(_onSearchAyahs, transformer: restartable());
    on<_ClearSearch>(_onClearSearch);
  }

  final GetSurahContentUseCase _getSurahContentUseCase;
  final GetQuranPageUseCase _getQuranPageUseCase;
  final SaveLastReadPositionUseCase _saveLastReadPositionUseCase;
  final GetLastReadPositionUseCase _getLastReadPositionUseCase;
  final SearchAyahsUseCase _searchAyahsUseCase;
  final GetStartPageForSurahUseCase _getStartPageForSurahUseCase;

  Future<void> _onLoadSurah(
    _LoadSurah event,
    Emitter<QuranReaderState> emit,
  ) async {
    emit(const QuranReaderState.loading());

    final result = await _getSurahContentUseCase.call(
      surahNumber: event.surahNumber,
    );

    result.fold((failure) => emit(QuranReaderState.error(failure)), (surah) {
      if (state is QuranReaderPageLoaded) {
        emit((state as QuranReaderPageLoaded).copyWith(currentSurah: surah));
      } else if (event.loadStartPage) {
        final startPage = _getStartPageForSurahUseCase.call(surah.number);
        add(QuranReaderEvent.loadPage(startPage));
      }
    });
  }

  Future<void> _onLoadPage(
    _LoadPage event,
    Emitter<QuranReaderState> emit,
  ) async {
    // We only show full loading if there's no page yet
    if (state is! QuranReaderPageLoaded) {
      emit(const QuranReaderState.loading());
    }

    final result = await _getQuranPageUseCase.call(
      pageNumber: event.pageNumber,
    );

    result.fold((failure) => emit(QuranReaderState.error(failure)), (page) {
      if (page.ayahs.isNotEmpty) {
        final firstSurahNum = page.ayahs.first.surahNumber;
        _triggerSideEffects(firstSurahNum, page.pageNumber);
      }

      emit(
        QuranReaderState.pageLoaded(
          currentPage: page,
          initialPageHint: page.pageNumber,
          // Preserve current surah if it matches the page
          currentSurah:
              state is QuranReaderPageLoaded &&
                  (state as QuranReaderPageLoaded).currentSurah?.number ==
                      page.ayahs.firstOrNull?.surahNumber
              ? (state as QuranReaderPageLoaded).currentSurah
              : null,
        ),
      );
    });
  }

  void _triggerSideEffects(int surahNumber, int pageNumber) {
    // Delegating side effects to events to keep the handler focused
    if (state is QuranReaderPageLoaded) {
      if ((state as QuranReaderPageLoaded).currentSurah?.number !=
          surahNumber) {
        add(QuranReaderEvent.loadSurah(surahNumber, loadStartPage: false));
      }
    } else {
      add(QuranReaderEvent.loadSurah(surahNumber, loadStartPage: false));
    }

    add(
      QuranReaderEvent.saveLastRead(surahNumber: surahNumber, page: pageNumber),
    );
  }

  void _onScrollToAyah(_ScrollToAyah event, Emitter<QuranReaderState> emit) {
    if (state is QuranReaderPageLoaded) {
      final s = state as QuranReaderPageLoaded;
      emit(s.copyWith(scrollToAyah: event.ayahNumber));
      // Reset scroll hint immediately after emitting
      emit(s.copyWith(scrollToAyah: null));
    }
  }

  Future<void> _onSaveLastRead(
    _SaveLastRead event,
    Emitter<QuranReaderState> emit,
  ) async {
    await _saveLastReadPositionUseCase.call(
      surahNumber: event.surahNumber,
      ayahNumber: event.ayahNumber,
      page: event.page,
    );
  }

  Future<void> _onSaveLastReadImmediate(
    _SaveLastReadImmediate event,
    Emitter<QuranReaderState> emit,
  ) async {
    await _saveLastReadPositionUseCase.call(
      surahNumber: event.surahNumber,
      ayahNumber: event.ayahNumber,
      page: event.page,
    );
  }

  Future<void> _onLoadLastRead(
    _LoadLastRead event,
    Emitter<QuranReaderState> emit,
  ) async {
    emit(const QuranReaderState.loading());
    final result = await _getLastReadPositionUseCase.call();

    result.fold((failure) => emit(QuranReaderState.error(failure)), (position) {
      final targetPage =
          position.page ??
          (position.surahNumber != null
              ? _getStartPageForSurahUseCase.call(position.surahNumber!)
              : 1);

      add(QuranReaderEvent.loadPage(targetPage));
    });
  }

  Future<void> _onSearchAyahs(
    _SearchAyahs event,
    Emitter<QuranReaderState> emit,
  ) async {
    if (event.query.isEmpty) {
      add(const QuranReaderEvent.clearSearch());
      return;
    }

    emit(
      QuranReaderState.searchSuccess(
        searchResults: state is QuranReaderSearchSuccess
            ? (state as QuranReaderSearchSuccess).searchResults
            : [],
        searchQuery: event.query,
        isSearching: true,
      ),
    );

    final result = await _searchAyahsUseCase.call(query: event.query);

    result.fold(
      (failure) => emit(QuranReaderState.error(failure)),
      (ayahs) => emit(
        QuranReaderState.searchSuccess(
          searchResults: ayahs,
          searchQuery: event.query,
          isSearching: false,
        ),
      ),
    );
  }

  void _onClearSearch(_ClearSearch event, Emitter<QuranReaderState> emit) {
    // When clearing search, we don't necessarily know what page to go back to
    // unless we were already on one. The UI usually handles the transition.
    emit(const QuranReaderState.initial());
  }
}
