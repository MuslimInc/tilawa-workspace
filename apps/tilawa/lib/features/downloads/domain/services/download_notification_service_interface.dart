import '../entities/download_item.dart';

/// Interface for the download notification service
///
/// Defines the contract for showing and managing download progress notifications.
abstract interface class IDownloadNotificationService {
  /// Initialize the notification service
  Future<void> initialize();

  /// Show a download progress notification
  ///
  /// [downloadId] - Unique identifier for the download
  /// [title] - Title of the download (e.g., surah name)
  /// [reciterName] - Name of the reciter
  /// [progress] - Download progress (0-100)
  /// [status] - Current download status
  /// [pendingMessage] - Localized message for pending status
  /// [progressMessage] - Localized message for progress
  /// [completeMessage] - Localized message for completed status
  /// [failedMessage] - Localized message for failed status
  Future<void> showDownloadProgress({
    required String downloadId,
    required String title,
    required String reciterName,
    int? reciterId,
    required int progress,
    required DownloadStatus status,
    String? pendingMessage,
    String? progressMessage,
    String? completeMessage,
    String? failedMessage,
  });

  /// Show a batch download progress notification
  ///
  /// [batchId] - Unique identifier for the batch
  /// [title] - Title for the batch download
  /// [progress] - Overall progress (0-100)
  /// [completedCount] - Number of completed downloads
  /// [totalCount] - Total number of downloads in batch
  /// [status] - Current download status
  Future<void> showBatchDownloadProgress({
    required String batchId,
    required String title,
    required int progress,
    required int completedCount,
    required int totalCount,
    required DownloadStatus status,
    String? progressMessage,
    String? completeMessage,
    String? failedMessage,
  });

  /// Cancel a download notification
  Future<void> cancelNotification(String downloadId);

  /// Cancel all download notifications
  Future<void> cancelAllNotifications();

  /// Handle notification tap from payload string
  Future<void> handleNotificationTap(String? payload);
}
