import '../entities/download_item.dart';
import 'batch_download_repository.dart';
import 'download_query_repository.dart';
import 'single_download_repository.dart';

/// Main downloads repository interface
///
/// This interface extends all specialized repository interfaces to maintain
/// backward compatibility while following the Interface Segregation Principle (ISP).
///
/// For new code, prefer depending on the specific interface you need:
/// - [SingleDownloadRepository] for individual download operations
/// - [BatchDownloadRepository] for bulk download operations
/// - [DownloadQueryRepository] for querying download data
///
/// This unified interface exists to:
/// 1. Maintain backward compatibility with existing code
/// 2. Provide a single implementation class
/// 3. Enable gradual migration to segregated interfaces
abstract class DownloadsRepository
    implements
        SingleDownloadRepository,
        BatchDownloadRepository,
        DownloadQueryRepository {
  // No additional methods - this interface just combines the three specialized interfaces
  // All methods are inherited from the parent interfaces

  /// Additional methods that don't fit neatly into the three categories

  /// Add a new download (internal use by repository implementation)
  Future<void> addDownload(DownloadItem downloadItem);

  /// Update an existing download (internal use by repository implementation)
  Future<void> updateDownload(DownloadItem downloadItem);

  /// Delete a download
  Future<void> deleteDownload(String id);

  /// Update download progress (called by download service)
  Future<void> updateDownloadProgress(
    String id,
    DownloadStatus status,
    double progress,
    int downloadedSize,
    int fileSize,
  );
}
