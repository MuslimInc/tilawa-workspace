part of 'bookmarks_bloc.dart';

@freezed
sealed class BookmarksState with _$BookmarksState {
  const factory BookmarksState.initial() = BookmarksInitial;

  const factory BookmarksState.loading() = BookmarksLoading;

  const factory BookmarksState.loaded({
    required List<BookmarkEntity> bookmarks,
    required List<BookmarkEntity> filteredBookmarks,
    @Default('') String searchQuery,
  }) = BookmarksLoaded;

  const factory BookmarksState.bookmarkCreated({
    required BookmarkEntity bookmark,
    required List<BookmarkEntity> bookmarks,
  }) = BookmarkCreated;

  const factory BookmarksState.bookmarkUpdated({
    required BookmarkEntity bookmark,
    required List<BookmarkEntity> bookmarks,
  }) = BookmarkUpdated;

  const factory BookmarksState.bookmarkDeleted({
    required String deletedId,
    required List<BookmarkEntity> bookmarks,
  }) = BookmarkDeleted;

  const factory BookmarksState.error(String message) = BookmarksError;
}
