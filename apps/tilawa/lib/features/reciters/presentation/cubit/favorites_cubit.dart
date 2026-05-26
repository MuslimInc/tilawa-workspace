import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/usecases/usecase.dart';

import '../../domain/usecases/clear_favorite_reciters_use_case.dart';
import '../../domain/usecases/get_favorite_reciters_use_case.dart';
import '../../domain/usecases/toggle_favorite_reciter_use_case.dart';
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
      _currentFavoriteIds = Set<int>.from(current.favoriteIds);
    }
  }
  final GetFavoriteRecitersUseCase _getFavorites;
  final ToggleFavoriteReciterUseCase _toggleFavorite;
  final ClearFavoriteRecitersUseCase _clearFavoriteReciters;

  Set<int> _currentFavoriteIds = {};
  final Set<int> _pendingReciterIds = {};

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
      favoriteIds: cached.map((r) => r.id).toSet(),
    );
  }

  Future<void> loadFavorites() async {
    if (isClosed) return;
    emit(FavoritesLoading());
    final Either<Failure, List<ReciterEntity>> result = await _getFavorites(
      const NoParams(),
    );
    if (isClosed) return;

    result.fold((failure) => emit(FavoritesError(failure)), (favorites) {
      _currentFavoriteIds = favorites.map((e) => e.id).toSet();
      emit(
        FavoritesLoaded(favorites: favorites, favoriteIds: _currentFavoriteIds),
      );
    });
  }

  Future<void> toggleFavorite(ReciterEntity reciter) async {
    if (isClosed) return;
    if (_pendingReciterIds.contains(reciter.id)) {
      return;
    }
    _pendingReciterIds.add(reciter.id);

    final FavoritesLoaded snapshot = _snapshotLoadedState();
    _currentFavoriteIds = Set<int>.from(snapshot.favoriteIds);
    final bool wasFavorite = snapshot.favoriteIds.contains(reciter.id);

    try {
      if (wasFavorite) {
        _currentFavoriteIds.remove(reciter.id);
      } else {
        _currentFavoriteIds.add(reciter.id);
      }

      _emitLoadedAfterToggle(
        reciter: reciter,
        wasFavorite: wasFavorite,
        previousFavorites: snapshot.favorites,
      );

      final Either<Failure, void> result = await _toggleFavorite(reciter.id);
      if (isClosed) return;

      result.fold(
        (_) {
          _currentFavoriteIds = Set<int>.from(snapshot.favoriteIds);
          if (!isClosed) {
            emit(snapshot);
          }
        },
        (_) {},
      );
    } finally {
      _pendingReciterIds.remove(reciter.id);
    }
  }

  FavoritesLoaded _snapshotLoadedState() {
    if (state is FavoritesLoaded) {
      final FavoritesLoaded loaded = state as FavoritesLoaded;
      return FavoritesLoaded(
        favorites: List<ReciterEntity>.from(loaded.favorites),
        favoriteIds: Set<int>.from(loaded.favoriteIds),
      );
    }
    return FavoritesLoaded(
      favorites: const <ReciterEntity>[],
      favoriteIds: Set<int>.from(_currentFavoriteIds),
    );
  }

  void _emitLoadedAfterToggle({
    required ReciterEntity reciter,
    required bool wasFavorite,
    required List<ReciterEntity> previousFavorites,
  }) {
    if (isClosed) return;

    final List<ReciterEntity> updatedFavorites = wasFavorite
        ? previousFavorites.where((r) => r.id != reciter.id).toList()
        : [...previousFavorites, reciter];

    emit(
      FavoritesLoaded(
        favorites: updatedFavorites,
        favoriteIds: Set<int>.from(_currentFavoriteIds),
        removedReciter: wasFavorite ? reciter : null,
      ),
    );
  }

  Future<void> clearAllFavorites() async {
    if (isClosed) return;
    if (_pendingReciterIds.isNotEmpty) {
      return;
    }

    final FavoritesLoaded? currentState = state is FavoritesLoaded
        ? state as FavoritesLoaded
        : null;
    if (currentState == null || currentState.favoriteIds.isEmpty) {
      return;
    }

    final List<ReciterEntity> previousFavorites = List<ReciterEntity>.from(
      currentState.favorites,
    );
    final Set<int> previousFavoriteIds = Set<int>.from(
      currentState.favoriteIds,
    );

    _currentFavoriteIds = {};
    emit(
      const FavoritesLoaded(favorites: <ReciterEntity>[], favoriteIds: <int>{}),
    );

    final Either<Failure, void> result = await _clearFavoriteReciters();
    if (isClosed) return;

    result.fold(
      (_) {
        _currentFavoriteIds = previousFavoriteIds;
        emit(
          FavoritesLoaded(
            favorites: previousFavorites,
            favoriteIds: previousFavoriteIds,
          ),
        );
      },
      (_) {},
    );
  }

}
