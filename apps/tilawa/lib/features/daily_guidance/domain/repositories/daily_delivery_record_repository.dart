import '../entities/daily_delivery_record.dart';

/// Domain contract for delivery record persistence (anti-repetition + stability).
abstract class DailyDeliveryRecordRepository {
  /// Returns the delivery record for the given [localDate], or null.
  Future<DailyDeliveryRecord?> getRecordForDate(String localDate);

  /// Saves or updates a delivery record.
  Future<void> saveRecord(DailyDeliveryRecord record);

  /// Returns all item IDs delivered within the last [days] calendar days.
  Future<Set<String>> getRecentlyDeliveredItemIds({required int days});

  /// Returns all delivery records, ordered by date descending.
  Future<List<DailyDeliveryRecord>> getRecentRecords({int limit = 30});

  /// Prunes records older than [keepDays] calendar days.
  Future<void> pruneOldRecords({required int keepDays});
}
