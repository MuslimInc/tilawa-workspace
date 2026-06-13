import 'dart:collection';

import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/usecases/usecase.dart';

import '../../domain/usecases/clear_favorite_reciters_use_case.dart';
import '../../domain/usecases/get_favorite_reciters_use_case.dart';
import '../../domain/usecases/toggle_favorite_reciter_use_case.dart';
import '../utils/reciter_list_order.dart';
import 'favorites_state.dart';

@injectable
class FavoritesCubit extends Cubit<FavoritesState> {
  FavoritesCubit(
    this._getFavorites,
    this._toggleFavorite,
    this._clearFavoriteReciters,
  ) : super(_initialState(_getFavorites)) {
    final FavoritesState current = state;
    if (current is FavoritesLoaded) {
      _replaceFavorites(current.favorites);
    }
  }
  final GetFavoriteRecitersUseCase _getFavorites;
  final ToggleFavoriteReciterUseCase _toggleFavorite;
  final ClearFavoriteRecitersUseCase _clearFavoriteReciters;

  /// Insertion-ordered index: O(1) add/remove/lookup by reciter id.
  final LinkedHashMap<int, ReciterEntity> _favoritesById =
      LinkedHashMap<int, ReciterEntity>();
  final Set<int> _pendingReciterIds = <int>{};

  /// Seeds the cubit from the splash-prefetched favorites so the reciters
  /// screen lands on [FavoritesLoaded] without a flash of loading state.
  static FavoritesState _initialState(GetFavoriteRecitersUseCase getFavorites) {
    final List<ReciterEntity>? cached = getFavorites
        .takeCachedSuccessForStartup();
    if (cached == null) {
      return FavoritesInitial();
    }
    return FavoritesLoaded(
      favorites: cached,
      favoriteIds: cached.map((ReciterEntity r) => r.id).toSet(),
    );
  }

  Future<void> loadFavorites() async {
    if (isClosed) return;
    emit(FavoritesLoading());
    final Either<Failure, List<ReciterEntity>> result = await _getFavorites(
      const NoParams(),
    );
    if (isClosed) return;

    result.fold((failure) => emit(FavoritesError(failure)), (
      List<ReciterEntity> favorites,
    ) {
      _replaceFavorites(favorites);
      emit(_loadedState());
    });
  }

  /// Reorders the favorites list to match [catalogReciters] without a fetch.
  ///
  /// Called after [LoadReciters] completes or when returning to the reciters
  /// main tab — not during optimistic heart toggles.
  void applyCatalogOrder(List<ReciterEntity> catalogReciters) {
    if (isClosed) return;
    _syncIndexFromStateIfNeeded();
    if (_favoritesById.isEmpty) {
      return;
    }

    final List<ReciterEntity> ordered = <ReciterEntity>[];
    final Set<int> matchedIds = <int>{};
    for (final ReciterEntity reciter in catalogReciters) {
      final ReciterEntity? favorite = _favoritesById[reciter.id];
      if (favorite != null) {
        ordered.add(favorite);
        matchedIds.add(reciter.id);
      }
    }
    for (final ReciterEntity favorite in _favoritesById.values) {
      if (!matchedIds.contains(favorite.id)) {
        ordered.add(favorite);
      }
    }
    if (sameReciterOrder(_favoritesById.values.toList(), ordered)) {
      return;
    }

    _replaceFavorites(ordered);
    emit(_loadedState());
  }

  Future<void> toggleFavorite(ReciterEntity reciter) async {
    if (isClosed) return;
    _syncIndexFromStateIfNeeded();
    if (_pendingReciterIds.contains(reciter.id)) {
      return;
    }
    _pendingReciterIds.add(reciter.id);

    final LinkedHashMap<int, ReciterEntity> snapshot = _snapshotMap();
    final bool wasFavorite = _favoritesById.containsKey(reciter.id);

    try {
      if (wasFavorite) {
        _favoritesById.remove(reciter.id);
      } else {
        _favoritesById[reciter.id] = reciter;
      }

      emit(
        _loadedState(
          removedReciter: wasFavorite ? reciter : null,
        ),
      );

      final Either<Failure, void> result = await _toggleFavorite(reciter.id);
      if (isClosed) return;

      result.fold(
        (_) {
          _restoreMap(snapshot);
          if (!isClosed) {
            emit(_loadedState());
          }
        },
        (_) {},
      );
    } finally {
      _pendingReciterIds.remove(reciter.id);
    }
  }

  Future<void> clearAllFavorites() async {
    if (isClosed) return;
    _syncIndexFromStateIfNeeded();
    if (_pendingReciterIds.isNotEmpty) {
      return;
    }
    if (_favoritesById.isEmpty) {
      return;
    }

    final LinkedHashMap<int, ReciterEntity> snapshot = _snapshotMap();

    _favoritesById.clear();
    emit(
      const FavoritesLoaded(favorites: <ReciterEntity>[], favoriteIds: <int>{}),
    );

    final Either<Failure, void> result = await _clearFavoriteReciters();
    if (isClosed) return;

    result.fold(
      (_) {
        _restoreMap(snapshot);
        emit(_loadedState());
      },
      (_) {},
    );
  }

  void _replaceFavorites(Iterable<ReciterEntity> favorites) {
    _favoritesById
      ..clear()
      ..addEntries(
        favorites.map((ReciterEntity reciter) => MapEntry(reciter.id, reciter)),
      );
  }

  /// Keeps the id index aligned when [blocTest] seeds [FavoritesLoaded] after
  /// construction.
  void _syncIndexFromStateIfNeeded() {
    if (_favoritesById.isNotEmpty || state is! FavoritesLoaded) {
      return;
    }

    final FavoritesLoaded loaded = state as FavoritesLoaded;
    if (loaded.favorites.isEmpty) {
      return;
    }

    _replaceFavorites(loaded.favorites);
  }

  LinkedHashMap<int, ReciterEntity> _snapshotMap() {
    return LinkedHashMap<int, ReciterEntity>.from(_favoritesById);
  }

  void _restoreMap(LinkedHashMap<int, ReciterEntity> snapshot) {
    _favoritesById
      ..clear()
      ..addAll(snapshot);
  }

  FavoritesLoaded _loadedState({ReciterEntity? removedReciter}) {
    return FavoritesLoaded(
      favorites: _favoritesById.values.toList(growable: false),
      favoriteIds: _favoritesById.keys.toSet(),
      removedReciter: removedReciter,
    );
  }
}
