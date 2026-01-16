import 'package:equatable/equatable.dart';

import 'package:tilawa_core/entities/reciter_entity.dart';

abstract class FavoritesState extends Equatable {
  const FavoritesState();

  @override
  List<Object?> get props => [];
}

class FavoritesInitial extends FavoritesState {}

class FavoritesLoading extends FavoritesState {}

class FavoritesLoaded extends FavoritesState {
  const FavoritesLoaded({
    required this.favorites,
    required this.favoriteIds,
    this.removedReciter,
  });
  final List<ReciterEntity> favorites;
  final Set<int> favoriteIds;
  final ReciterEntity? removedReciter;

  @override
  List<Object?> get props => [favorites, favoriteIds, removedReciter];
}

class FavoritesError extends FavoritesState {
  const FavoritesError(this.message);
  final String message;

  @override
  List<Object> get props => [message];
}
