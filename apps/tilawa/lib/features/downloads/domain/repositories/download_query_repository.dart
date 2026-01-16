import 'package:audio_service/audio_service.dart';

import '../entities/download_item.dart';

/// Repository interface for querying download data
///
/// This interface follows the Interface Segregation Principle (ISP)
/// by separating query operations from command operations (downloads).
/// Clients that only need to read download data don't have to depend
/// on download operation methods.
abstract class DownloadQueryRepository {
  /// Initialize the repository (start listening to progress updates)
  Future<void> initialize();

  /// Get all downloads (raw list)
  Future<List<DownloadItem>> getAllDownloads();

  /// Get a specific download item by ID
  Future<DownloadItem?> getDownloadItem(String id);

  /// Validate if downloaded file exists on disk
  Future<bool> validateDownloadedFile(DownloadItem download);

  /// Create MediaItem from a download
  MediaItem createMediaItemFromDownload(DownloadItem download);

  /// Create MediaItems from multiple downloads
  List<MediaItem> createMediaItemsFromDownloads(List<DownloadItem> downloads);

  /// Get total size of all downloads in bytes
  Future<int> getTotalDownloadsSize();

  /// Clear all downloads (delete all data and files)
  Future<void> clearAllDownloads();

  /// Resume any pending or stuck downloads on app start
  Future<void> resumePendingDownloads();
}
