import 'package:dartz_plus/dartz_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/entities/reciter_entity.dart' as entity;
import 'package:tilawa_core/errors/failures.dart';

import '../../domain/usecases/get_reciters_use_case.dart';

part 'reciters_event.dart';
part 'reciters_state.dart';

@injectable
class RecitersBloc extends HydratedBloc<RecitersEvent, RecitersState> {
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
      final List<entity.ReciterEntity>? recitersData = result
          .fold<List<entity.ReciterEntity>?>(
            (_) => null,
            (entities) => entities,
          );

      if (recitersData != null) {
        final List<entity.ReciterEntity> filteredReciters = _filterReciters(
          recitersData,
          searchQuery,
          selectedLetter,
          showFavoritesOnly,
          favoriteIds,
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
      } else {
        emit(const RecitersError('Failed to load reciters'));
      }
    } catch (e) {
      emit(RecitersError('Error loading reciters: $e'));
    }
  }

  void _onSearchReciters(
    SearchRecitersEvent event,
    Emitter<RecitersState> emit,
  ) {
    if (state is! RecitersLoaded) {
      return;
    }

    final currentState = state as RecitersLoaded;
    final List<entity.ReciterEntity> filteredReciters = _filterReciters(
      currentState.reciters,
      event.query,
      null, // Clear letter filter when searching
      currentState.showFavoritesOnly,
      currentState.favoriteIds,
    );

    emit(
      currentState.copyWith(
        searchQuery: event.query,
        clearSelectedLetter: true,
        filteredReciters: filteredReciters,
      ),
    );
  }

  void _onFilterByLetter(FilterByLetter event, Emitter<RecitersState> emit) {
    if (state is! RecitersLoaded) {
      return;
    }

    final currentState = state as RecitersLoaded;
    final List<entity.ReciterEntity> filteredReciters = _filterReciters(
      currentState.reciters,
      '', // Clear search when filtering by letter
      event.letter,
      currentState.showFavoritesOnly,
      currentState.favoriteIds,
    );

    emit(
      currentState.copyWith(
        searchQuery: '',
        selectedLetter: event.letter,
        filteredReciters: filteredReciters,
      ),
    );
  }

  void _onClearLetterFilter(
    ClearLetterFilter event,
    Emitter<RecitersState> emit,
  ) {
    if (state is! RecitersLoaded) {
      return;
    }

    final currentState = state as RecitersLoaded;
    final List<entity.ReciterEntity> filteredReciters = _filterReciters(
      currentState.reciters,
      currentState.searchQuery,
      null,
      currentState.showFavoritesOnly,
      currentState.favoriteIds,
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

  void _onSyncFavoriteIds(SyncFavoriteIds event, Emitter<RecitersState> emit) {
    if (state is! RecitersLoaded) {
      return;
    }

    final currentState = state as RecitersLoaded;
    final List<entity.ReciterEntity> filteredReciters = _filterReciters(
      currentState.reciters,
      currentState.searchQuery,
      currentState.selectedLetter,
      currentState.showFavoritesOnly,
      event.favoriteIds,
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
      const [],
    );

    emit(
      currentState.copyWith(
        showFavoritesOnly: false,
        favoriteIds: const [],
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
    // If we have loaded reciters, refetch them with the new language
    if (state is RecitersLoaded) {
      await _onLoadReciters(const LoadReciters(), emit);
    }
  }

  @override
  RecitersState? fromJson(Map<String, dynamic> json) {
    // Reciters should be loaded from repository, so we always start with initial state
    return const RecitersInitial();
  }

  @override
  Map<String, dynamic>? toJson(RecitersState state) {
    // Don't persist complex reciters data - will reload from repository
    return null;
  }
}
