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
  const LanguageChanged(this.languageCode);

  final String languageCode;

  @override
  List<Object?> get props => [languageCode];
}

/// Re-sorts the visible catalog so favorited reciters appear first.
///
/// Used after pull-to-refresh, initial catalog load, or returning to the
/// reciters main tab — not during optimistic heart toggles.
class ApplyFavoriteOrdering extends RecitersEvent {
  const ApplyFavoriteOrdering();
}
