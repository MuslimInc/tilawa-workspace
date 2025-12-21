/// Repository interface for batch/bulk download operations
///
/// This interface follows the Interface Segregation Principle (ISP)
/// by providing only the methods needed for batch download operations.
/// Separates concerns from single download operations.
abstract class BatchDownloadRepository {
  /// Start multiple downloads efficiently as a batch
  ///
  /// This method optimizes for bulk operations by:
  /// - Creating database entries in batch
  /// - Managing a single notification for the entire batch
  /// - Coordinating concurrent downloads through queue manager
  Future<void> startDownloadBatch(
    List<({String url, String surahTitle, String reciterName, int reciterId})>
    items,
  );

  /// Cancel all active downloads for a specific reciter
  ///
  /// This is typically used when user cancels "Download All" operation
  Future<void> cancelDownloadsForReciter(String reciterName);

  /// Delete all downloads for a specific reciter
  Future<void> deleteDownloadsForReciter(String reciterName);
}
