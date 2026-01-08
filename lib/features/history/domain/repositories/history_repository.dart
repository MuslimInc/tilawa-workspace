import '../entities/history_entity.dart';

/// Repository interface for listening history operations
abstract class HistoryRepository {
  /// Get all history entries sorted by played date (newest first)
  Future<List<HistoryEntity>> getAllHistory();

  /// Get recent history (limited number of entries)
  Future<List<HistoryEntity>> getRecentHistory({int limit = 20});

  /// Get history for a specific date range
  Future<List<HistoryEntity>> getHistoryByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Get history for a specific reciter
  Future<List<HistoryEntity>> getHistoryByReciter(String reciterId);

  /// Get a specific history entry by ID
  Future<HistoryEntity?> getHistoryById(String id);

  /// Add or update a history entry
  /// If an entry exists for the same surah+reciter+moshaf, it updates it
  Future<HistoryEntity> addOrUpdateHistory({
    required int surahId,
    required String surahName,
    required String surahNameEn,
    required String reciterId,
    required String reciterName,
    required int moshafId,
    required String moshafName,
    required int lastPositionMs,
    required int durationMs,
    required String audioUrl,
    String? artworkUrl,
    bool completed = false,
  });

  /// Update last position for an existing entry
  Future<HistoryEntity?> updateLastPosition({
    required String id,
    required int lastPositionMs,
    bool? completed,
  });

  /// Delete a history entry
  Future<void> deleteHistory(String id);

  /// Delete all history entries
  Future<void> deleteAllHistory();

  /// Delete history older than a specific date
  Future<void> deleteHistoryOlderThan(DateTime date);

  /// Search history by surah name or reciter name
  Future<List<HistoryEntity>> searchHistory(String query);

  /// Get history count
  Future<int> getHistoryCount();

  /// Get total listening time in milliseconds
  Future<int> getTotalListeningTime();

  /// Get most played surahs
  Future<List<HistoryEntity>> getMostPlayedSurahs({int limit = 10});

  /// Check if a surah has been played before
  Future<bool> hasBeenPlayed({
    required int surahId,
    required String reciterId,
    required int moshafId,
  });
}
