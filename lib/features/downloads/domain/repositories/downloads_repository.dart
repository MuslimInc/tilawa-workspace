import 'package:audio_service/audio_service.dart';

import '../entities/download_item.dart';

abstract class DownloadsRepository {
  /// Get all downloads grouped by reciter
  Future<Map<String, List<DownloadItem>>> getDownloadsByReciter();

  /// Get downloads for a specific reciter
  Future<List<DownloadItem>> getDownloadsForReciter(String reciterName);

  /// Get a specific download item
  Future<DownloadItem?> getDownloadItem(String id);

  /// Add a new download
  Future<void> addDownload(DownloadItem downloadItem);

  /// Update an existing download
  Future<void> updateDownload(DownloadItem downloadItem);

  /// Delete a download
  Future<void> deleteDownload(String id);

  /// Delete all downloads for a reciter
  Future<void> deleteDownloadsForReciter(String reciterName);

  /// Clear all downloads
  Future<void> clearAllDownloads();

  /// Get download progress stream
  Stream<DownloadItem> getDownloadProgress(String id);

  /// Start downloading a surah
  Future<void> startDownload(
    String surahId,
    String surahTitle,
    String reciterName,
  );

  /// Pause a download
  Future<void> pauseDownload(String id);

  /// Resume a download
  Future<void> resumeDownload(String id);

  /// Cancel a download
  Future<void> cancelDownload(String id);

  /// Check if a surah is already downloaded
  Future<bool> isSurahDownloaded(String surahId, String reciterName);

  /// Check if a surah is currently downloading
  Future<bool> isSurahDownloading(String surahId, String reciterName);

  /// Get downloaded file path
  Future<String?> getDownloadedFilePath(String surahId, String reciterName);

  /// Update download progress
  Future<void> updateDownloadProgress(
    String id,
    DownloadStatus status,
    double progress,
    int downloadedSize,
    int fileSize,
  );

  /// Create MediaItem from download
  MediaItem createMediaItemFromDownload(DownloadItem download);

  /// Validate if downloaded file exists
  Future<bool> validateDownloadedFile(DownloadItem download);

  /// Get valid completed downloads for a reciter
  Future<List<DownloadItem>> getValidCompletedDownloads(String reciterName);

  /// Retry a failed download
  Future<void> retryDownload(String downloadId);

  /// Create MediaItems from multiple downloads
  List<MediaItem> createMediaItemsFromDownloads(List<DownloadItem> downloads);

  /// Resume any pending or stuck downloads on app start
  Future<void> resumePendingDownloads();
}
