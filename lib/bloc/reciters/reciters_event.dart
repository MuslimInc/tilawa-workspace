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
  final String query;

  const SearchRecitersEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class FilterByLetter extends RecitersEvent {
  final String letter;

  const FilterByLetter(this.letter);

  @override
  List<Object?> get props => [letter];
}

class ClearLetterFilter extends RecitersEvent {
  const ClearLetterFilter();
}

class ClearSearch extends RecitersEvent {
  const ClearSearch();
}
