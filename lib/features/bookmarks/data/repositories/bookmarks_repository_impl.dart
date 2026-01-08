import 'package:injectable/injectable.dart';

import '../../domain/entities/bookmark_entity.dart';
import '../../domain/repositories/bookmarks_repository.dart';
import '../datasources/bookmarks_local_datasource.dart';

@LazySingleton(as: BookmarksRepository)
class BookmarksRepositoryImpl implements BookmarksRepository {
  BookmarksRepositoryImpl(this._localDataSource);

  final BookmarksLocalDataSource _localDataSource;

  @override
  Future<List<BookmarkEntity>> getAllBookmarks() async {
    return _localDataSource.getAllBookmarks();
  }

  @override
  Future<List<BookmarkEntity>> getBookmarksBySurah(int surahId) async {
    final List<BookmarkEntity> bookmarks = await _localDataSource
        .getAllBookmarks();
    return bookmarks.where((b) => b.surahId == surahId).toList();
  }

  @override
  Future<List<BookmarkEntity>> getBookmarksByReciter(String reciterId) async {
    final List<BookmarkEntity> bookmarks = await _localDataSource
        .getAllBookmarks();
    return bookmarks.where((b) => b.reciterId == reciterId).toList();
  }

  @override
  Future<BookmarkEntity?> getBookmarkById(String id) async {
    return _localDataSource.getBookmarkById(id);
  }

  @override
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
  }) async {
    final String id = await _localDataSource.generateBookmarkId();
    final now = DateTime.now();

    final bookmark = BookmarkEntity(
      id: id,
      surahId: surahId,
      surahName: surahName,
      surahNameEn: surahNameEn,
      reciterId: reciterId,
      reciterName: reciterName,
      moshafId: moshafId,
      moshafName: moshafName,
      positionMs: positionMs,
      durationMs: durationMs,
      audioUrl: audioUrl,
      label: label,
      artworkUrl: artworkUrl,
      createdAt: now,
      updatedAt: now,
    );

    await _localDataSource.saveBookmark(bookmark);
    return bookmark;
  }

  @override
  Future<BookmarkEntity> updateBookmark(BookmarkEntity bookmark) async {
    final BookmarkEntity? existing = await _localDataSource.getBookmarkById(
      bookmark.id,
    );
    if (existing == null) {
      throw Exception('Bookmark not found');
    }

    final BookmarkEntity updatedBookmark = bookmark.copyWith(
      updatedAt: DateTime.now(),
    );
    await _localDataSource.saveBookmark(updatedBookmark);
    return updatedBookmark;
  }

  @override
  Future<BookmarkEntity> updateBookmarkLabel(String id, String? label) async {
    final BookmarkEntity? existing = await _localDataSource.getBookmarkById(id);
    if (existing == null) {
      throw Exception('Bookmark not found');
    }

    final BookmarkEntity updatedBookmark = existing.copyWith(
      label: label,
      updatedAt: DateTime.now(),
    );
    await _localDataSource.saveBookmark(updatedBookmark);
    return updatedBookmark;
  }

  @override
  Future<void> deleteBookmark(String id) async {
    await _localDataSource.deleteBookmark(id);
  }

  @override
  Future<void> deleteBookmarksBySurah(int surahId) async {
    final List<BookmarkEntity> bookmarks = await _localDataSource
        .getAllBookmarks();
    final List<BookmarkEntity> filtered = bookmarks
        .where((b) => b.surahId != surahId)
        .toList();
    await _localDataSource.saveAllBookmarks(filtered);
  }

  @override
  Future<void> deleteAllBookmarks() async {
    await _localDataSource.clearAllBookmarks();
  }

  @override
  Future<List<BookmarkEntity>> searchBookmarks(String query) async {
    final List<BookmarkEntity> bookmarks = await _localDataSource
        .getAllBookmarks();
    final String lowerQuery = query.toLowerCase();

    return bookmarks.where((bookmark) {
      return bookmark.surahName.toLowerCase().contains(lowerQuery) ||
          bookmark.surahNameEn.toLowerCase().contains(lowerQuery) ||
          bookmark.reciterName.toLowerCase().contains(lowerQuery) ||
          (bookmark.label?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  @override
  Future<bool> hasBookmarkAtPosition({
    required int surahId,
    required String reciterId,
    required int positionMs,
  }) async {
    final List<BookmarkEntity> bookmarks = await _localDataSource
        .getAllBookmarks();

    const toleranceMs = 5000; // 5 seconds tolerance

    return bookmarks.any(
      (b) =>
          b.surahId == surahId &&
          b.reciterId == reciterId &&
          (b.positionMs - positionMs).abs() <= toleranceMs,
    );
  }

  @override
  Future<int> getBookmarkCount() async {
    return _localDataSource.getBookmarkCount();
  }
}
