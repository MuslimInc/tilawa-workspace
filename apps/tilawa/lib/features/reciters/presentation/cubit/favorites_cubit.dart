import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/usecases/usecase.dart';
import '../../domain/usecases/get_favorite_reciters_use_case.dart';
import '../../domain/usecases/toggle_favorite_reciter_use_case.dart';
import 'favorites_state.dart';

@injectable
class FavoritesCubit extends Cubit<FavoritesState> {
  FavoritesCubit(this._getFavorites, this._toggleFavorite)
    : super(FavoritesInitial());
  final GetFavoriteRecitersUseCase _getFavorites;
  final ToggleFavoriteReciterUseCase _toggleFavorite;

  Set<int> _currentFavoriteIds = {};
  final Set<int> _pendingReciterIds = {};

  Future<void> loadFavorites() async {
    emit(FavoritesLoading());
    final Either<Failure, List<ReciterEntity>> result = await _getFavorites(
      const NoParams(),
    );

    result.fold(
      (failure) => emit(FavoritesError(failure.message ?? 'Unknown Error')),
      (favorites) {
        _currentFavoriteIds = favorites.map((e) => e.id).toSet();
        emit(
          FavoritesLoaded(
            favorites: favorites,
            favoriteIds: _currentFavoriteIds,
          ),
        );
      },
    );
  }

  Future<void> toggleFavorite(ReciterEntity reciter) async {
    if (_pendingReciterIds.contains(reciter.id)) {
      return;
    }
    _pendingReciterIds.add(reciter.id);

    try {
      // Optimistic update
      final bool isFav = _isFavorite(reciter.id);
      if (isFav) {
        _currentFavoriteIds.remove(reciter.id);
      } else {
        _currentFavoriteIds.add(reciter.id);
      }

      // Emit loaded state immediately with updated IDs to reflect UI change fast
      if (state is FavoritesLoaded) {
        final List<ReciterEntity> currentReciters =
            (state as FavoritesLoaded).favorites;
        List<ReciterEntity> updatedReciters;
        if (isFav) {
          updatedReciters = currentReciters
              .where((r) => r.id != reciter.id)
              .toList();
        } else {
          updatedReciters = [...currentReciters, reciter];
        }
        emit(
          FavoritesLoaded(
            favorites: updatedReciters,
            favoriteIds: Set.from(_currentFavoriteIds),
            removedReciter: isFav ? reciter : null,
          ),
        );
      }

      final Either<Failure, void> result = await _toggleFavorite(reciter.id);

      result.fold(
        (failure) {
          // Revert on failure
          if (isFav) {
            _currentFavoriteIds.add(reciter.id);
          } else {
            _currentFavoriteIds.remove(reciter.id);
          }
          loadFavorites(); // Re-sync with source of truth
          emit(FavoritesError(failure.message ?? 'Unknown Error'));
        },
        (_) {
          // Success - ensure our list is fully synced or just rely on optimistic
          // Depending on UX requirements, better to keep it optimistic.
        },
      );
    } finally {
      _pendingReciterIds.remove(reciter.id);
    }
  }

  bool _isFavorite(int id) {
    if (state is FavoritesLoaded) {
      return (state as FavoritesLoaded).favoriteIds.contains(id);
    }
    return _currentFavoriteIds.contains(id);
  }
}
