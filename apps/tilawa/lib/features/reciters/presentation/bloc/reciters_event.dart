part of 'reciters_bloc.dart';

abstract class RecitersEvent extends Equatable {
  const RecitersEvent();

  @override
  List<Object?> get props => [];
}

class LoadReciters extends RecitersEvent {
  const LoadReciters();
}

class SearchRecitersEvent extends RecitersEvent {
  const SearchRecitersEvent(this.query);
  final String query;

  @override
  List<Object?> get props => [query];
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

class ClearSearch extends RecitersEvent {
  const ClearSearch();
}

class ToggleFavoritesFilter extends RecitersEvent {
  const ToggleFavoritesFilter(this.favoriteIds);
  final List<int> favoriteIds;

  @override
  List<Object?> get props => [favoriteIds];
}

class ClearFavoritesFilter extends RecitersEvent {
  const ClearFavoritesFilter();
}

class LanguageChanged extends RecitersEvent {
  const LanguageChanged();
}
