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
}
