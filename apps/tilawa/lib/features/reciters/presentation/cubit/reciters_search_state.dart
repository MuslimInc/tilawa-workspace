part of 'reciters_search_cubit.dart';

sealed class RecitersSearchState extends Equatable {
  const RecitersSearchState();

  @override
  List<Object?> get props => [];
}

final class RecitersSearchInitial extends RecitersSearchState {
  const RecitersSearchInitial();
}

final class RecitersSearchLoading extends RecitersSearchState {
  const RecitersSearchLoading({required this.query});

  final String query;

  @override
  List<Object?> get props => [query];
}

final class RecitersSearchLoaded extends RecitersSearchState {
  const RecitersSearchLoaded({
    required this.query,
    required this.results,
  });

  final String query;
  final List<ReciterEntity> results;

  @override
  List<Object?> get props => [query, results];
}

final class RecitersSearchError extends RecitersSearchState {
  const RecitersSearchError({required this.query, required this.message});

  final String query;
  final String message;

  @override
  List<Object?> get props => [query, message];
}
