import 'package:tilawa_core/entities/reciter_entity.dart';

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

/// O(1) identity/length checks, then O(k) membership where k is favorite count.
bool sameFavoriteIdSet(Set<int> previous, Set<int> current) {
  if (identical(previous, current)) {
    return true;
  }
  if (previous.length != current.length) {
    return false;
  }
  for (final int id in previous) {
    if (!current.contains(id)) {
      return false;
    }
  }
  return true;
}

/// Whether [reciters] already has every favorite id before any non-favorite.
bool recitersAlreadyFavoritesFirst(
  List<ReciterEntity> reciters,
  Set<int> favoriteIds,
) {
  if (favoriteIds.isEmpty) {
    return true;
  }

  var seenNonFavorite = false;
  for (final ReciterEntity reciter in reciters) {
    final bool isFavorite = favoriteIds.contains(reciter.id);
    if (isFavorite && seenNonFavorite) {
      return false;
    }
    if (!isFavorite) {
      seenNonFavorite = true;
    }
  }
  return true;
}

/// Single O(n) catalog pass with O(1) [favoriteIds] membership per reciter.
List<ReciterEntity> favoritesInCatalogOrder(
  Set<int> favoriteIds,
  List<ReciterEntity> catalogReciters,
) {
  if (favoriteIds.isEmpty) {
    return const <ReciterEntity>[];
  }

  final List<ReciterEntity> ordered = <ReciterEntity>[];
  for (final ReciterEntity reciter in catalogReciters) {
    if (favoriteIds.contains(reciter.id)) {
      ordered.add(reciter);
    }
  }
  return ordered;
}

/// Partitions [reciters] into favorites then others preserving each group's
/// relative order. O(n) with O(1) [favoriteIds] lookups.
List<ReciterEntity> bubbleFavoritesToTop(
  List<ReciterEntity> reciters,
  Set<int> favoriteIds,
) {
  if (favoriteIds.isEmpty ||
      recitersAlreadyFavoritesFirst(reciters, favoriteIds)) {
    return reciters;
  }

  final List<ReciterEntity> favorites = <ReciterEntity>[];
  final List<ReciterEntity> others = <ReciterEntity>[];

  for (final ReciterEntity reciter in reciters) {
    if (favoriteIds.contains(reciter.id)) {
      favorites.add(reciter);
    } else {
      others.add(reciter);
    }
  }

  return <ReciterEntity>[...favorites, ...others];
}
