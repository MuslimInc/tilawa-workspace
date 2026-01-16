import '../entities/bookmark_entity.dart';

/// Repository interface for bookmark operations
abstract class BookmarksRepository {
  /// Get all bookmarks sorted by creation date (newest first)
  Future<List<BookmarkEntity>> getAllBookmarks();

  /// Get bookmarks for a specific surah
  Future<List<BookmarkEntity>> getBookmarksBySurah(int surahId);

  /// Get bookmarks for a specific reciter
  Future<List<BookmarkEntity>> getBookmarksByReciter(String reciterId);

  /// Get a specific bookmark by ID
  Future<BookmarkEntity?> getBookmarkById(String id);

  /// Create a new bookmark
  Future<BookmarkEntity> createBookmark({
    required int surahId,
    required String surahName,
    required String surahNameEn,
    required String reciterId,
    required String reciterName,
    required int moshafId,
    required String moshafName,
    required int positionMs,
    required int durationMs,
    required String audioUrl,
    String? label,
    String? artworkUrl,
  });

  /// Update an existing bookmark
  Future<BookmarkEntity> updateBookmark(BookmarkEntity bookmark);

  /// Update bookmark label
  Future<BookmarkEntity> updateBookmarkLabel(String id, String? label);

  /// Delete a bookmark
  Future<void> deleteBookmark(String id);

  /// Delete all bookmarks for a surah
  Future<void> deleteBookmarksBySurah(int surahId);

  /// Delete all bookmarks
  Future<void> deleteAllBookmarks();

  /// Search bookmarks by label
  Future<List<BookmarkEntity>> searchBookmarks(String query);

  /// Check if a bookmark exists for a specific position
  /// (within 5 seconds tolerance)
  Future<bool> hasBookmarkAtPosition({
    required int surahId,
    required String reciterId,
    required int positionMs,
  });

  /// Get bookmark count
  Future<int> getBookmarkCount();
}
