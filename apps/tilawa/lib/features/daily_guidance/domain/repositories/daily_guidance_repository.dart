import '../entities/daily_guidance_enums.dart';
import '../entities/daily_guidance_item.dart';

/// Domain contract for Daily Guidance content storage.
abstract class DailyGuidanceRepository {
  /// Returns all published and eligible items for the given [contentMode]
  /// and [locale].
  Future<List<DailyGuidanceItem>> getEligibleItems({
    required DailyGuidanceContentMode contentMode,
    required String locale,
  });

  /// Returns a single item by [id], or null if not found.
  Future<DailyGuidanceItem?> getItemById(String id);

  /// Refreshes the local content cache from the remote source (if available).
  /// Returns the number of items updated.
  Future<int> refreshContent();
}
