part of 'reciters_bloc.dart';

abstract class RecitersEvent extends Equatable {
  const RecitersEvent();

  @override
  List<Object?> get props => [];
}

class LoadReciters extends RecitersEvent {
  const LoadReciters();
}

class FilterByLetter extends RecitersEvent {
  const FilterByLetter(this.letter);
  final String letter;

  @override
  List<Object?> get props => [letter];
}

class ClearLetterFilter extends RecitersEvent {
  const ClearLetterFilter();
}

class ToggleFavoritesFilter extends RecitersEvent {
  const ToggleFavoritesFilter(this.favoriteIds);
  final Set<int> favoriteIds;

  @override
  List<Object?> get props => [favoriteIds];
}

class SyncFavoriteIds extends RecitersEvent {
  const SyncFavoriteIds(this.favoriteIds);
  final Set<int> favoriteIds;

  @override
  List<Object?> get props => [favoriteIds];
}

class ClearFavoritesFilter extends RecitersEvent {
  const ClearFavoritesFilter();
}

class LanguageChanged extends RecitersEvent {
  const LanguageChanged();
}
