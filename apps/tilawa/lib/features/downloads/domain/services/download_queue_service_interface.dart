/// Domain-level abstraction for download queue operations.
abstract class IDownloadQueueService {
  /// Remove all queued downloads for a specific reciter.
  void dequeueForReciter(String reciterName);

  /// Remove a single download from the queue.
  void removeFromQueue(String id);

  /// Get queue position for a download (1-based, -1 if not in queue).
  int getQueuePosition(String id);

  /// Maximum number of concurrent downloads.
  set maxConcurrentDownloads(int count);
  int get maxConcurrentDownloads;
}
