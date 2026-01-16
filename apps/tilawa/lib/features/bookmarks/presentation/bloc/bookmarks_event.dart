part of 'bookmarks_bloc.dart';

@freezed
sealed class BookmarksEvent with _$BookmarksEvent {
  const factory BookmarksEvent.load() = LoadBookmarksEvent;

  const factory BookmarksEvent.create({
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
  }) = CreateBookmarkEvent;

  const factory BookmarksEvent.delete({required String id}) =
      DeleteBookmarkEvent;

  const factory BookmarksEvent.updateLabel({
    required String id,
    String? label,
  }) = UpdateBookmarkLabelEvent;

  const factory BookmarksEvent.search({required String query}) =
      SearchBookmarksEvent;

  const factory BookmarksEvent.clearSearch() = ClearBookmarksSearchEvent;
}
