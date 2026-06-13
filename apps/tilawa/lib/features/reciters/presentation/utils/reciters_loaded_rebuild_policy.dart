import '../bloc/reciters_bloc.dart';
import 'reciter_list_order.dart';

export 'reciter_list_order.dart';

/// Decides whether [RecitersScreen] should rebuild for two loaded states.
///
/// Skips rebuild when only favorite ids changed but the visible list order is
/// unchanged (heart icons update via [FavoritesCubit]). Rebuilds when favorites
/// filtering changes the visible list, e.g. favorites tab sync.
bool shouldRebuildRecitersLoaded(
  RecitersLoaded previous,
  RecitersLoaded current,
) {
  final bool onlyFavoritesChanged =
      previous.favoriteIds != current.favoriteIds &&
      previous.selectedLetter == current.selectedLetter &&
      previous.showFavoritesOnly == current.showFavoritesOnly &&
      sameReciterOrder(previous.filteredReciters, current.filteredReciters);

  if (onlyFavoritesChanged) {
    return false;
  }

  return !sameReciterOrder(
        previous.filteredReciters,
        current.filteredReciters,
      ) ||
      previous.selectedLetter != current.selectedLetter ||
      previous.showFavoritesOnly != current.showFavoritesOnly;
}
