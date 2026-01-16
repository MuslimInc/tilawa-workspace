import '../entities/download_item.dart';

/// Repository interface for single download operations
///
/// This interface follows the Interface Segregation Principle (ISP)
/// by providing only the methods needed for individual download operations.
/// Clients that only need to download single items don't have to depend
/// on batch download methods.
abstract class SingleDownloadRepository {
  /// Start downloading a single surah
  Future<void> startDownload(
    String url, {
    required String title,
    bool? showNotification,
    required String surahTitle,
    required String reciterName,
    required int reciterId,
  });

  /// Cancel a single download
  Future<void> cancelDownload(String id);

  /// Pause a download
  Future<void> pauseDownload(String id);

  /// Resume a download
  Future<void> resumeDownload(String id);

  /// Retry a failed download
  Future<void> retryDownload(String downloadId);

  /// Check if a surah is already downloaded
  Future<bool> isSurahDownloaded(String url, String reciterName);

  /// Check if a surah is currently downloading
  Future<bool> isSurahDownloading(String url, String reciterName);

  /// Get downloaded file path
  Future<String?> getDownloadedFilePath(String url, String reciterName);

  /// Stream of download updates for UI feedback
  /// Emits when downloads are added, updated, or completed
  Stream<DownloadItem> get downloadUpdates;

  /// Get download progress stream for a specific download
  Stream<DownloadItem> getDownloadProgress(String id);
}
