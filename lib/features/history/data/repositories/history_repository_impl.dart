import 'package:injectable/injectable.dart';

import '../../domain/entities/history_entity.dart';
import '../../domain/repositories/history_repository.dart';
import '../datasources/history_local_datasource.dart';

@LazySingleton(as: HistoryRepository)
class HistoryRepositoryImpl implements HistoryRepository {
  HistoryRepositoryImpl(this._localDataSource);

  final HistoryLocalDataSource _localDataSource;

  @override
  Future<List<HistoryEntity>> getAllHistory() async {
    return _localDataSource.getAllHistory();
  }

  @override
  Future<List<HistoryEntity>> getRecentHistory({int limit = 20}) async {
    final List<HistoryEntity> history = await _localDataSource.getAllHistory();
    return history.take(limit).toList();
  }

  @override
  Future<List<HistoryEntity>> getHistoryByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final List<HistoryEntity> history = await _localDataSource.getAllHistory();
    return history.where((h) {
      return h.playedAt.isAfter(startDate) && h.playedAt.isBefore(endDate);
    }).toList();
  }

  @override
  Future<List<HistoryEntity>> getHistoryByReciter(String reciterId) async {
    final List<HistoryEntity> history = await _localDataSource.getAllHistory();
    return history.where((h) => h.reciterId == reciterId).toList();
  }

  @override
  Future<HistoryEntity?> getHistoryById(String id) async {
    return _localDataSource.getHistoryById(id);
  }

  @override
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
  }) async {
    // Check if entry already exists
    final HistoryEntity? existing = await _localDataSource.getHistoryByKey(
      surahId: surahId,
      reciterId: reciterId,
      moshafId: moshafId,
    );

    final now = DateTime.now();

    if (existing != null) {
      // Update existing entry
      final HistoryEntity updated = existing.copyWith(
        lastPositionMs: lastPositionMs,
        playedAt: now,
        completed: completed,
        playCount: existing.playCount + 1,
      );
      await _localDataSource.saveHistory(updated);
      return updated;
    } else {
      // Create new entry
      final String id = await _localDataSource.generateHistoryId();
      final newHistory = HistoryEntity(
        id: id,
        surahId: surahId,
        surahName: surahName,
        surahNameEn: surahNameEn,
        reciterId: reciterId,
        reciterName: reciterName,
        moshafId: moshafId,
        moshafName: moshafName,
        lastPositionMs: lastPositionMs,
        durationMs: durationMs,
        audioUrl: audioUrl,
        artworkUrl: artworkUrl,
        playedAt: now,
        completed: completed,
      );
      await _localDataSource.saveHistory(newHistory);
      return newHistory;
    }
  }

  @override
  Future<HistoryEntity?> updateLastPosition({
    required String id,
    required int lastPositionMs,
    bool? completed,
  }) async {
    final HistoryEntity? existing = await _localDataSource.getHistoryById(id);
    if (existing == null) return null;

    final HistoryEntity updated = existing.copyWith(
      lastPositionMs: lastPositionMs,
      playedAt: DateTime.now(),
      completed: completed ?? existing.completed,
    );
    await _localDataSource.saveHistory(updated);
    return updated;
  }

  @override
  Future<void> deleteHistory(String id) async {
    await _localDataSource.deleteHistory(id);
  }

  @override
  Future<void> deleteAllHistory() async {
    await _localDataSource.clearAllHistory();
  }

  @override
  Future<void> deleteHistoryOlderThan(DateTime date) async {
    final List<HistoryEntity> history = await _localDataSource.getAllHistory();
    final List<HistoryEntity> filtered = history
        .where((h) => h.playedAt.isAfter(date))
        .toList();
    await _localDataSource.saveAllHistory(filtered);
  }

  @override
  Future<List<HistoryEntity>> searchHistory(String query) async {
    final List<HistoryEntity> history = await _localDataSource.getAllHistory();
    final String lowerQuery = query.toLowerCase();

    return history.where((h) {
      return h.surahName.toLowerCase().contains(lowerQuery) ||
          h.surahNameEn.toLowerCase().contains(lowerQuery) ||
          h.reciterName.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  @override
  Future<int> getHistoryCount() async {
    return _localDataSource.getHistoryCount();
  }

  @override
  Future<int> getTotalListeningTime() async {
    final List<HistoryEntity> history = await _localDataSource.getAllHistory();
    var total = 0;
    for (final h in history) {
      total += h.lastPositionMs;
    }
    return total;
  }

  @override
  Future<List<HistoryEntity>> getMostPlayedSurahs({int limit = 10}) async {
    final List<HistoryEntity> history = await _localDataSource.getAllHistory();

    // Group by surah+reciter+moshaf and sort by play count
    history.sort((a, b) => b.playCount.compareTo(a.playCount));

    return history.take(limit).toList();
  }

  @override
  Future<bool> hasBeenPlayed({
    required int surahId,
    required String reciterId,
    required int moshafId,
  }) async {
    final HistoryEntity? existing = await _localDataSource.getHistoryByKey(
      surahId: surahId,
      reciterId: reciterId,
      moshafId: moshafId,
    );
    return existing != null;
  }
}
