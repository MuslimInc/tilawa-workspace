import 'package:equatable/equatable.dart';

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

class ClearSearch extends RecitersEvent {
  const ClearSearch();
}

class ClearLetterFilter extends RecitersEvent {
  const ClearLetterFilter();
}
