import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/last_visited_page_repository.dart';

/// SharedPreferences implementation of [LastVisitedPageRepository].
///
/// This implementation persists the last visited page to device storage
/// using the SharedPreferences plugin, allowing the app to remember
/// the user's position across app restarts.
class SharedPreferencesLastVisitedPageRepository
    implements LastVisitedPageRepository {
  final SharedPreferencesAsync _prefs;

  /// Creates a repository with a SharedPreferencesAsync instance.
  SharedPreferencesLastVisitedPageRepository(this._prefs);

  @override
  Future<void> saveLastVisitedPage(int pageNumber) async {
    await _prefs.setInt(LastVisitedPageRepository.storageKey, pageNumber);
  }

  @override
  Future<int?> getLastVisitedPage() async {
    return _prefs.getInt(LastVisitedPageRepository.storageKey);
  }

  @override
  Future<void> clearLastVisitedPage() async {
    await _prefs.remove(LastVisitedPageRepository.storageKey);
  }
}
