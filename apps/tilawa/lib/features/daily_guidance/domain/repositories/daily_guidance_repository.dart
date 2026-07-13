import '../entities/daily_guidance_enums.dart';
import '../entities/daily_guidance_item.dart';

/// Domain contract for Daily Guidance content storage.
abstract class DailyGuidanceRepository {
  /// Returns all published and eligible items for the given [contentMode]
  /// and [locale].
  Future<List<DailyGuidanceItem>> getEligibleItems({
    required DailyGuidanceContentMode contentMode,
    required String locale,
    required DailyGuidanceCapability capability,
  });

  /// Returns a trusted item when it is eligible for the requested context.
  Future<DailyGuidanceItem?> getItemById({
    required String id,
    required String locale,
    required DailyGuidanceCapability capability,
  });

  /// Refreshes the local content cache from the remote source (if available).
  /// Returns the number of items updated.
  Future<int> refreshContent();
}
