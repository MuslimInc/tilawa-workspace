import 'package:injectable/injectable.dart';

import '../repositories/home_daily_ayah_bookmark_store.dart';

@injectable
class ToggleHomeDailyAyahBookmarkUseCase {
  ToggleHomeDailyAyahBookmarkUseCase(this._store);

  final HomeDailyAyahBookmarkStore _store;

  Future<bool> isBookmarked(String bookmarkKey) =>
      _store.isBookmarked(bookmarkKey);

  /// Returns the new bookmarked state after toggle.
  Future<bool> toggle(String bookmarkKey) => _store.toggleBookmark(bookmarkKey);
}
