import '../entities/surah_entity.dart';

abstract class SurahRepository {
  /// Get all surahs for a specific reciter
  Future<List<SurahEntity>> getSurahsForReciter(String reciterName);

  /// Update surah download status
  Future<void> updateSurahDownloadStatus(
    String surahId,
    String reciterName,
    bool isDownloaded,
  );

  /// Update surah download progress
  Future<void> updateSurahDownloadProgress(
    String surahId,
    String reciterName,
    bool isDownloading,
    double progress,
    String? downloadId,
  );

  /// Check if a surah is downloaded
  Future<bool> isSurahDownloaded(String surahId, String reciterName);

  /// Get surah by ID and reciter
  Future<SurahEntity?> getSurah(String surahId, String reciterName);

  /// Update surah
  Future<void> updateSurah(SurahEntity surah);
}
