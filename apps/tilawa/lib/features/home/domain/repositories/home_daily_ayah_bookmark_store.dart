/// Persists Home daily-ayah sheet bookmarks.
abstract class HomeDailyAyahBookmarkStore {
  Future<bool> isBookmarked(String bookmarkKey);

  Future<bool> toggleBookmark(String bookmarkKey);
}
