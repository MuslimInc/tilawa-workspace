import '../entities/download_item.dart';
import '../entities/downloaded_file_integrity.dart';

/// Repository interface for querying download data
///
/// This interface follows the Interface Segregation Principle (ISP)
/// by separating query operations from command operations (downloads).
/// Clients that only need to read download data don't have to depend
/// on download operation methods.
abstract class DownloadQueryRepository {
  /// Get all downloads (raw list)
  Future<List<DownloadItem>> getAllDownloads();

  /// Get a specific download item by ID
  Future<DownloadItem?> getDownloadItem(String id);

  /// Validate if downloaded file exists on disk (and matches expected size).
  Future<bool> validateDownloadedFile(DownloadItem download);

  /// Inspect existence and size integrity of a completed download.
  Future<DownloadedFileIntegrity> inspectDownloadedFile(DownloadItem download);

  /// Get total size of all downloads in bytes
  Future<int> getTotalDownloadsSize();
}
