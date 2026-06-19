/// Catalog index for rotating Home daily inspiration content.
int homeDailyInspirationCatalogIndex(DateTime date) {
  final int dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
  return dayOfYear % homeDailyInspirationCatalogLength;
}

/// Number of ayah/dua pairs in the rotation catalog.
const int homeDailyInspirationCatalogLength = 3;
