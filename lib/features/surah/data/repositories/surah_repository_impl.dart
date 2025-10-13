import 'package:injectable/injectable.dart';
import 'package:muzakri/features/downloads/domain/repositories/downloads_repository.dart';
import 'package:muzakri/features/surah/domain/entities/surah.dart';
import 'package:muzakri/features/surah/domain/repositories/surah_repository.dart';

@LazySingleton(as: SurahRepository)
class SurahRepositoryImpl implements SurahRepository {
  SurahRepositoryImpl(this._downloadsRepository);

  final DownloadsRepository _downloadsRepository;

  // In-memory cache for surahs
  final Map<String, Surah> _surahCache = {};

  String _getCacheKey(String surahId, String reciterName) {
    return '${surahId}_$reciterName';
  }

  @override
  Future<List<Surah>> getSurahsForReciter(String reciterName) async {
    // This would typically fetch from a data source
    // For now, return empty list - this should be implemented based on your data source
    return [];
  }

  @override
  Future<void> updateSurahDownloadStatus(
    String surahId,
    String reciterName,
    bool isDownloaded,
  ) async {
    final cacheKey = _getCacheKey(surahId, reciterName);
    final existingSurah = _surahCache[cacheKey];

    if (existingSurah != null) {
      _surahCache[cacheKey] = existingSurah.copyWith(
        isDownloaded: isDownloaded,
        isDownloading: false,
        downloadProgress: isDownloaded ? 1.0 : 0.0,
      );
    }
  }

  @override
  Future<void> updateSurahDownloadProgress(
    String surahId,
    String reciterName,
    bool isDownloading,
    double progress,
    String? downloadId,
  ) async {
    final cacheKey = _getCacheKey(surahId, reciterName);
    final existingSurah = _surahCache[cacheKey];

    if (existingSurah != null) {
      _surahCache[cacheKey] = existingSurah.copyWith(
        isDownloading: isDownloading,
        downloadProgress: progress,
        downloadId: downloadId,
      );
    }
  }

  @override
  Future<bool> isSurahDownloaded(String surahId, String reciterName) async {
    // First check cache
    final cacheKey = _getCacheKey(surahId, reciterName);
    final cachedSurah = _surahCache[cacheKey];

    if (cachedSurah != null) {
      return cachedSurah.isDownloaded;
    }

    // Fallback to downloads repository
    return await _downloadsRepository.isSurahDownloaded(surahId, reciterName);
  }

  @override
  Future<Surah?> getSurah(String surahId, String reciterName) async {
    final cacheKey = _getCacheKey(surahId, reciterName);
    return _surahCache[cacheKey];
  }

  @override
  Future<void> updateSurah(Surah surah) async {
    final cacheKey = _getCacheKey(surah.id, surah.reciterName);
    _surahCache[cacheKey] = surah;
  }

  /// Add surah to cache (useful when creating surahs from external data)
  void addSurahToCache(Surah surah) {
    final cacheKey = _getCacheKey(surah.id, surah.reciterName);
    _surahCache[cacheKey] = surah;
  }

  /// Get all cached surahs
  List<Surah> getAllCachedSurahs() {
    return _surahCache.values.toList();
  }

  /// Clear cache
  void clearCache() {
    _surahCache.clear();
  }
}
