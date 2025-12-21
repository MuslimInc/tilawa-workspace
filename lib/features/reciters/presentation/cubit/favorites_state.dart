import 'package:equatable/equatable.dart';

import '../../../../core/entities/reciter_entity.dart';

abstract class FavoritesState extends Equatable {
  const FavoritesState();

  @override
  List<Object> get props => [];
}

class FavoritesInitial extends FavoritesState {}

class FavoritesLoading extends FavoritesState {}

class FavoritesLoaded extends FavoritesState {
  const FavoritesLoaded({required this.favorites, required this.favoriteIds});
  final List<ReciterEntity> favorites;
  final Set<int> favoriteIds;

  @override
  List<Object> get props => [favorites, favoriteIds];
}

class FavoritesError extends FavoritesState {
  const FavoritesError(this.message);
  final String message;

  @override
  List<Object> get props => [message];
}
