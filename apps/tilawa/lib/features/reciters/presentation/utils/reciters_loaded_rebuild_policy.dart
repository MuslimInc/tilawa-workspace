import 'package:tilawa_core/entities/reciter_entity.dart';

import '../bloc/reciters_bloc.dart';

/// Returns whether two reciter lists show the same ids in the same order.
bool sameReciterOrder(
  List<ReciterEntity> previous,
  List<ReciterEntity> current,
) {
  if (previous.length != current.length) {
    return false;
  }

  for (int i = 0; i < previous.length; i++) {
    if (previous[i].id != current[i].id) {
      return false;
    }
  }

  return true;
}

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
