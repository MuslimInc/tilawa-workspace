import 'package:dartz_plus/dartz_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/entities/reciter_entity.dart' as entity;
import 'package:tilawa_core/errors/failures.dart';

import '../../domain/services/reciter_catalog_index.dart';
import '../../domain/usecases/get_reciters_use_case.dart';

part 'reciters_event.dart';
part 'reciters_state.dart';

@lazySingleton
class RecitersBloc extends Bloc<RecitersEvent, RecitersState> {
  RecitersBloc(
    this._getRecitersUseCase, {
    List<entity.ReciterEntity>? initialReciters,
  }) : super(_initialState(initialReciters)) {
    on<LoadReciters>(_onLoadReciters);
    on<FilterByLetter>(_onFilterByLetter);
    on<ClearLetterFilter>(_onClearLetterFilter);
    on<SyncFavoriteIds>(_onSyncFavoriteIds);
    on<ClearFavoritesFilter>(_onClearFavoritesFilter);
    on<LanguageChanged>(_onLanguageChanged);
  }
  final GetRecitersUseCase _getRecitersUseCase;
  ReciterCatalogIndex? _catalogIndex;

  static RecitersState _initialState(
    List<entity.ReciterEntity>? initialReciters,
  ) {
    if (initialReciters == null) {
      return const RecitersInitial();
    }
    return RecitersLoaded(
      reciters: initialReciters,
      filteredReciters: initialReciters,
    );
  }

  ReciterCatalogIndex _indexFor(List<entity.ReciterEntity> reciters) {
    if (_catalogIndex == null ||
        _catalogIndex!.reciters.length != reciters.length) {
      _catalogIndex = ReciterCatalogIndex.from(reciters);
    }
    return _catalogIndex!;
  }

  Future<void> _onLoadReciters(
    LoadReciters event,
    Emitter<RecitersState> emit,
  ) async {
    final String? selectedLetter = state is RecitersLoaded
        ? (state as RecitersLoaded).selectedLetter
        : null;
    final bool showFavoritesOnly = state is RecitersLoaded
        ? (state as RecitersLoaded).showFavoritesOnly
        : false;
    final Set<int> favoriteIds = state is RecitersLoaded
        ? (state as RecitersLoaded).favoriteIds
        : const <int>{};

    emit(const RecitersLoading());

    try {
      final Either<Failure, List<entity.ReciterEntity>> result =
          await _getRecitersUseCase();

      await result.fold((failure) async => emit(RecitersError(failure)), (
        recitersData,
      ) async {
        _catalogIndex = ReciterCatalogIndex.from(recitersData);
        final List<entity.ReciterEntity> filteredReciters = await Future(
          () => _filterReciters(
            recitersData,
            selectedLetter,
            showFavoritesOnly,
            favoriteIds,
          ),
        );

        emit(
          RecitersLoaded(
            reciters: recitersData,
            filteredReciters: filteredReciters,
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

  Future<void> _onFilterByLetter(
    FilterByLetter event,
    Emitter<RecitersState> emit,
  ) async {
    if (state is! RecitersLoaded) {
      return;
    }

    final currentState = state as RecitersLoaded;

    final List<entity.ReciterEntity> filteredReciters = await Future(
      () => _filterReciters(
        currentState.reciters,
        event.letter,
        currentState.showFavoritesOnly,
        currentState.favoriteIds,
      ),
    );

    emit(
      currentState.copyWith(
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

    final List<entity.ReciterEntity> filteredReciters = await Future(
      () => _filterReciters(
        currentState.reciters,
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
    String? selectedLetter,
    bool showFavoritesOnly,
    Set<int> favoriteIds,
  ) {
    final ReciterCatalogIndex index = _indexFor(reciters);
    final Set<int> favoriteIdsLookup = favoriteIds;
    List<entity.ReciterEntity> filtered = selectedLetter == null
        ? reciters
        : index.recitersForLetter(selectedLetter);

    if (showFavoritesOnly) {
      filtered = filtered.where((entity.ReciterEntity reciter) {
        return favoriteIdsLookup.contains(reciter.id);
      }).toList();
    }

    if (favoriteIdsLookup.isEmpty) {
      return filtered;
    }

    final List<entity.ReciterEntity> favorites = <entity.ReciterEntity>[];
    final List<entity.ReciterEntity> others = <entity.ReciterEntity>[];

    for (final entity.ReciterEntity reciter in filtered) {
      if (favoriteIdsLookup.contains(reciter.id)) {
        favorites.add(reciter);
      } else {
        others.add(reciter);
      }
    }

    return <entity.ReciterEntity>[...favorites, ...others];
  }

  Future<void> _onLanguageChanged(
    LanguageChanged event,
    Emitter<RecitersState> emit,
  ) async {
    if (state is RecitersLoaded) {
      _catalogIndex = null;
      final currentState = state as RecitersLoaded;
      emit(currentState.copyWith(clearSelectedLetter: true));
      await _onLoadReciters(const LoadReciters(), emit);
    }
  }
}
