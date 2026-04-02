import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:dartz_plus/dartz_plus.dart';
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
abstract class QuranReaderState with _$QuranReaderState {
  const factory QuranReaderState({
    @Default(QuranReaderStatus.initial) QuranReaderStatus status,
    SurahContentEntity? currentSurah,
    QuranPageEntity? currentPage,
    int? initialPageHint,
    @Default({}) Map<int, QuranPageEntity> pages,
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
    this._saveLastReadPositionUseCase,
    this._getLastReadPositionUseCase,
    this._searchAyahsUseCase,
    this._getStartPageForSurahUseCase,
  ) : super(const QuranReaderState()) {
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
    emit(state.copyWith(status: QuranReaderStatus.loading, errorMessage: ''));

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

        if (event.loadStartPage) {
          final startPage = _getStartPageForSurahUseCase.call(surah.number);
          add(QuranReaderEvent.loadPage(startPage));
        }
      },
    );
  }

  Future<void> _onLoadPage(
    _LoadPage event,
    Emitter<QuranReaderState> emit,
  ) async {
    if (state.pages.containsKey(event.pageNumber)) {
      final cachedPage = state.pages[event.pageNumber]!;

      if (cachedPage.ayahs.isNotEmpty) {
        final firstSurahNum = cachedPage.ayahs.first.surahNumber;
        if (state.currentSurah?.number != firstSurahNum) {
          add(QuranReaderEvent.loadSurah(firstSurahNum, loadStartPage: false));
        }
        add(
          QuranReaderEvent.saveLastRead(
            surahNumber: firstSurahNum,
            page: cachedPage.pageNumber,
          ),
        );
      }

      emit(
        state.copyWith(
          currentPage: cachedPage,
          initialPageHint: cachedPage.pageNumber,
        ),
      );
      return;
    }

    if (state.pages.isEmpty) {
      emit(state.copyWith(status: QuranReaderStatus.loading, errorMessage: ''));
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

        const maxCachedPages = 20;
        if (newPages.length > maxCachedPages) {
          final keysToRemove =
              newPages.keys.where((k) => k != page.pageNumber).toList()..sort(
                (a, b) => (a - page.pageNumber).abs().compareTo(
                  (b - page.pageNumber).abs(),
                ),
              );
          while (newPages.length > maxCachedPages) {
            newPages.remove(keysToRemove.removeLast());
          }
        }

        if (page.ayahs.isNotEmpty) {
          final firstSurahNum = page.ayahs.first.surahNumber;
          if (state.currentSurah?.number != firstSurahNum) {
            add(
              QuranReaderEvent.loadSurah(firstSurahNum, loadStartPage: false),
            );
          }
          add(
            QuranReaderEvent.saveLastRead(
              surahNumber: firstSurahNum,
              page: page.pageNumber,
            ),
          );
        }

        emit(
          state.copyWith(
            status: QuranReaderStatus.loaded,
            currentPage: page,
            initialPageHint: page.pageNumber,
            pages: newPages,
          ),
        );
      },
    );
  }

  void _onScrollToAyah(_ScrollToAyah event, Emitter<QuranReaderState> emit) {
    emit(state.copyWith(scrollToAyah: event.ayahNumber));
    emit(state.copyWith(scrollToAyah: null));
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
    emit(state.copyWith(status: QuranReaderStatus.loading, errorMessage: ''));
    final result = await _getLastReadPositionUseCase.call();

    result.fold(
      (failure) {
        emit(
          state.copyWith(
            status: QuranReaderStatus.error,
            errorMessage: failure.toString(),
          ),
        );
      },
      (position) {
        if (position.page != null) {
          emit(state.copyWith(initialPageHint: position.page));
          add(QuranReaderEvent.loadPage(position.page!));
        } else if (position.surahNumber != null) {
          emit(
            state.copyWith(
              initialPageHint: _getStartPageForSurahUseCase.call(
                position.surahNumber!,
              ),
            ),
          );
          add(QuranReaderEvent.loadSurah(position.surahNumber!));
        } else {
          emit(state.copyWith(initialPageHint: 1));
          add(const QuranReaderEvent.loadSurah(1));
        }
      },
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
