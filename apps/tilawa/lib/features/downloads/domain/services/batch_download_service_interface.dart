/// Domain-level abstraction for batch download management.
abstract class IBatchDownloadService {
  /// Cancel all active batches for a specific reciter.
  Future<void> cancelBatchesForReciter(String reciterName);
}
