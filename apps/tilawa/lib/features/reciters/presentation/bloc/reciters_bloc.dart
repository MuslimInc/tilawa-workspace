import 'package:dartz_plus/dartz_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/entities/reciter_entity.dart' as entity;
import 'package:tilawa_core/errors/failures.dart';

import '../../domain/usecases/get_reciters_use_case.dart';

part 'reciters_event.dart';
part 'reciters_state.dart';

@lazySingleton
class RecitersBloc extends Bloc<RecitersEvent, RecitersState> {
  RecitersBloc(this._getRecitersUseCase) : super(const RecitersInitial()) {
    on<LoadReciters>(_onLoadReciters);
    on<SearchRecitersEvent>(_onSearchReciters);
    on<FilterByLetter>(_onFilterByLetter);
    on<ClearLetterFilter>(_onClearLetterFilter);
    on<ClearSearch>(_onClearSearch);
    on<ToggleFavoritesFilter>(_onToggleFavoritesFilter);
    on<SyncFavoriteIds>(_onSyncFavoriteIds);
    on<ClearFavoritesFilter>(_onClearFavoritesFilter);
    on<LanguageChanged>(_onLanguageChanged);
  }
  final GetRecitersUseCase _getRecitersUseCase;

  Future<void> _onLoadReciters(
    LoadReciters event,
    Emitter<RecitersState> emit,
  ) async {
    final String searchQuery = state is RecitersLoaded
        ? (state as RecitersLoaded).searchQuery
        : '';
    final String? selectedLetter = state is RecitersLoaded
        ? (state as RecitersLoaded).selectedLetter
        : null;
    final bool showFavoritesOnly = state is RecitersLoaded
        ? (state as RecitersLoaded).showFavoritesOnly
        : false;
    final List<int> favoriteIds = state is RecitersLoaded
        ? (state as RecitersLoaded).favoriteIds
        : const [];

    emit(const RecitersLoading());

    try {
      // Prefer domain use case to fetch once and share data
      final Either<Failure, List<entity.ReciterEntity>> result =
          await _getRecitersUseCase();

      await result.fold((failure) async => emit(RecitersError(failure)), (
        recitersData,
      ) async {
        final List<entity.ReciterEntity> filteredReciters = await Future(
          () => _filterReciters(
            recitersData,
            searchQuery,
            selectedLetter,
            showFavoritesOnly,
            favoriteIds,
          ),
        );

        emit(
          RecitersLoaded(
            reciters: recitersData,
            filteredReciters: filteredReciters,
            searchQuery: searchQuery,
            selectedLetter: selectedLetter,
            showFavoritesOnly: showFavoritesOnly,
            favoriteIds: favoriteIds,
          ),
        );
      });
    } catch (e) {
      emit(RecitersError(UnexpectedFailure(e.toString())));
    }
  }

  Future<void> _onSearchReciters(
    SearchRecitersEvent event,
    Emitter<RecitersState> emit,
  ) async {
    if (state is! RecitersLoaded) {
      return;
    }

    final currentState = state as RecitersLoaded;

    // Offload filtering to prevent UI jank
    final List<entity.ReciterEntity> filteredReciters = await Future(
      () => _filterReciters(
        currentState.reciters,
        event.query,
        null, // Clear letter filter when searching
        currentState.showFavoritesOnly,
        currentState.favoriteIds,
      ),
    );

    emit(
      currentState.copyWith(
        searchQuery: event.query,
        clearSelectedLetter: true,
        filteredReciters: filteredReciters,
      ),
    );
  }

  Future<void> _onFilterByLetter(
    FilterByLetter event,
    Emitter<RecitersState> emit,
  ) async {
    if (state is! RecitersLoaded) {
      return;
    }

    final currentState = state as RecitersLoaded;

    // Offload filtering to next event loop to prevent UI jank
    final List<entity.ReciterEntity> filteredReciters = await Future(
      () => _filterReciters(
        currentState.reciters,
        '', // Clear search when filtering by letter
        event.letter,
        currentState.showFavoritesOnly,
        currentState.favoriteIds,
      ),
    );

    emit(
      currentState.copyWith(
        searchQuery: '',
        selectedLetter: event.letter,
        filteredReciters: filteredReciters,
      ),
    );
  }

  Future<void> _onClearLetterFilter(
    ClearLetterFilter event,
    Emitter<RecitersState> emit,
  ) async {
    if (state is! RecitersLoaded) {
      return;
    }

    final currentState = state as RecitersLoaded;

    // Offload filtering to prevent UI jank
    final List<entity.ReciterEntity> filteredReciters = await Future(
      () => _filterReciters(
        currentState.reciters,
        currentState.searchQuery,
        null,
        currentState.showFavoritesOnly,
        currentState.favoriteIds,
      ),
    );

    emit(
      currentState.copyWith(
        clearSelectedLetter: true,
        filteredReciters: filteredReciters,
      ),
    );
  }

  void _onClearSearch(ClearSearch event, Emitter<RecitersState> emit) {
    if (state is! RecitersLoaded) {
      return;
    }

    final currentState = state as RecitersLoaded;
    final List<entity.ReciterEntity> filteredReciters = _filterReciters(
      currentState.reciters,
      '',
      currentState.selectedLetter,
      currentState.showFavoritesOnly,
      currentState.favoriteIds,
    );

    emit(
      currentState.copyWith(
        searchQuery: '',
        filteredReciters: filteredReciters,
      ),
    );
  }

  void _onToggleFavoritesFilter(
    ToggleFavoritesFilter event,
    Emitter<RecitersState> emit,
  ) {
    if (state is! RecitersLoaded) {
      return;
    }

    final currentState = state as RecitersLoaded;
    final bool newShowFavoritesOnly = !currentState.showFavoritesOnly;

    final List<entity.ReciterEntity> filteredReciters = _filterReciters(
      currentState.reciters,
      currentState.searchQuery,
      currentState.selectedLetter,
      newShowFavoritesOnly,
      event.favoriteIds,
    );

    emit(
      currentState.copyWith(
        showFavoritesOnly: newShowFavoritesOnly,
        favoriteIds: event.favoriteIds,
        filteredReciters: filteredReciters,
      ),
    );
  }

  Future<void> _onSyncFavoriteIds(
    SyncFavoriteIds event,
    Emitter<RecitersState> emit,
  ) async {
    if (state is! RecitersLoaded) {
      return;
    }

    final currentState = state as RecitersLoaded;
    final List<entity.ReciterEntity> filteredReciters = await Future(
      () => _filterReciters(
        currentState.reciters,
        currentState.searchQuery,
        currentState.selectedLetter,
        currentState.showFavoritesOnly,
        event.favoriteIds,
      ),
    );

    emit(
      currentState.copyWith(
        favoriteIds: event.favoriteIds,
        filteredReciters: filteredReciters,
      ),
    );
  }

  void _onClearFavoritesFilter(
    ClearFavoritesFilter event,
    Emitter<RecitersState> emit,
  ) {
    if (state is! RecitersLoaded) {
      return;
    }

    final currentState = state as RecitersLoaded;
    final List<entity.ReciterEntity> filteredReciters = _filterReciters(
      currentState.reciters,
      currentState.searchQuery,
      currentState.selectedLetter,
      false,
      currentState.favoriteIds,
    );

    emit(
      currentState.copyWith(
        showFavoritesOnly: false,
        filteredReciters: filteredReciters,
      ),
    );
  }

  List<entity.ReciterEntity> _filterReciters(
    List<entity.ReciterEntity> reciters,
    String searchQuery,
    String? selectedLetter,
    bool showFavoritesOnly,
    List<int> favoriteIds,
  ) {
    final String normalizedQuery = searchQuery.trim().toLowerCase();
    final Set<int> favoriteIdsLookup = favoriteIds.toSet();
    var filtered = reciters;

    // Filter by search query
    if (normalizedQuery.isNotEmpty) {
      filtered = filtered.where((reciter) {
        final String reciterName = reciter.name.toLowerCase();
        final String reciterLetter = reciter.letter.toLowerCase();
        return reciterName.contains(normalizedQuery) ||
            reciterLetter.contains(normalizedQuery);
      }).toList();
    }

    // Filter by selected letter
    if (selectedLetter != null) {
      filtered = filtered.where((reciter) {
        return reciter.letter == selectedLetter;
      }).toList();
    }

    // Filter by favorites
    if (showFavoritesOnly) {
      filtered = filtered.where((reciter) {
        return favoriteIdsLookup.contains(reciter.id);
      }).toList();
    }

    if (favoriteIdsLookup.isEmpty) {
      return filtered;
    }

    final List<entity.ReciterEntity> favorites = [];
    final List<entity.ReciterEntity> others = [];

    for (final entity.ReciterEntity reciter in filtered) {
      if (favoriteIdsLookup.contains(reciter.id)) {
        favorites.add(reciter);
      } else {
        others.add(reciter);
      }
    }

    return [...favorites, ...others];
  }

  Future<void> _onLanguageChanged(
    LanguageChanged event,
    Emitter<RecitersState> emit,
  ) async {
    if (state is RecitersLoaded) {
      final currentState = state as RecitersLoaded;
      emit(currentState.copyWith(searchQuery: '', clearSelectedLetter: true));
      await _onLoadReciters(const LoadReciters(), emit);
    }
  }
}
