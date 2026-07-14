import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/home_daily_ayah_bookmark_store.dart';

@LazySingleton(as: HomeDailyAyahBookmarkStore)
class SharedPreferencesHomeDailyAyahBookmarkStore
    implements HomeDailyAyahBookmarkStore {
  SharedPreferencesHomeDailyAyahBookmarkStore(this._prefs);

  static const String storageKey = 'home_daily_ayah_bookmarks';

  final SharedPreferencesAsync _prefs;

  @override
  Future<bool> isBookmarked(String bookmarkKey) async {
    final Set<String> bookmarks =
        (await _prefs.getStringList(storageKey))?.toSet() ?? {};
    return bookmarks.contains(bookmarkKey);
  }

  @override
  Future<bool> toggleBookmark(String bookmarkKey) async {
    final Set<String> bookmarks =
        (await _prefs.getStringList(storageKey))?.toSet() ?? {};
    final bool next = !bookmarks.contains(bookmarkKey);
    if (next) {
      bookmarks.add(bookmarkKey);
    } else {
      bookmarks.remove(bookmarkKey);
    }
    await _prefs.setStringList(storageKey, bookmarks.toList());
    return next;
  }
}
