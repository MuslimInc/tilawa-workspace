/// Preference keys and product limits for Home athkar shortcuts.
abstract final class PinnedAthkarConstants {
  /// SharedPreferences key for the ordered list of pinned athkar category IDs.
  static const String preferenceKey = 'athkar_pinned_category_ids';

  /// Home is capped at four shortcuts to keep the dashboard scannable on
  /// narrow phones while still allowing Morning, Evening, and two more habits.
  static const int maxPinnedCategories = 4;

  /// First-run defaults shown until the user customizes the picker.
  static const List<int> defaultCategoryIds = [1, 2];
}
