/// Repository interface for persisting the last visited page.
///
/// This abstract class defines the contract for saving and retrieving
/// the last visited (or jumped-to) page, following the Repository Pattern
/// from Clean Architecture.
abstract class LastVisitedPageRepository {
  /// Key used for storing the last visited page in SharedPreferences
  static const String storageKey = 'last_visited_page';

  /// Saves the last visited page number
  ///
  /// [pageNumber] must be between 1 and 604 (valid Quran page range)
  Future<void> saveLastVisitedPage(int pageNumber);

  /// Gets the last visited page number
  ///
  /// Returns null if no page has been saved yet
  Future<int?> getLastVisitedPage();

  /// Clears the saved last visited page
  Future<void> clearLastVisitedPage();
}
