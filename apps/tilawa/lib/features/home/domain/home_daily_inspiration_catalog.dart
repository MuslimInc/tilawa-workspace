/// Catalog index for rotating Home daily inspiration content.
int homeDailyInspirationCatalogIndex(DateTime date) {
  final int dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
  return dayOfYear % homeDailyInspirationCatalogLength;
}

/// Number of ayah/dua pairs in the rotation catalog.
const int homeDailyInspirationCatalogLength = 3;

/// Verse coordinates for each catalog entry (index 0–2).
const List<({int surahNumber, int ayahNumber})> homeDailyAyahCatalogVerses = [
  (surahNumber: 2, ayahNumber: 43),
  (surahNumber: 2, ayahNumber: 152),
  (surahNumber: 29, ayahNumber: 45),
];
