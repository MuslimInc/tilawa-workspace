import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/bookmark_entity.dart';

abstract class BookmarksLocalDataSource {
  Future<List<BookmarkEntity>> getAllBookmarks();
  Future<BookmarkEntity?> getBookmarkById(String id);
  Future<void> saveBookmark(BookmarkEntity bookmark);
  Future<void> deleteBookmark(String id);
  Future<void> saveAllBookmarks(List<BookmarkEntity> bookmarks);
  Future<void> clearAllBookmarks();
  Future<String> generateBookmarkId();
  Future<int> getBookmarkCount();
}

@LazySingleton(as: BookmarksLocalDataSource)
class BookmarksLocalDataSourceImpl implements BookmarksLocalDataSource {
  BookmarksLocalDataSourceImpl(this._prefs);

  static const String _bookmarksKey = 'bookmarks';
  static const String _bookmarkCounterKey = 'bookmark_counter';

  final SharedPreferencesAsync _prefs;

  @override
  Future<List<BookmarkEntity>> getAllBookmarks() async {
    final List<String> bookmarksJson =
        await _prefs.getStringList(_bookmarksKey) ?? [];

    final List<BookmarkEntity> bookmarks = bookmarksJson.map((json) {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return BookmarkEntity.fromJson(map);
    }).toList();

    // Sort by creation date (newest first)
    bookmarks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return bookmarks;
  }

  @override
  Future<BookmarkEntity?> getBookmarkById(String id) async {
    final List<BookmarkEntity> bookmarks = await getAllBookmarks();
    try {
      return bookmarks.firstWhere((bookmark) => bookmark.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> saveBookmark(BookmarkEntity bookmark) async {
    final List<BookmarkEntity> bookmarks = await getAllBookmarks();

    final int existingIndex = bookmarks.indexWhere((b) => b.id == bookmark.id);

    if (existingIndex != -1) {
      bookmarks[existingIndex] = bookmark;
    } else {
      bookmarks.add(bookmark);
    }

    await saveAllBookmarks(bookmarks);
  }

  @override
  Future<void> deleteBookmark(String id) async {
    final List<BookmarkEntity> bookmarks = await getAllBookmarks();
    bookmarks.removeWhere((bookmark) => bookmark.id == id);
    await saveAllBookmarks(bookmarks);
  }

  @override
  Future<void> saveAllBookmarks(List<BookmarkEntity> bookmarks) async {
    final List<String> bookmarksJson = bookmarks
        .map((bookmark) => jsonEncode(bookmark.toJson()))
        .toList();
    await _prefs.setStringList(_bookmarksKey, bookmarksJson);
  }

  @override
  Future<void> clearAllBookmarks() async {
    await _prefs.remove(_bookmarksKey);
    await _prefs.remove(_bookmarkCounterKey);
  }

  @override
  Future<String> generateBookmarkId() async {
    final int counter = await _prefs.getInt(_bookmarkCounterKey) ?? 0;
    final int newCounter = counter + 1;
    await _prefs.setInt(_bookmarkCounterKey, newCounter);
    return 'bookmark_$newCounter';
  }

  @override
  Future<int> getBookmarkCount() async {
    final List<BookmarkEntity> bookmarks = await getAllBookmarks();
    return bookmarks.length;
  }
}
